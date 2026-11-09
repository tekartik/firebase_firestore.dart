// ignore_for_file: inference_failure_on_collection_literal

import 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/copy_utils.dart';

import 'firestore_test_runner.dart';

/// Run copy utils tests.
void runCopyUtilsTest({
  required Firestore firestore,
  required FirestoreTestContext? testContext,
}) {
  var testsRefPath = FirestoreTestContext.getRootCollectionPath(testContext);
  group('copy utils collections', () {
    // firestore = firestore.debugQuickLoggerWrapper();

    test(
      'copy/list documents with parent',
      () async {
        var parent = url.join(
          testsRefPath,
          'tekartik_test_recursive_documents',
        );
        var parentDest = url.join(
          testsRefPath,
          'tekartik_test_recursive_documents_dst',
        );
        var parentDoc = firestore.doc(parent);
        await parentDoc.recursiveDelete(firestore);
        await firestore.doc(parentDest).recursiveDelete(firestore);
        var doc1 = firestore.doc('$parent/sub/doc');
        await doc1.set({});
        var doc2 = doc1.collection('c1').doc('d2');
        await doc2.set({});
        var collection = doc1.parent;
        expect((await collection.recursiveListDocuments()).map((e) => e.path), [
          doc1.path,
          doc2.path,
        ]);

        var dstDocument = firestore.doc(parentDest);
        expect(await parentDoc.recursiveCopyTo(firestore, dstDocument), 2);
        expect((await parentDoc.recursiveListDocuments()).map((e) => e.path), [
          doc1.path,
          doc2.path,
        ]);
        expect(await parentDoc.recursiveDelete(firestore), 2);
        expect(
          (await parentDoc.recursiveListDocuments()).map((e) => e.path),
          isEmpty,
        );
        /*
      await doc1.delete();
      await doc2.delete();

       */
        expect(
          (await collection.recursiveListDocuments()).map((e) => e.path),
          isEmpty,
        );
      },
      skip:
          skipFirestoreListCollectionsTests ||
          !firestore.service.supportsListCollections,
    );

    test(
      'copy/list documents no parent (weird)',
      () async {
        var parent = url.join(
          testsRefPath,
          'tekartik_test_recursive_documents',
        );

        var doc1 = firestore.doc('$parent/sub/doc');
        await doc1.set({});
        // doc1/c1/d2 is a "missing" document (no data, a sub-collection).
        var doc2 = doc1.collection('c1').doc('d2').collection('c3').doc('d3');
        await doc2.set({});
        var collection = doc1.parent;
        // Found when the missing documents can be listed and doc1/c1 (holding
        // only a missing document) is listed, as Firestore does.
        var found =
            firestore.service.supportsListMissingDocuments &&
            (await doc1.listCollections()).isNotEmpty;
        expect((await collection.recursiveListDocuments()).map((e) => e.path), [
          doc1.path,
          if (found) doc2.path,
        ]);

        await doc1.delete();
        await doc2.delete();
        expect(
          (await collection.recursiveListDocuments()).map((e) => e.path),
          isEmpty,
        );
      },
      skip:
          skipFirestoreListCollectionsTests ||
          !firestore.service.supportsListCollections,
    );

    test(
      'copy/list/delete documents under a missing document',
      () async {
        var parent = url.join(testsRefPath, 'tekartik_test_recursive_missing');
        var collection = firestore.collection('$parent/coll');
        var dstCollection = firestore.collection('$parent/dst');
        await collection.recursiveDelete(firestore);
        await dstCollection.recursiveDelete(firestore);
        var doc1 = collection.doc('doc1');
        await doc1.set({'value': 1});
        // coll/missing is a "missing" document (no data, a sub-collection),
        // a query does not return it.
        var doc2 = collection.doc('missing').collection('sub').doc('doc2');
        await doc2.set({'value': 2});
        expect((await collection.recursiveListDocuments()).map((e) => e.path), [
          doc1.path,
          doc2.path,
        ]);
        expect(await collection.recursiveCopyTo(firestore, dstCollection), 2);
        expect(
          (await dstCollection.recursiveListDocuments()).map((e) => e.path),
          [
            dstCollection.doc('doc1').path,
            dstCollection.doc('missing/sub/doc2').path,
          ],
        );
        expect(await dstCollection.recursiveDelete(firestore), 2);
        expect(await collection.recursiveDelete(firestore), 2);
        expect((await doc2.get()).exists, isFalse);
        expect(
          (await collection.recursiveListDocuments()).map((e) => e.path),
          isEmpty,
        );
      },
      skip:
          skipFirestoreListCollectionsTests ||
          !firestore.service.supportsListCollections ||
          !firestore.service.supportsListMissingDocuments,
    );
  });
}
