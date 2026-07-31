import 'dart:async';

import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/firestore_mock.dart';
import 'package:test/test.dart';

class _MockFirestoreSupported extends FirestoreMock {
  bool runTransactionCalled = false;

  @override
  bool get supportsTransaction => true;

  @override
  Future<T> runTransaction<T>(
    FutureOr<T> Function(Transaction transaction) updateFunction,
  ) async {
    runTransactionCalled = true;
    var mockTxn = _MockTransaction();
    return await updateFunction(mockTxn);
  }
}

class _MockFirestoreSupportedWithBatch extends _MockFirestoreSupported {
  final _MockWriteBatch mockBatch = _MockWriteBatch();

  @override
  WriteBatch batch() => mockBatch;
}

class _MockFirestoreUnsupported extends FirestoreMock {
  final _MockWriteBatch mockBatch = _MockWriteBatch();

  @override
  bool get supportsTransaction => false;

  @override
  WriteBatch batch() => mockBatch;
}

class _MockWriteBatch implements WriteBatch {
  bool committed = false;
  final List<String> operations = [];

  @override
  Future<void> commit() async {
    committed = true;
  }

  @override
  void delete(DocumentReference ref) {
    operations.add('delete ${ref.path}');
  }

  @override
  void set(
    DocumentReference ref,
    Map<String, Object?> data, [
    SetOptions? options,
  ]) {
    operations.add('set ${ref.path} $data');
  }

  @override
  void update(DocumentReference ref, Map<String, Object?> data) {
    operations.add('update ${ref.path} $data');
  }
}

class _MockTransaction implements Transaction {
  @override
  void delete(DocumentReference documentRef) {}

  @override
  Future<DocumentSnapshot> get(DocumentReference documentRef) {
    throw UnimplementedError();
  }

  @override
  void set(
    DocumentReference documentRef,
    Map<String, Object?> data, [
    SetOptions? options,
  ]) {}

  @override
  void update(DocumentReference documentRef, Map<String, Object?> data) {}
}

class _MockDocumentReference extends DocumentReferenceMock {
  final Map<String, Object?>? mockData;

  _MockDocumentReference(super.firestoreMock, super.path, {this.mockData});

  @override
  Future<DocumentSnapshot> get() async {
    return _MockDocumentSnapshot(this, mockData: mockData, mockExists: true);
  }
}

class _MockDocumentSnapshot extends DocumentSnapshotMock {
  final Map<String, Object?>? mockData;
  final bool mockExists;

  _MockDocumentSnapshot(super.ref, {this.mockData, required this.mockExists});

  @override
  Map<String, Object?> get data => mockData ?? {};

  @override
  bool get exists => mockExists;
}

void main() {
  group('runTransactionSupport', () {
    test('supported transaction', () async {
      var firestore = _MockFirestoreSupported();
      var executed = false;

      var result = await firestore.runTransactionSupport((txn) async {
        executed = true;
        return 'success';
      });

      expect(firestore.runTransactionCalled, isTrue);
      expect(executed, isTrue);
      expect(result, 'success');
    });

    test('unsupported transaction success fallback', () async {
      var firestore = _MockFirestoreUnsupported();
      var docRef = _MockDocumentReference(
        firestore,
        'test/doc1',
        mockData: {'count': 5},
      );

      var result = await firestore.runTransactionSupport((txn) async {
        var snapshot = await txn.get(docRef);
        expect(snapshot.data['count'], 5);

        txn.set(docRef, {'count': 6});
        txn.update(docRef, {'updated': true});
        txn.delete(_MockDocumentReference(firestore, 'test/doc2'));
        return 42;
      });

      expect(result, 42);
      expect(firestore.mockBatch.committed, isTrue);
      expect(firestore.mockBatch.operations, [
        'set test/doc1 {count: 6}',
        'update test/doc1 {updated: true}',
        'delete test/doc2',
      ]);
    });

    test('unsupported transaction error aborts batch commit', () async {
      var firestore = _MockFirestoreUnsupported();

      try {
        await firestore.runTransactionSupport((txn) async {
          txn.set(_MockDocumentReference(firestore, 'test/doc1'), {'a': 1});
          throw const FormatException('failed transaction');
        });
      } catch (e) {
        expect(e, isA<FormatException>());
      }

      expect(firestore.mockBatch.committed, isFalse);
    });

    test('runNoTransaction on supported firestore uses WriteBatch', () async {
      var firestore = _MockFirestoreSupportedWithBatch();
      var executed = false;

      var result = await firestore.runNoTransaction((txn) async {
        executed = true;
        txn.set(_MockDocumentReference(firestore, 'test/doc1'), {'a': 1});
        return 'no_txn';
      });

      expect(firestore.runTransactionCalled, isFalse);
      expect(executed, isTrue);
      expect(result, 'no_txn');
      expect(firestore.mockBatch.committed, isTrue);
    });
  });
}
