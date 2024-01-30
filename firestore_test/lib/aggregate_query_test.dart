// ignore_for_file: inference_failure_on_collection_literal

import 'package:path/path.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/collection.dart';
// ignore: implementation_imports
import 'package:test/test.dart';

import 'firestore_test.dart';

void runAggregateQueryTest(
    {required Firestore firestore,
    required FirestoreTestContext? testContext}) {
  var testsRefPath = FirestoreTestContext.getRootCollectionPath(testContext);
  var docParent = url.join(testsRefPath, 'tekartik_test_aggregate_query');
  group(
    'aggregate_query',
    () {
      // firestore = firestore.debugQuickLoggerWrapper();
      test('one item', () async {
        var collectionId = 'aggregate_query_one_item';
        var collection = firestore.collection(join(docParent, collectionId));
        await deleteCollection(firestore, collection);
        var doc = collection.doc('doc');
        await doc.set({'value': 2});
        var snapshot = await collection.aggregate([
          AggregateField.count(),
          AggregateField.average('value'),
          AggregateField.sum('value')
        ]).get();
        expect(snapshot.count, 1);
        expect(snapshot.getAverage('value'), closeTo(2, 0.01));
        expect(snapshot.getSum('value'), closeTo(2, 0.01));
      });
      test('complex', () async {
        // Warning this requires an index
        var collectionId = 'aggregate_query_complex';
        var collection = firestore.collection(join(docParent, collectionId));
        await deleteCollection(firestore, collection);
        await firestore.runTransaction((transaction) async {
          transaction.set(collection.doc('doc1'), {'test': 1, 'value': 3});
          transaction.set(collection.doc('doc2'), {'test': 2, 'value': 5.5});
          transaction.set(collection.doc('doc3'), {'test': 2, 'value': 8});
          transaction.set(collection.doc('doc4'), {'test': 2, 'value': 8.5});
          transaction.set(collection.doc('doc5'), {'test': 2, 'value': null});
          transaction.set(
              collection.doc('doc6'), {'test': 2, 'value': 'not a number'});
        });
        var snapshot = await collection.where('test', isEqualTo: 2).aggregate([
          AggregateField.count(),
          AggregateField.average('value'),
          AggregateField.sum('value')
        ]).get();
        expect(snapshot.count, 5);
        expect(snapshot.getAverage('value'), closeTo(7.333, 0.01));
        expect(snapshot.getSum('value'), closeTo(22, 0.01));
      });
    },
    skip: !firestore.service.supportsAggregateQueries,
  );
}
