import 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';

import 'firestore_test_runner.dart';

/// Run list documents tests.
void runListDocumentsTest({
  required Firestore firestore,
  required FirestoreTestContext? testContext,
}) {
  var testsRefPath = FirestoreTestContext.getRootCollectionPath(testContext);
  group('list documents', () {
    test('list documents', () async {
      var collection = firestore
          .doc(url.join(testsRefPath, 'tekartik_test_list_documents'))
          .collection('coll');
      var doc1 = collection.doc('doc1');
      var doc2 = collection.doc('doc2');
      await doc1.set({'test': 1});
      await doc2.set({'test': 2});
      try {
        var result = await collection.listDocuments();
        expect(result.nextPageToken, isNull);
        var refs = result.refs;
        expect(refs.map((ref) => ref.path).toList()..sort(), [
          doc1.path,
          doc2.path,
        ]);
        expect(refs.ids.toSet(), (await collection.get()).ids.toSet());
      } finally {
        await doc1.delete();
        await doc2.delete();
      }
      expect((await collection.listDocuments()).refs, isEmpty);
    });

    test('list documents paging', () async {
      var collection = firestore
          .doc(url.join(testsRefPath, 'tekartik_test_list_documents_paging'))
          .collection('coll');
      var docs = [for (var i = 1; i <= 3; i++) collection.doc('doc$i')];
      for (var doc in docs) {
        await doc.set({'test': 1});
      }
      try {
        var ids = <String>[];
        String? pageToken;
        var pageCount = 0;
        do {
          var result = await collection.listDocuments(
            options: FirestoreListDocumentsOptions(
              pageSize: 2,
              pageToken: pageToken,
            ),
          );
          expect(result.refs.length, lessThanOrEqualTo(2));
          ids.addAll(result.refs.ids);
          pageToken = result.nextPageToken;
          expect(++pageCount, lessThan(10));
        } while (pageToken != null);
        expect(pageCount, greaterThanOrEqualTo(2));
        expect(ids..sort(), ['doc1', 'doc2', 'doc3']);
      } finally {
        for (var doc in docs) {
          await doc.delete();
        }
      }
    });

    test('list missing documents', () async {
      var collection = firestore
          .doc(url.join(testsRefPath, 'tekartik_test_list_missing_documents'))
          .collection('coll');
      var existingDoc = collection.doc('existing');
      // Has no data of its own, only a sub-collection
      var missingDoc = collection.doc('missing');
      var subDoc = missingDoc.collection('sub').doc('doc');
      await missingDoc.delete();
      await existingDoc.set({'test': 1});
      await subDoc.set({'test': 2});
      try {
        expect((await missingDoc.get()).exists, isFalse);
        expect((await collection.get()).ids, ['existing']);

        var ids = (await collection.listDocuments()).refs.ids..sort();
        if (!firestore.service.supportsListMissingDocuments) {
          expect(ids, ['existing']);
        } else if (!skipFirestoreListMissingDocumentsTests) {
          expect(ids, ['existing', 'missing']);
        } else {
          expect(ids, contains('existing'));
        }

        // Never the missing ones when not shown.
        ids = (await collection.listDocuments(
          options: const FirestoreListDocumentsOptions(showMissing: false),
        )).refs.ids..sort();
        expect(ids, ['existing']);
      } finally {
        await existingDoc.delete();
        await subDoc.delete();
      }
      expect((await collection.listDocuments()).refs, isEmpty);
    });
  });
}
