// Delete entire collection
// <https://firebase.google.com/docs/firestore/manage-data/delete-data#collections>

import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';

/// Query extension
extension TekartikFirestoreQueryExt on Query {
  /// Delete all items in a query, return the count deleted
  Future<int> queryDelete({int? batchSize, Iterable<String>? keepIds}) async {
    return await _delete(batchSize: batchSize, keepIds: keepIds);
  }

  /// Delete all item in a query, return the count deleted
  /// Batch size default to 10
  /// Keep doc with paths in keepPaths
  Future<int> _delete({int? batchSize, Iterable<String>? keepIds}) async {
    batchSize ??= 10;
    var count = 0;
    var deletedIds = <String>{};
    if (keepIds != null) {
      deletedIds.addAll(keepIds);
    }
    int snapshotSize;
    do {
      var snapshot = await limit(batchSize).get();
      snapshotSize = snapshot.docs.length;

      // When there are no documents left, we are done
      if (snapshotSize == 0) {
        break;
      }

      // Delete documents in a batch
      var batch = firestore.batch();
      for (var doc in snapshot.docs) {
        var ref = doc.ref;
        var id = ref.id;
        if (deletedIds.contains(id)) {
          //devPrint('already deleted $path');
          continue;
        }
        deletedIds.add(id);
        //devPrint('deleting $path');
        batch.delete(ref);
      }

      await batch.commit();
      count += snapshot.docs.length;
    } while (snapshotSize >= batchSize);

    return count;
  }

  /// Copy all items to a collection, return the count copied
  Future<int> queryCopyTo(
    CollectionReference dstCollectionRef, {
    int? batchSize,
  }) async {
    return await _copyTo(dstCollectionRef, batchSize: batchSize);
  }

  /// Prefer extension
  /// Copy all items to a collection, return the count copied
  /// [clearExisting] means the destination collection will be cleared first
  Future<int> _copyTo(
    CollectionReference dstCollectionRef, {
    int? batchSize,
  }) async {
    var query = orderBy(firestoreNameFieldPath);
    batchSize ??= 10;
    var count = 0;

    int snapshotSize;
    do {
      var snapshot = await query.limit(batchSize).get();
      snapshotSize = snapshot.docs.length;

      // When there are no documents left, we are done
      if (snapshotSize == 0) {
        break;
      }

      // Delete documents in a batch
      var dstFirestore = dstCollectionRef.firestore;
      var batch = dstFirestore.batch();
      for (var doc in snapshot.docs) {
        batch.set(dstCollectionRef.doc(doc.ref.id), doc.data);
      }

      await batch.commit();
      count += snapshot.docs.length;

      query = query.startAfter(values: [snapshot.docs.last.ref.id]);
    } while (snapshotSize >= batchSize);

    return count;
  }
}

/// Compat. (deprecated)
///
/// Delete all item in a query, return the count deleted
/// Batch size default to 10
/// Keep doc with paths in keepPaths
Future<int> deleteQuery(
  Firestore firestore,
  Query query, {
  int? batchSize,
  Iterable<String>? keepPaths,
}) async {
  return await query.queryDelete(
    batchSize: batchSize,
    keepIds: keepPaths?.map((path) => firestorePathGetId(path)),
  );
}
