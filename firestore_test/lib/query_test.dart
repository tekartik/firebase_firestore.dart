// ignore_for_file: inference_failure_on_collection_literal

import 'package:dev_test/test.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
// ignore: implementation_imports
import 'package:tekartik_firebase_firestore/utils/collection.dart';

import 'firestore_test.dart';

void runFirestoreQueryTests(
    {required Firestore firestore, required FirestoreTestContext testContext}) {
  group('query', () {
    CollectionReference getTestsRef() {
      return firestore.collection(testContext.rootCollectionPath);
    }

    test('select', () async {
      var testsRef = getTestsRef();
      var collRef = testsRef.doc('collection_test').collection('select');
      var docRef = collRef.doc('one');
      await docRef.set({'field1': 1, 'field2': 2});
      expect(await collRef.count(), 1);
      var querySnapshot = await collRef.select(['field1']).get();
      var data = querySnapshot.docs.first.data;
      if (firestore.service.supportsQuerySelect) {
        expect(data, {'field1': 1});
      } else {
        expect(data, {'field1': 1, 'field2': 2});
      }
      querySnapshot = await collRef.select(['field2']).get();
      data = querySnapshot.docs.first.data;
      if (firestore.service.supportsQuerySelect) {
        expect(data, {'field2': 2});
      } else {
        expect(data, {'field1': 1, 'field2': 2});
      }

      querySnapshot = await collRef.select(['field1', 'field2']).get();
      data = querySnapshot.docs.first.data;
      expect(data, {'field1': 1, 'field2': 2});
    });

    test('order_by_different_type', () async {
      var testsRef = getTestsRef();
      var collRef =
          testsRef.doc('collection_test').collection('order_by_different_type');
      await deleteCollection(firestore, collRef);
      await firestore.runTransaction((txn) {
        txn.set(collRef.doc('0'), {'value': 0});
        txn.set(collRef.doc('0.5'), {'value': 0.5});
        txn.set(collRef.doc('1'), {'value': 1});
        txn.set(collRef.doc('false'), {'value': false});
        txn.set(collRef.doc('-1'), {'value': -1});
        txn.set(collRef.doc('true'), {'value': true});
        txn.set(collRef.doc('text'), {'value': 'text'});
        txn.set(collRef.doc('timestamp'), {'value': Timestamp(1, 2000)});
        txn.set(collRef.doc('bytes'), {
          'value': Blob.fromList([1, 2, 3])
        });
        txn.set(collRef.doc('list'), {
          'value': [1]
        });
        txn.set(collRef.doc('map'), {
          'value': {'test': 1}
        });
        txn.set(collRef.doc('bytes'), {
          'value': Blob.fromList([1, 2, 3])
        });
        txn.set(collRef.doc('ref'), {'value': firestore.doc('test/1')});
        txn.set(collRef.doc('geoPoint'), {'value': GeoPoint(1, 2)});
      });

      Future<void> check() async {
        var querySnapshot = await collRef.orderBy('value').get();
        expect(querySnapshot.ids, [
          'false',
          'true',
          '-1',
          '0',
          '0.5',
          '1',
          'timestamp',
          'text',
          'bytes',
          'ref',
          'geoPoint',
          'list',
          'map'
        ]);
      }

      await testContext.runTestAndIfNeededAllowDelay(check);
    });
    test('order_by_name', () async {
      var testsRef = getTestsRef();
      var collRef = testsRef.doc('collection_test').collection('order');
      await deleteCollection(firestore, collRef);
      var twoRef = collRef.doc('two');
      var oneRef = collRef.doc('one');
      await firestore.runTransaction((txn) {
        txn.set(oneRef, {});
        txn.set(twoRef, {});
      });

      Future<void> check() async {
        var querySnapshot = await collRef.get();
        // Order by name by default
        expect(querySnapshot.docs[0].ref.path, oneRef.path);
        expect(querySnapshot.docs[1].ref.path, twoRef.path);

        expect(await collRef.count(), 2);

        querySnapshot = await collRef.orderBy(firestoreNameFieldPath).get();
        // Order by name by default
        expect(querySnapshot.docs[0].ref.path, oneRef.path);
        expect(querySnapshot.docs[1].ref.path, twoRef.path);
      }

      await testContext.runTestAndIfNeededAllowDelay(check);
    });

    test('order_by_key', () async {
      var testsRef = getTestsRef();
      var collRef = testsRef.doc('collection_test').collection('order_by_key');
      await deleteCollection(firestore, collRef);
      var oneRef = collRef.doc('one');
      await oneRef.set({});
      var twoRef = collRef.doc('two');
      await twoRef.set({});
      var threeRef = collRef.doc('three');
      await threeRef.set({});

      var querySnapshot = await collRef.orderById().get();
      // Order by name by default
      expect(querySnapshot.ids, [oneRef, threeRef, twoRef].ids);
      querySnapshot = await collRef.orderById(descending: true).get();
      // Order by name by default
      expect(querySnapshot.ids, [twoRef, threeRef, oneRef].ids);
    }, skip: 'Not supported on all platforms');

    /// Requires an index
    test('where_and_order_by_name', () async {
      var testsRef = getTestsRef();
      var collRef =
          testsRef.doc('collection_test').collection('where_and_order');
      await deleteCollection(firestore, collRef);
      var oneRef = collRef.doc('one');
      var twoRef = collRef.doc('two');
      var threeRef = collRef.doc('three');
      await firestore.runTransaction((transaction) {
        transaction.set(oneRef, {'name': 1, 'target': 1});
        transaction.set(twoRef, {'name': 2, 'target': 1});
        transaction.set(threeRef, {'name': 3, 'target': 2});
      });

      var query = collRef
          .where('target', isEqualTo: 1)
          .orderBy('name', descending: true);
      var querySnapshot = await collRef.get();
      // Order by name by default
      expect(docsKeys(querySnapshot.docs), [twoRef, oneRef]);

      expect(await query.count(), 2);
    }, skip: true);

    bool isNodePlatform() {
      return firestore.service.toString().contains('firestore.serviceNode');
    }

    test('order_desc_field_and_key', () async {
      try {
        var testsRef = getTestsRef();
        var collRef = testsRef
            .doc('collection_test')
            .collection('order_desc_field_and_key');
        await deleteCollection(firestore, collRef);
        var oneRef = collRef.doc('one');
        await oneRef.set({'value': 2});
        var twoRef = collRef.doc('two');
        await twoRef.set({'value': 1});
        var threeRef = collRef.doc('three');
        await threeRef.set({'value': 1});

        QuerySnapshot querySnapshot;

        querySnapshot = await collRef
            .orderBy('value', descending: true)
            .orderBy(firestoreNameFieldPath)
            .get();
        // Order by name by default
        expect(querySnapshot.docs[0].ref.path, oneRef.path);
        expect(querySnapshot.docs[1].ref.path, threeRef.path);
        expect(querySnapshot.docs[2].ref.path, twoRef.path);

        querySnapshot = await collRef
            .orderBy('value', descending: true)
            .orderBy(firestoreNameFieldPath)
            .startAt(values: [1, 'three']).get();
        // Order by name by default

        expect(querySnapshot.docs[0].ref.path, threeRef.path);
        expect(querySnapshot.docs[1].ref.path, twoRef.path);
      } catch (e) {
        // Allow failure on node
        if (isNodePlatform()) {
          print('failure $e on node');
        } else {
          rethrow;
        }
      }
    });

    test('between', () async {
      var testsRef = getTestsRef();
      var collRef = testsRef.doc('collection_test').collection('between');
      await deleteCollection(firestore, collRef);
      var oneRef = collRef.doc('2_1');
      await oneRef.set({'value': 1});
      var twoRef = collRef.doc('3_2');
      await twoRef.set({'value': 2});
      var threeRef = collRef.doc('1_3');
      await threeRef.set({'value': 3});

      var querySnapshot = await collRef.orderBy('value').get();
      expect(querySnapshot.ids, [oneRef, twoRef, threeRef].ids);
      querySnapshot = await collRef
          .orderBy('value')
          .startAt(values: [2]).endBefore(values: [3]).get();
      expect(querySnapshot.ids, [twoRef].ids);
      querySnapshot = await collRef.orderBy('value', descending: true).get();
      expect(querySnapshot.ids, [threeRef, twoRef, oneRef].ids);
    });

    test('complex', () async {
      var testsRef = getTestsRef();
      var collRef = testsRef.doc('collection_test').collection('many');
      var docRefOne = collRef.doc('one');
      List<DocumentSnapshot> list;
      await docRefOne.set({
        'array': [3, 4],
        'value': 1,
        'date': DateTime.fromMillisecondsSinceEpoch(2),
        'timestamp': Timestamp(2, 0),
        'sub': {'value': 'b'}
      });
      var docRefTwo = collRef.doc('two');
      await docRefTwo.set({
        'value': 2,
        'date': DateTime.fromMillisecondsSinceEpoch(1),
        'sub': {'value': 'a'}
      });
      // limit
      var querySnapshot = await collRef.limit(1).get();
      list = querySnapshot.docs;
      expect(list.length, 1);

      /*
        // offset
        querySnapshot = await collRef.orderBy('value').offset(1).get();
        list = querySnapshot.docs;
        expect(list.length, 1);
        */

      // order by
      querySnapshot = await collRef.orderBy('value').get();
      list = querySnapshot.docs;
      expect(list.length, 2);
      expect(list.first.ref.id, 'one');

      // order by date
      querySnapshot = await collRef.orderBy('date').get();
      list = querySnapshot.docs;
      expect(list.length, 2);
      expect(list.first.ref.id, 'two');

      // order by timestamp
      querySnapshot = await collRef.orderBy('timestamp').get();
      list = querySnapshot.docs;
      expect(list.length, 1);
      expect(list.first.ref.id, 'one');

      // order by sub field
      querySnapshot = await collRef.orderBy('sub.value').get();
      list = querySnapshot.docs;
      expect(list.length, 2);
      expect(list.first.ref.id, 'two');

      // desc
      querySnapshot = await collRef.orderBy('value', descending: true).get();
      list = querySnapshot.docs;
      expect(list.length, 2);
      expect(list.first.ref.id, 'two');

      // start at
      querySnapshot = await collRef.orderBy('value').startAt(values: [2]).get();
      list = querySnapshot.docs;
      expect(list.length, 1, reason: 'check startAt implementation');
      expect(list.first.ref.id, 'two');

      // start after
      querySnapshot =
          await collRef.orderBy('value').startAfter(values: [1]).get();
      list = querySnapshot.docs;
      expect(list.length, 1, reason: 'check startAfter implementation');
      expect(list.first.ref.id, 'two');

      // end at
      querySnapshot = await collRef.orderBy('value').endAt(values: [1]).get();
      list = querySnapshot.docs;
      expect(list.length, 1, reason: 'check endAt implementation');
      expect(list.first.ref.id, 'one');

      // end before
      querySnapshot =
          await collRef.orderBy('value').endBefore(values: [2]).get();
      list = querySnapshot.docs;
      expect(list.length, 1);
      expect(list.first.ref.id, 'one');

      if (firestore.service.supportsQuerySnapshotCursor) {
        // start after using snapshot
        querySnapshot = await collRef
            .orderBy('value')
            .startAfter(snapshot: list.first)
            .get();
        list = querySnapshot.docs;
        expect(list.length, 1);
        expect(list.first.ref.id, 'two');
      }

      // where >
      querySnapshot = await collRef.where('value', isGreaterThan: 1).get();
      list = querySnapshot.docs;
      expect(list.length, 1);
      expect(list.first.ref.id, 'two');

      // where >=
      querySnapshot =
          await collRef.where('value', isGreaterThanOrEqualTo: 2).get();
      list = querySnapshot.docs;
      expect(list.length, 1);
      expect(list.first.ref.id, 'two');

      // where >= timestamp
      querySnapshot = await collRef
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp(2, 0))
          .get();
      list = querySnapshot.docs;

      expect(list.length, 1);
      expect(list.first.ref.id, 'one');

      // where == timestamp
      querySnapshot = await collRef
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp(2, 0))
          .get();
      list = querySnapshot.docs;

      expect(list.length, 1);
      expect(list.first.ref.id, 'one');

      // where > timestamp
      querySnapshot = await collRef
          .where('timestamp', isGreaterThan: Timestamp(2, 0))
          .get();
      list = querySnapshot.docs;
      expect(list.length, 0);

      // where > timestamp
      querySnapshot = await collRef
          .where('timestamp', isGreaterThan: Timestamp(1, 1))
          .get();
      list = querySnapshot.docs;
      expect(list.length, 1);
      expect(list.first.ref.id, 'one');

      // where <
      querySnapshot = await collRef.where('value', isLessThan: 2).get();
      list = querySnapshot.docs;
      expect(list.length, 1);
      expect(list.first.ref.id, 'one');

      // where <=
      querySnapshot =
          await collRef.where('value', isLessThanOrEqualTo: 1).get();
      list = querySnapshot.docs;
      expect(list.length, 1);
      expect(list.first.ref.id, 'one');

      // array contains
      querySnapshot = await collRef.where('array', arrayContains: 4).get();
      list = querySnapshot.docs;
      expect(list.length, 1);
      expect(list.first.ref.id, 'one');

      querySnapshot = await collRef.where('array', arrayContains: 5).get();
      list = querySnapshot.docs;
      expect(list.length, 0);

      // failed on rest
      try {
        querySnapshot =
            await collRef.where('array', arrayContainsAny: [4]).get();
        list = querySnapshot.docs;
        expect(list.length, 1);
        expect(list.first.ref.id, 'one');
      } catch (e) {
        print('Allow rest failure: $e');
      }

      // complex object
      querySnapshot =
          await collRef.where('sub', isEqualTo: {'value': 'a'}).get();
      list = querySnapshot.docs;
      expect(list.length, 1);
      expect(list.first.ref.id, 'two');

      // ordered by sub (complex object)
      querySnapshot = await collRef.orderBy('sub').get();
      list = querySnapshot.docs;
      expect(list.length, 2);
      expect(list.first.ref.id, 'two');
    });

    test('array_complex', () async {
      var testsRef = getTestsRef();
      var collRef = testsRef.doc('collection_test').collection('array');
      var docRefOne = collRef.doc('one');
      List<DocumentSnapshot> list;
      await docRefOne.set({
        'array': [3, 4],
        'timestamp_array': [Timestamp(1, 1)]
      });
      var docRefTwo = collRef.doc('two');
      await docRefTwo.set({
        'array': [3],
        'timestamp_array': [Timestamp(1, 1), Timestamp(2, 2)]
      });
      var docRefThree = collRef.doc('three');
      await docRefThree.set({
        'array': [5],
      });

      // array contains
      var querySnapshot = await collRef.where('array', arrayContains: 4).get();
      list = querySnapshot.docs;
      expect(list.length, 1);
      expect(list.first.ref.id, 'one');

      querySnapshot = await collRef.where('array', arrayContains: 6).get();
      list = querySnapshot.docs;
      expect(list.length, 0);

      try {
        // array contains any
        try {
          await collRef.where('array', arrayContainsAny: []).get();
          fail('should fail');
        } catch (e) {
          // devPrint(e);
          // FirebaseError: [code=invalid-argument]: Invalid Query. A non-empty array is required for 'array-contains-any' filters.
        }

        querySnapshot =
            await collRef.where('array', arrayContainsAny: [4]).get();
        list = querySnapshot.docs;
        expect(list.length, 1);
        expect(list.first.ref.id, 'one');

        querySnapshot =
            await collRef.where('array', arrayContainsAny: [4, 5]).get();
        list = querySnapshot.docs;
        expect(list.length, 2);
        expect(list.first.ref.id, 'one');

        querySnapshot = await collRef.where('timestamp_array',
            arrayContainsAny: [Timestamp(1, 1)]).get();
        list = querySnapshot.docs;
        expect(list.length, 2);
        expect(list.first.ref.id, 'one');
      } catch (e) {
        print('Allow REST failure for: $e');
      }
    });

    test('order', () async {
      var testsRef = getTestsRef();
      var collRef =
          testsRef.doc('collection_test').collection('complex_timestamp');
      var docRefOne = collRef.doc('one');
      var docRefTwo = collRef.doc('two');

      List<DocumentSnapshot> list;
      var timestamp2 = Timestamp.fromMillisecondsSinceEpoch(2);
      var date2 = DateTime.fromMillisecondsSinceEpoch(2);

      var map2 = <String, Object?>{
        'date': date2,
        'int': 2,
        'text': '2',
        'double': 1.5
      };
      if (firestore.service.supportsTimestamps) {
        map2['timestamp'] = timestamp2;
      }

      var timestamp1 = Timestamp.fromMillisecondsSinceEpoch(1);
      var date1 = DateTime.fromMillisecondsSinceEpoch(1);

      var map1 = <String, Object?>{
        'date': date1,
        'int': 1,
        'text': '1',
        'double': 0.5
      };
      if (firestore.service.supportsTimestamps) {
        map1['timestamp'] = timestamp1;
      }

      await docRefTwo.set(map2);
      await docRefOne.set(map1);

      Future testField<T>(String field, T value1, T value2) async {
        var reason = '$field $value1 $value2';
        // order by
        var querySnapshot = await collRef.orderBy(field).get();
        list = querySnapshot.docs;
        expect(list.length, 2);
        expect(list.first.ref.id, 'one', reason: reason);

        // start at
        querySnapshot =
            await collRef.orderBy(field).startAt(values: [value2]).get();
        list = querySnapshot.docs;
        expect(list.length, 1, reason: reason);
        expect(list.first.ref.id, 'two');

        // start after
        querySnapshot =
            await collRef.orderBy(field).startAfter(values: [value1]).get();
        list = querySnapshot.docs;
        expect(list.length, 1);
        expect(list.first.ref.id, 'two');

        // end at
        querySnapshot =
            await collRef.orderBy(field).endAt(values: [value1]).get();
        list = querySnapshot.docs;
        expect(list.length, 1);
        expect(list.first.ref.id, 'one');

        // end before
        querySnapshot =
            await collRef.orderBy(field).endBefore(values: [value2]).get();
        list = querySnapshot.docs;
        expect(list.length, 1);
        expect(list.first.ref.id, 'one');

        if (firestore.service.supportsQuerySnapshotCursor) {
          // start after using snapshot
          querySnapshot = await collRef
              .orderBy(field)
              .startAfter(snapshot: list.first)
              .get();
          list = querySnapshot.docs;
          expect(list.length, 1);
          expect(list.first.ref.id, 'two');
        }

        // where >
        querySnapshot = await collRef.where(field, isGreaterThan: value1).get();
        list = querySnapshot.docs;
        expect(list.length, 1);
        expect(list.first.ref.id, 'two');

        // where >=
        querySnapshot =
            await collRef.where(field, isGreaterThanOrEqualTo: value2).get();
        list = querySnapshot.docs;
        expect(list.length, 1);
        expect(list.first.ref.id, 'two');

        // where <
        querySnapshot = await collRef.where(field, isLessThan: value2).get();
        list = querySnapshot.docs;
        expect(list.length, 1);
        expect(list.first.ref.id, 'one');

        // where <=
        querySnapshot =
            await collRef.where(field, isLessThanOrEqualTo: value1).get();
        list = querySnapshot.docs;
        expect(list.length, 1);
        expect(list.first.ref.id, 'one');
      }

      await testField('int', 1, 2);

      await testField('double', .5, 1.5);
      await testField('text', '1', '2');
      await testField('date', date1, date2);
      if (firestore.service.supportsTimestamps) {
        await testField('timestamp', timestamp1, timestamp2);
      }
    }, timeout: Timeout(Duration(seconds: 120)));

    test('nested_object_order', () async {
      var testsRef = getTestsRef();
      var collRef = testsRef.doc('nested_order_test').collection('many');
      var docRefOne = collRef.doc('one');
      await docRefOne.set({
        'sub': {'value': 'b'}
      });
      var docRefTwo = collRef.doc('two');
      await docRefTwo.set({
        'sub': {'value': 'a'}
      });
      var docRefThree = collRef.doc('three');
      await docRefThree.set({'no_sub': false});
      var docRefFour = collRef.doc('four');
      await docRefFour.set({
        'sub': {'other': 'a', 'value': 'c'}
      });

      List<String> querySnapshotDocIds(QuerySnapshot querySnapshot) {
        return querySnapshot.docs.map((snapshot) => snapshot.ref.id).toList();
      }

      // complex object
      var querySnapshot =
          await collRef.where('sub', isEqualTo: {'value': 'a'}).get();
      expect(querySnapshotDocIds(querySnapshot), ['two']);

      // ordered by sub (complex object)
      querySnapshot = await collRef.orderBy('sub').get();
      expect(querySnapshotDocIds(querySnapshot), ['four', 'two', 'one']);
    });

    test('list_object_order', () async {
      var testsRef = getTestsRef();
      var collRef = testsRef.doc('list_order_test').collection('many');
      var docRefOne = collRef.doc('one');
      await docRefOne.set({
        'sub': ['b']
      });
      var docRefTwo = collRef.doc('two');
      await docRefTwo.set({
        'sub': ['a']
      });
      var docRefThree = collRef.doc('three');
      await docRefThree.set({'no_sub': false});
      var docRefFour = collRef.doc('four');
      await docRefFour.set({
        'sub': ['a', 'b']
      });

      // complex object
      var querySnapshot = await collRef.where('sub', isEqualTo: ['a']).get();
      expect(querySnapshotDocIds(querySnapshot), ['two']);

      // ordered by sub (complex object)
      querySnapshot = await collRef.orderBy('sub').get();
      expect(querySnapshotDocIds(querySnapshot), ['two', 'four', 'one']);
    });

    test('whereIn', () async {
      var testsRef = getTestsRef();
      var collRef = testsRef.doc('where_in_test').collection('simple');
      var docRefOne = collRef.doc('one');
      await docRefOne.set({'value': 1});
      var docRefTwo = collRef.doc('two');
      await docRefTwo.set({'value': 2});
      var querySnapshot = await collRef.where('value', whereIn: [1]).get();
      expect(querySnapshotDocIds(querySnapshot), ['one']);
      querySnapshot = await collRef.where('value', whereIn: [1, 2, 3]).get();
      expect(querySnapshotDocIds(querySnapshot), ['one', 'two']);
    });

    test('onQuerySnapshot', () async {
      var testsRef = getTestsRef();
      var collRef = testsRef.doc('query_test').collection('onSnapshot');

      var docRef = collRef.doc('item');
      // delete it
      await docRef.delete();
      if (firestore.service.supportsTrackChanges) {
        var completer1 = Completer<void>();
        var completer2 = Completer<void>();
        var completer3 = Completer<void>();
        var completer4 = Completer<void>();
        var count = 0;
        var onCountResults = <int>[];
        var countSubscription = collRef.onCount().listen((count) {
          onCountResults.add(count);
        });
        var subscription =
            collRef.onSnapshot().listen((QuerySnapshot querySnapshot) {
          if (++count == 1) {
            // first step ignore the result
            completer1.complete();
          } else if (count == 2) {
            // second step expect an added item
            expect(querySnapshot.documentChanges.length, 1);
            expect(querySnapshot.documentChanges.first.type,
                DocumentChangeType.added);

            completer2.complete();
          } else if (count == 3) {
            // second step expect a modified item
            expect(querySnapshot.documentChanges.length, 1);
            expect(querySnapshot.documentChanges.first.type,
                DocumentChangeType.modified);

            completer3.complete();
          } else if (count == 4) {
            // second step expect a deletion
            expect(querySnapshot.documentChanges.length, 1);
            expect(querySnapshot.documentChanges.first.type,
                DocumentChangeType.removed);

            completer4.complete();
          }
        });
        // wait for receiving first data
        await completer1.future;

        // create it
        await docRef.set({});

        // wait for receiving change data
        await completer2.future;

        // modify it
        await docRef.set({'value': 1});

        // wait for receiving change data
        await completer3.future;

        // delete it
        await docRef.delete();

        // wait for receiving change data
        await completer4.future;

        await subscription.cancel();
        // Allow count to come later
        await sleep(100);
        await countSubscription.cancel();
        expect(onCountResults, [0, 1, 1, 0]);
      }
    });
  });
}
