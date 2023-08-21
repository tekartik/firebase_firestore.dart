// ignore_for_file: inference_failure_on_collection_literal

import 'package:path/path.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
// ignore: implementation_imports
import 'package:tekartik_firebase_firestore_test/utils_test.dart';
import 'package:test/test.dart';

void runListCollectionsTest({
  required Firestore firestore,
}) {
  // firestore = firestore.debugQuickLoggerWrapper();
  test('list root collections', () async {
    var collectionId = 'tekartik_test_root_collection';
    var doc = firestore.doc('$collectionId/doc');
    var collections = await firestore.listCollections();
    print('Existing root collections: $collections');
    await doc.set({});
    collections = await firestore.listCollections();
    print('New root collections: $collections');
    var collection =
        collections.firstWhere((element) => element.id == collectionId);
    expect(collection.path, collectionId);
    await doc.delete();
  }, skip: !firestore.service.supportsListCollections);

  test('list doc collections', () async {
    var parent = url.join(testsRefPath, 'tekartik_test_collection');
    var collectionId = 'sub';
    var doc = firestore.doc('$parent/$collectionId/doc');
    var collections = await firestore.doc(parent).listCollections();
    print('Existing collections: $collections');
    await doc.set({});
    collections = await firestore.doc(parent).listCollections();
    print('New collections: $collections');
    expect(collections.map((e) => e.id), contains(collectionId));
    await doc.delete();
  }, skip: !firestore.service.supportsListCollections);
}
