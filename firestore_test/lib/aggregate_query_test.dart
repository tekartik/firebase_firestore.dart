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
      test('empty collection', () async {
        var collectionId = 'aggregate_query_empty_collection';
        var collection = firestore.collection(join(docParent, collectionId));
        await deleteCollection(firestore, collection);
        expect(await collection.count(), 0);

        var snapshot = await collection.aggregate([
          AggregateField.count(),
          //AggregateField.average('value'),
          AggregateField.sum('value')
        ]).get();
        expect(snapshot.count, 0);
        expect(snapshot.getAverage('value'), isNull);
        expect(snapshot.getSum('value'), closeTo(0, 0.01));

        try {
          snapshot = await collection.aggregate([
            AggregateField.average('value'),
          ]).get();
          expect(snapshot.getAverage('value'), isNull);
        } catch (e) {
          print('Failing OK for flutter here: $e');
        }
      });
      // firestore = firestore.debugQuickLoggerWrapper();
      test('one item', () async {
        var collectionId = 'aggregate_query_one_item';
        var collection = firestore.collection(join(docParent, collectionId));
        await deleteCollection(firestore, collection);
        var doc = collection.doc('doc');
        expect(await collection.count(), 0);

        /*
        var snapshot = await collection.aggregate([
          AggregateField.count(),
          //AggregateField.average('value'),
          AggregateField.sum('value')
        ]).get();
        expect(snapshot.count, 0);
        expect(snapshot.getAverage('value'), isNull);
        expect(snapshot.getSum('value'), closeTo(0, 0.01));

         */
        await doc.set({'value': 2});
        expect(await collection.count(), 1);
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
          transaction.set(collection.doc('doc3'), {'test': 3, 'value': 8});
          transaction.set(collection.doc('doc4'), {'test': 4, 'value': 8.5});
          transaction.set(collection.doc('doc5'), {'test': 5, 'value': null});
          transaction.set(
              collection.doc('doc6'), {'test': 6, 'value': 'not a number'});
        });
        var snapshot =
            await collection.where('test', isGreaterThan: 1).aggregate([
          AggregateField.count(),
          AggregateField.average('value'),
          AggregateField.sum('value'),
          AggregateField.average('test'),
          AggregateField.sum('test')
        ]).get();
        expect(snapshot.count, 5);
        expect(snapshot.getAverage('value'), closeTo(7.333, 0.01));
        expect(snapshot.getSum('value'), closeTo(22, 0.01));
        expect(snapshot.getAverage('test'), closeTo(4, 0.01));
        expect(snapshot.getSum('test'), closeTo(20, 0.01));
      });
    },
    skip: !firestore.service.supportsAggregateQueries,
  );
}
