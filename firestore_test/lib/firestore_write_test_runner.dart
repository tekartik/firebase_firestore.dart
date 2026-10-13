import 'dart:typed_data';

import 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';

import 'firestore_test_runner.dart';

/// Write tests (update, merge, transaction and batch atomicity).
void firestoreWriteTestGroup({
  required FirestoreService service,
  required Firestore firestore,
  required FirestoreTestContext? testContext,
}) {
  CollectionReference getCollection(String name) => firestore.collection(
    url.join(
      FirestoreTestContext.getRootCollectionPath(testContext),
      'write_test',
      name,
    ),
  );

  Future<void> expectFails(Future<void> Function() action) async {
    try {
      await action();
      fail('should fail');
    } catch (e) {
      expect(e, isNot(isA<TestFailure>()));
    }
  }

  group('write', () {
    test('update keeps the typed values', () async {
      var ref = getCollection('update').doc('typed_values');
      var data = <String, Object?>{
        'ref': firestore.doc('test/doc'),
        'geo': const GeoPoint(1, 2),
        'list': [firestore.doc('test/doc')],
        'value': 1,
        if (service.supportsTimestamps) ...{
          'timestamp': Timestamp(1, 2000000),
          'nested': {'timestamp': Timestamp(2, 0)},
        },
        if (service.supportsBlobs) 'blob': Blob(Uint8List.fromList([1, 2, 3])),
      };
      await ref.set(data);
      await ref.update({'value': 2});
      await runTestAndIfNeededAllowDelay(testContext, () async {
        expect((await ref.get()).data, {...data, 'value': 2});
      });
    });

    test('update time', () async {
      var ref = getCollection('update').doc('time');
      await ref.set({'value': 1});
      var snapshot1 = await ref.get();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await ref.update({'value': 2});
      await runTestAndIfNeededAllowDelay(testContext, () async {
        var snapshot2 = await ref.get();
        expect(snapshot2.data, {'value': 2});
        expect(snapshot2.createTime, snapshot1.createTime);
        expect(
          snapshot2.updateTime!.compareTo(snapshot1.updateTime!),
          greaterThan(0),
        );
      });
    }, skip: !service.supportsDocumentSnapshotTime);

    test('update missing document', () async {
      var ref = getCollection('update').doc('missing');
      await ref.delete();
      await expectFails(() => ref.update({'value': 1}));
      expect((await ref.get()).exists, isFalse);
    });

    test('update dotted array union and remove', () async {
      var ref = getCollection('update').doc('dotted_array');
      await ref.set({
        'map': {
          'union': [1, 2],
          'remove': [1, 2],
          'other': 1,
        },
      });
      await ref.update({
        'map.union': FieldValue.arrayUnion([2, 3]),
        'map.remove': FieldValue.arrayRemove([1]),
      });
      await runTestAndIfNeededAllowDelay(testContext, () async {
        expect((await ref.get()).data, {
          'map': {
            'union': [1, 2, 3],
            'remove': [2],
            'other': 1,
          },
        });
      });
    }, skip: !service.supportsFieldValueArray);

    test('merge a map onto a typed value', () async {
      var ref = getCollection('merge').doc('onto_typed_value');
      await ref.set({
        'ref': firestore.doc('test/doc'),
        if (service.supportsTimestamps) 'timestamp': Timestamp(1, 2000000),
      });
      await ref.set({
        'ref': {'sub': 1},
        if (service.supportsTimestamps) 'timestamp': {'sub': 2},
      }, SetOptions(merge: true));
      await runTestAndIfNeededAllowDelay(testContext, () async {
        expect((await ref.get()).data, {
          'ref': {'sub': 1},
          if (service.supportsTimestamps) 'timestamp': {'sub': 2},
        });
      });
    });

    test('batch is atomic', () async {
      var collRef = getCollection('batch_atomic');
      var setRef = collRef.doc('set');
      var missingRef = collRef.doc('missing');
      await setRef.delete();
      await missingRef.delete();
      var batch = firestore.batch();
      batch.set(setRef, {'value': 1});
      batch.update(missingRef, {'value': 1});
      await expectFails(() => batch.commit());
      expect((await setRef.get()).exists, isFalse);
      expect((await missingRef.get()).exists, isFalse);
    });

    group('transaction', () {
      test('throw rolls back', () async {
        var ref = getCollection('transaction').doc('throw_rolls_back');
        await ref.set({'value': 1});
        await expectFails(
          () => firestore.runTransaction((txn) async {
            await txn.get(ref);
            txn.set(ref, {'value': 2});
            throw StateError('rollback');
          }),
        );
        expect((await ref.get()).data, {'value': 1});
      });

      test('update missing document fails', () async {
        var collRef = getCollection('transaction_update_missing');
        var setRef = collRef.doc('set');
        var missingRef = collRef.doc('missing');
        await setRef.delete();
        await missingRef.delete();
        await expectFails(
          () => firestore.runTransaction((txn) async {
            await txn.get(setRef);
            txn.set(setRef, {'value': 1});
            txn.update(missingRef, {'value': 1});
          }),
        );
        expect((await setRef.get()).exists, isFalse);
        expect((await missingRef.get()).exists, isFalse);
      });
    }, skip: skipFirestoreTransactionTests || !firestore.supportsTransaction);
  });
}
