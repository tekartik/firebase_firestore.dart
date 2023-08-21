// ignore_for_file: inference_failure_on_collection_literal

import 'package:path/path.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
// ignore: implementation_imports
import 'package:tekartik_firebase_firestore_test/utils_test.dart';
import 'package:test/test.dart';

void runListCollectionsTest({
  required Firestore firestore,
}) {
  test('list root collections', () async {
    var collectionId = 'tekartik_test_root_collection';
    var doc = firestore.doc('$collectionId/doc');
    await doc.set({});
    var collections = await firestore.listCollections();
    var collection =
        collections.firstWhere((element) => element.id == collectionId);
    expect(collection.path, collectionId);
    await doc.delete();
  }, solo: true, skip: !firestore.service.supportsListCollections);

  test('list doc collections', () async {
    var parent = url.join(testsRefPath, 'tekartik_test_collection');
    var collectionId = 'sub';
    var doc = firestore.doc('$parent/$collectionId/doc');
    await doc.set({});
    var collections = await firestore.doc(parent).listCollections();
    expect(collections.map((e) => e.id), contains(collectionId));
    await doc.delete();
  }, skip: !firestore.service.supportsListCollections);
}
