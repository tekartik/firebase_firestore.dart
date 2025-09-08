// ignore_for_file: inference_failure_on_collection_literal

import 'package:dev_test/test.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/collection.dart';
// ignore: implementation_imports

import 'firestore_test.dart';

void runFirestoreCollectionGroupTests({
  required Firestore firestore,
  FirestoreTestContext? testContext,
}) {
  var testsRefPath = FirestoreTestContext.getRootCollectionPath(testContext);
  var rootTestsDoc = firestore.collection(testsRefPath).doc('collection_group');
  // var rootTestsCollection = rootTestsDoc.collection('tests');
  group('collectionGroup', () {
    test('query', () async {
      var coll = rootTestsDoc.collection('query');
      await coll.delete();
      var collectionId = 'tekartik_collection_group_query1';

      var topDoc1 = coll.doc('doc1');
      var topDoc2 = coll.doc('doc2');
      var col1 = topDoc1.collection(collectionId);
      var col2 = topDoc2.collection(collectionId);
      var doc1 = col1.doc('sub_doc1');
      var doc2 = col2.doc('sub_doc1');
      var doc3 = col2.doc('sub_doc2');
      await firestore.runTransaction((txn) async {
        txn.set(doc1, {'name': 'B doc1'});
        txn.set(doc2, {'name': 'C doc2'});
        txn.set(doc3, {'name': 'A doc3'});
      });
      var query = firestore.collectionGroup(collectionId).orderBy('name');
      var snapshot = await query.get();
      expect(snapshot.ids, [doc3.id, doc1.id, doc2.id]);
    }, skip: true);
  });
}
