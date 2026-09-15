import 'package:tekartik_firebase_firestore/firestore_logger.dart';
import 'package:tekartik_firebase_firestore/utils/firestore_mock.dart';
import 'package:test/test.dart';

class _FirestoreMockWithTransactionSupport extends FirestoreMock {
  _FirestoreMockWithTransactionSupport(this.supportsTransaction);

  @override
  final bool supportsTransaction;
}

class _FirestoreMockWithCollectionGroup extends FirestoreMock {
  final collectionGroupIds = <String>[];

  @override
  Query collectionGroup(String collectionId) {
    collectionGroupIds.add(collectionId);
    return collection(collectionId);
  }
}

void main() {
  group('firestore_logger', () {
    var firestore = FirestoreMock();

    var firestoreLogger = FirestoreLogger(
      firestore: firestore,
      options: FirestoreLoggerOptions.all(),
    );

    test('document', () {
      var doc1 = firestore.doc('test/doc');
      var doc2 = firestoreLogger.doc('test/doc');
      expect(doc1, doc2);
    });
    test('collection', () {
      var coll1 = firestore.collection('test');
      var coll2 = firestoreLogger.collection('test');
      expect(coll1, coll2);
    });
    test('collectionGroup', () async {
      var events = <FirestoreLoggerEvent>[];
      var firestore = _FirestoreMockWithCollectionGroup();
      var logger = FirestoreLogger(
        firestore: firestore,
        options: FirestoreLoggerOptions.all(log: events.add),
      );

      var query = logger.collectionGroup('group1');
      expect(firestore.collectionGroupIds, ['group1']);
      expect(query.firestore, same(logger));

      // Query events are logged (even on failure, the mock cannot execute
      // queries), for the group query and derived ones.
      await expectLater(query.get(), throwsA(anything));
      await expectLater(query.orderBy('name').get(), throwsA(anything));
      expect(events.map((e) => e.toString().split('\n').first), [
        'qry **/group1',
        'qry **/group1',
      ]);
    });
    test('supportsTransaction', () {
      for (var supported in [true, false]) {
        var logger = FirestoreLogger(
          firestore: _FirestoreMockWithTransactionSupport(supported),
          options: FirestoreLoggerOptions.all(),
        );
        expect(
          logger.supportsTransaction,
          supported,
          reason: 'delegate supportsTransaction: $supported',
        );
      }
    });
  });
}
