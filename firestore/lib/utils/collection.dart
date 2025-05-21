// Delete entire collection
// <https://firebase.google.com/docs/firestore/manage-data/delete-data#collections>
import 'dart:async';

import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/query.dart';

/// Prefer extension
/// Delete all items in a collection, return the count deleted
/// Keep ids in keepIds
Future<int> deleteCollection(
  Firestore firestore,
  CollectionReference collectionRef, {
  int? batchSize,
  Iterable<String>? keepIds,
}) async {
  return await collectionRef.delete(batchSize: batchSize, keepIds: keepIds);
}

/// Firestore extension
extension TekartikFirestoreCollectionReferenceExt on CollectionReference {
  /// Delete all items in a collection, return the count deleted
  /// Keep ids in keepIds
  Future<int> delete({int? batchSize, Iterable<String>? keepIds}) async {
    return await queryDelete(batchSize: batchSize, keepIds: keepIds);
  }

  /// Copy all items to a collection, return the count copied
  /// [clearExisting] means the destination collection will be cleared first
  Future<int> copyTo(
    CollectionReference dstCollectionRef, {
    int? batchSize,
    bool? clearExisting,
  }) async {
    return await _copyTo(
      dstCollectionRef,
      batchSize: batchSize,
      clearExisting: clearExisting,
    );
  }

  /// Copy all items to a collection, return the count copied
  /// [clearExisting] means the destination collection will be cleared first
  Future<int> _copyTo(
    CollectionReference dstCollectionRef, {
    int? batchSize,
    bool? clearExisting,
  }) async {
    var dstFirestore = dstCollectionRef.firestore;
    if (clearExisting ?? false) {
      // Clear the destination collection first
      await deleteCollection(dstFirestore, dstCollectionRef);
    }
    return await queryCopyTo(dstCollectionRef, batchSize: batchSize);
  }
}

/// Compat. (deprecated)
///
/// Prefer extension
/// Copy all items to a collection, return the count copied
/// [clearExisting] means the destination collection will be cleared first
Future<int> copyCollection(
  Firestore firestore,
  CollectionReference collectionRef,
  Firestore dstFirestore,
  CollectionReference dstCollectionRef, {
  int? batchSize,
}) async {
  return await collectionRef.copyTo(dstCollectionRef, batchSize: batchSize);
}
