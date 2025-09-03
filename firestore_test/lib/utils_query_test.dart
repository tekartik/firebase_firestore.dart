import 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/query.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';

void runUtilsQueryTest({
  required FirestoreService firestoreService,
  required Firestore firestore,
  required FirestoreTestContext? testContext,
}) {
  group('utils_query', () {
    var testsRefPath = url.join(
      FirestoreTestContext.getRootCollectionPath(testContext),
    );

    test('deleteQuery one', () async {
      var ref = firestore.collection(
        url.join(testsRefPath, 'utils_query', 'delete_one'),
      );
      var query = ref;
      await deleteQuery(firestore, query);
      var itemDoc = ref.doc('item');
      // create an item
      await itemDoc.set({});

      Future<bool> findInCollection() async {
        var querySnapshot = await ref.get();
        for (var doc in querySnapshot.docs) {
          if (doc.ref.path == itemDoc.path) {
            return true;
          }
        }
        return false;
      }

      expect(await findInCollection(), isTrue);
      var count = await deleteQuery(firestore, ref);
      expect(count, 1);
      expect(await findInCollection(), isFalse);
    });

    test('deleteQuery two', () async {
      var ref = firestore.collection(
        url.join(testsRefPath, 'utils_query', 'delete_two'),
      );
      await deleteQuery(firestore, ref);
      var itemDoc = ref.doc('item1');
      var itemDoc2 = ref.doc('item2');
      // create two items
      await firestore.runTransaction((txn) {
        txn.set(itemDoc, {});
        txn.set(itemDoc2, {});
      });

      Future<bool> findInCollection() async {
        var querySnapshot = await ref.get();
        for (var doc in querySnapshot.docs) {
          if (doc.ref.path == itemDoc.path) {
            return true;
          }
        }
        return false;
      }

      Future<bool> find2InCollection() async {
        var querySnapshot = await ref.get();
        for (var doc in querySnapshot.docs) {
          if (doc.ref.path == itemDoc2.path) {
            return true;
          }
        }
        return false;
      }

      Future<void> check() async {
        expect(await findInCollection(), isTrue);
        expect(await find2InCollection(), isTrue);
      }

      try {
        await check();
      } catch (_) {
        if (testContext?.allowedDelayInReadMs != null) {
          await testContext?.sleepReadDelay();
          await check();
        } else {
          rethrow;
        }
      }
      var count = await deleteQuery(firestore, ref, batchSize: 1);
      expect(count, 2);
      expect(await findInCollection(), isFalse);
      expect(await find2InCollection(), isFalse);
    });

    test('deleteQuery batchSize and limit', () async {
      var collRef = firestore.collection(
        url.join(testsRefPath, 'utils_query', 'delete_limit'),
      );

      Future<int> getCount() async {
        return (await collRef.count());
      }

      await deleteQuery(firestore, collRef);
      expect(await getCount(), 0);
      await firestore.runTransaction((txn) {
        for (var i = 0; i < 10; i++) {
          var id = (i + 1).toString().padLeft(3, '0');
          var timestamp = Timestamp.now();
          txn.set(collRef.doc(id), {'timestamp': timestamp});
        }
      });
      var query = collRef.orderBy('timestamp');
      expect(await query.queryDelete(limit: 7, batchSize: 3), 7);
      expect(await getCount(), 3);
    });
    test('actionQuery batchSize and limit', () async {
      var collRef = firestore.collection(
        url.join(testsRefPath, 'utils_query', 'action_query'),
      );

      Future<int> getCount() async {
        return (await collRef.count());
      }

      await deleteQuery(firestore, collRef);
      expect(await getCount(), 0);
      await firestore.runTransaction((txn) {
        for (var i = 0; i < 10; i++) {
          var id = (i + 1).toString().padLeft(2, '0');
          var timestamp = Timestamp.now();
          txn.set(collRef.doc(id), {'text': id, 'timestamp': timestamp});
        }
      });

      var query = collRef.where('text', isLessThanOrEqualTo: '03');
      expect(await query.count(), 3);
      query = collRef.where('text', isLessThanOrEqualTo: '03').orderBy('text');
      expect(await query.count(), 3);
      query = collRef.where('text', isLessThanOrEqualTo: '07').orderBy('text');
      expect(
        await query.queryAction(
          limit: 9,
          batchSize: 3,
          orderByFields: ['text'],
          actionFunction: (ids) async {
            return ids.length;
          },
        ),
        7,
      );
      query = collRef
          .where('text', isGreaterThanOrEqualTo: '07')
          .orderBy('text');
      expect(
        await query.queryAction(
          limit: 9,
          batchSize: 3,
          orderByFields: ['text'],
          actionFunction: (ids) async {
            return ids.length;
          },
        ),
        4,
      );
    });

    test('invalid query', () async {
      var ref = firestore.collection(
        url.join(testsRefPath, 'utils_query', 'invalid_query'),
      );
      var query = ref
          .where('text', isGreaterThanOrEqualTo: '07')
          .orderBy(firestoreNameFieldPath);
      try {
        // node: invalid_query: caught [cloud_firestore/invalid-argument] Order by clause cannot contain more fields after the key text
        await query.get();
        fail('should fail');
      } catch (e) {
        // ignore: avoid_print
        print('invalid_query: caught $e');
        expect(e, isNot(isA<TestFailure>()));
      }

      query = ref
          .where('text', isGreaterThanOrEqualTo: '07')
          .orderBy('text')
          .orderBy('text2')
          .startAfter(values: ['a']);
      try {
        // node: INVALID_ARGUMENT: order by clause cannot contain more fields after the key
        await query.get();
        fail('should fail');
      } catch (e) {
        // ignore: avoid_print
        print('invalid_query: caught $e');
        expect(e, isNot(isA<TestFailure>()));
      }
    });
  });
}
