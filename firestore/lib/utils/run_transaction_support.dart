import 'dart:async';

import 'package:meta/meta.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';

/// Fallback [Transaction] implementation using a [WriteBatch] for writes
/// and direct document reference calls for reads.
class WriteBatchTransaction implements Transaction {
  /// The backing write batch.
  final WriteBatch writeBatch;

  /// Creates a [WriteBatchTransaction] wrapping [writeBatch].
  WriteBatchTransaction(this.writeBatch);

  @override
  void delete(DocumentReference documentRef) {
    writeBatch.delete(documentRef);
  }

  @override
  Future<DocumentSnapshot> get(DocumentReference documentRef) {
    return documentRef.get();
  }

  @override
  void set(
    DocumentReference documentRef,
    Map<String, Object?> data, [
    SetOptions? options,
  ]) {
    writeBatch.set(documentRef, data, options);
  }

  @override
  void update(DocumentReference documentRef, Map<String, Object?> data) {
    writeBatch.update(documentRef, data);
  }
}

/// Helper function to run operations using a [WriteBatchTransaction] directly,
/// without using a native transaction.
Future<T> _firestoreRunNoTransaction<T>(
  Firestore firestore,
  FutureOr<T> Function(Transaction transaction) action,
) async {
  var batch = firestore.batch();
  var transaction = WriteBatchTransaction(batch);
  var result = await action(transaction);
  await batch.commit();
  return result;
}

/// Helper function to run a transaction if supported, or fall back to [WriteBatchTransaction]
/// when transactions are not supported by the backend.
Future<T> _firestoreRunTransactionSupport<T>(
  Firestore firestore,
  FutureOr<T> Function(Transaction transaction) action,
) async {
  if (firestore.supportsTransaction) {
    return await firestore.runTransaction(action);
  } else {
    return await _firestoreRunNoTransaction(firestore, action);
  }
}

/// Extension on [Firestore] adding [runTransactionSupport] and [runNoTransaction].
extension TekartikFirestoreRunTransactionSupportExt on Firestore {
  /// Runs a transaction using [runTransaction] if [supportsTransaction] is `true`,
  /// or falls back to using a [WriteBatch] and direct document reads when `false`.
  Future<T> runTransactionSupport<T>(
    FutureOr<T> Function(Transaction transaction) action,
  ) {
    return _firestoreRunTransactionSupport(this, action);
  }

  /// Runs operations using [WriteBatchTransaction] directly without a native transaction.
  @visibleForTesting
  Future<T> runNoTransaction<T>(
    FutureOr<T> Function(Transaction transaction) action,
  ) {
    return _firestoreRunNoTransaction(this, action);
  }
}
