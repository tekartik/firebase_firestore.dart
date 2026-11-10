// ignore_for_file: inference_failure_on_collection_literal

// ignore: implementation_imports
import 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/copy_utils.dart';

import 'firestore_test_runner.dart';

/// Run list collections tests.
void runListCollectionsTest({
  required Firestore firestore,
  required FirestoreTestContext? testContext,
}) {
  var testsRefPath = FirestoreTestContext.getRootCollectionPath(testContext);
  group('list collections', () {
    // firestore = firestore.debugQuickLoggerWrapper();
    test(
      'list root collections',
      () async {
        var collectionId = 'tekartik_test_root_collection';
        var doc = firestore.doc('$collectionId/doc');
        var collections = await firestore.listCollections();
        await doc.set({});
        expect(
          (await firestore.collection(collectionId).recursiveListDocuments())
              .map((e) => e.path),
          [doc.path],
        );
        collections = await firestore.listCollections();
        var collection = collections.firstWhere(
          (element) => element.id == collectionId,
        );
        expect(collection.path, collectionId);
        await doc.delete();
        collections = await firestore.listCollections();
        expect(collections.map((e) => e.id), isNot(contains(collectionId)));

        expect(
          (await firestore.collection(collectionId).recursiveListDocuments())
              .map((e) => e.path),
          isEmpty,
        );
      },
      skip:
          skipFirestoreListCollectionsTests ||
          !firestore.service.supportsListCollections,
    );

    test(
      'list doc collections',
      () async {
        var parent = url.join(testsRefPath, 'tekartik_test_collection');
        var collectionId = 'sub';
        var collection = firestore.collection(url.join(parent, collectionId));
        var doc = collection.doc('doc');
        var collections = await firestore.doc(parent).listCollections();
        await doc.set({});
        expect((await collection.recursiveListDocuments()).map((e) => e.path), [
          doc.path,
        ]);
        collections = await firestore.doc(parent).listCollections();
        expect(collections.map((e) => e.id), contains(collectionId));
        await doc.delete();
        collections = await firestore.doc(parent).listCollections();
        expect(collections.map((e) => e.id), isNot(contains(collectionId)));
        expect(
          (await collection.recursiveListDocuments()).map((e) => e.path),
          isEmpty,
        );
      },
      skip:
          skipFirestoreListCollectionsTests ||
          !firestore.service.supportsListCollections,
    );

    var skipMissing =
        skipFirestoreListCollectionsTests ||
        skipFirestoreListMissingDocumentsTests ||
        !firestore.service.supportsListCollections ||
        !firestore.service.supportsListMissingDocuments;
    test(
      'list doc collections holding only missing documents',
      () async {
        // parent/sub/missing is a "missing" document (no data, a
        // sub-collection): sub is still a collection of parent, as
        // listDocuments lists sub/missing.
        var parent = url.join(testsRefPath, 'tekartik_test_collection_missing');
        var doc = firestore.doc(
          url.join(parent, 'sub', 'missing', 'sub2', 'doc'),
        );
        await doc.set({});
        try {
          expect(
            (await firestore.doc(parent).listCollections()).map((e) => e.id),
            contains('sub'),
          );
          expect(
            (await firestore
                    .doc(url.join(parent, 'sub', 'missing'))
                    .listCollections())
                .map((e) => e.id),
            contains('sub2'),
          );
          expect(
            (await firestore.doc(parent).recursiveListDocuments()).map(
              (e) => e.path,
            ),
            contains(doc.path),
          );
        } finally {
          await doc.delete();
        }
        expect(
          (await firestore.doc(parent).listCollections()).map((e) => e.id),
          isNot(contains('sub')),
        );
      },
      skip: skipMissing,
      timeout: const Timeout(Duration(minutes: 1)),
    );

    test(
      'list root collections holding only missing documents',
      () async {
        var collectionId = 'tekartik_test_root_collection_missing';
        var doc = firestore.doc('$collectionId/missing/sub/doc');
        await doc.set({});
        try {
          expect(
            (await firestore.listCollections()).map((e) => e.id),
            contains(collectionId),
          );
        } finally {
          await doc.delete();
        }
        expect(
          (await firestore.listCollections()).map((e) => e.id),
          isNot(contains(collectionId)),
        );
      },
      skip: skipMissing,
      timeout: const Timeout(Duration(minutes: 1)),
    );
  });
}
