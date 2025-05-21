// ignore_for_file: inference_failure_on_collection_literal

// ignore: implementation_imports
import 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/copy_utils.dart';

import 'firestore_test.dart';

void runListCollectionsTest({
  required Firestore firestore,
  required FirestoreTestContext? testContext,
}) {
  var testsRefPath = FirestoreTestContext.getRootCollectionPath(testContext);
  group('list collections', () {
    // firestore = firestore.debugQuickLoggerWrapper();
    test('list root collections', () async {
      var collectionId = 'tekartik_test_root_collection';
      var doc = firestore.doc('$collectionId/doc');
      var collections = await firestore.listCollections();
      await doc.set({});
      expect(
        (await firestore.collection(collectionId).recursiveListDocuments()).map(
          (e) => e.path,
        ),
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
        (await firestore.collection(collectionId).recursiveListDocuments()).map(
          (e) => e.path,
        ),
        isEmpty,
      );
    }, skip: !firestore.service.supportsListCollections);

    test('list doc collections', () async {
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
      collections = await firestore.listCollections();
      expect(collections.map((e) => e.id), isNot(contains(collectionId)));
      expect(
        (await collection.recursiveListDocuments()).map((e) => e.path),
        isEmpty,
      );
    }, skip: !firestore.service.supportsListCollections);
  });
}
