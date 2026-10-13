// Delete entire collection
// <https://firebase.google.com/docs/firestore/manage-data/delete-data#collections>

import 'dart:math';

import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/firestore_mixin.dart'
    show HasQueryInfo;

/// Returns -1 to abort (existing count, 0 or more is returned)
typedef TekartikFirestoreQueryActionFunction =
    Future<int> Function(List<String> ids);

/// Query extension
extension TekartikFirestoreQueryExt on Query {
  /// Delete all items in a query, return the count deleted
  Future<int> queryDelete({
    int? batchSize,
    Iterable<String>? keepIds,

    /// Needed
    int? limit,
  }) async {
    return await _delete(batchSize: batchSize, keepIds: keepIds, limit: limit);
  }

  /// Delete all item in a query, return the count deleted
  /// Batch size default to 10
  /// Keep doc with paths in keepPaths
  Future<int> _delete({
    int? batchSize,
    Iterable<String>? keepIds,
    required int? limit,
  }) async {
    var stepSize = batchSize ?? 10;
    var count = 0;

    var maxRemainingCount = limit;

    var keptIds = keepIds?.toSet() ?? <String>{};
    var deletedIds = <String>{};
    var query = this;
    while (true) {
      if (maxRemainingCount != null) {
        stepSize = min(stepSize, maxRemainingCount);
        if (stepSize <= 0) {
          break;
        }
      }

      // The kept documents can be returned again, get enough documents to
      // have a full batch to delete (the kept ones cannot fill the page).
      var pageSize = stepSize + keptIds.length;
      var snapshot = await query.limit(pageSize).get();

      var refsToDelete = <DocumentReference>[];
      var remainingCount = 0;
      for (var doc in snapshot.docs) {
        var id = doc.ref.id;
        if (keptIds.contains(id) || deletedIds.contains(id)) {
          continue;
        }
        remainingCount++;
        if (refsToDelete.length < stepSize) {
          refsToDelete.add(doc.ref);
        }
      }

      // When there are no documents left to delete, we are done
      if (refsToDelete.isEmpty) {
        break;
      }

      // Delete documents in a batch
      var batch = firestore.batch();
      for (var ref in refsToDelete) {
        batch.delete(ref);
      }
      await batch.commit();

      var idsToDelete = refsToDelete.ids;
      deletedIds.addAll(idsToDelete);
      var docCount = idsToDelete.length;
      count += docCount;
      if (maxRemainingCount != null) {
        maxRemainingCount -= docCount;
      }

      // Not a full page and everything deleted, we are done.
      if (snapshot.docs.length < pageSize && remainingCount == docCount) {
        break;
      }
    }

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
    // The existing order by fields (needed to start after the last document)
    // if known.
    var queryInfo = this is HasQueryInfo
        ? (this as HasQueryInfo).queryInfo
        : null;
    var orderByFields = <String>[
      if (queryInfo != null)
        for (var orderBy in queryInfo.orderBys)
          if (orderBy.fieldPath != firestoreNameFieldPath) orderBy.fieldPath!,
    ];
    var useSnapshotCursor =
        queryInfo == null && firestore.service.supportsQuerySnapshotCursor;
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

      var lastDoc = snapshot.docs.last;
      if (useSnapshotCursor) {
        // Unknown order by, the snapshot gives the values.
        query = query.startAfter(snapshot: lastDoc);
      } else {
        // Like queryAction, the existing order by values come first.
        query = query.startAfter(
          values: [
            for (var field in orderByFields) lastDoc.data[field],
            lastDoc.ref.id,
          ],
        );
      }
    } while (snapshotSize >= batchSize);

    return count;
  }

  /// action all item in a query
  Future<int> queryAction({
    int? batchSize,
    int? limit,

    /// Needed if there is an existing order
    List<String>? orderByFields,
    required TekartikFirestoreQueryActionFunction actionFunction,
  }) {
    return _queryAction(
      batchSize: batchSize,
      limit: limit,
      actionFunction: actionFunction,
      orderByFields: orderByFields,
    );
  }

  /// Prefer extension
  /// action all item in a query
  /// name sorting is added
  Future<int> _queryAction({
    int? batchSize,
    // Needed override query limit
    int? limit,

    /// Needed to know orderBy and append ours
    List<String>? orderByFields,

    required TekartikFirestoreQueryActionFunction actionFunction,
  }) async {
    var query = orderBy(firestoreNameFieldPath);
    var stepSize = batchSize ?? 10;
    var count = 0;

    var maxRemainingCount = limit;

    var doneIds = <String>{};
    int snapshotSize;
    do {
      if (maxRemainingCount != null) {
        stepSize = min(stepSize, maxRemainingCount);
        if (stepSize <= 0) {
          break;
        }
      }
      var snapshot = await query.limit(stepSize).get();
      snapshotSize = snapshot.docs.length;

      // When there are no documents left, we are done
      if (snapshotSize == 0) {
        break;
      }
      var idsToProcess = snapshot.docs.map((doc) => doc.ref.id).where((id) {
        return !doneIds.contains(id);
      }).toList();

      var processCount = await actionFunction(idsToProcess);
      // Return -1 to abort
      if (processCount < 0) {
        // Abort
        break;
      }
      count += processCount;
      if (maxRemainingCount != null) {
        maxRemainingCount -= processCount;
      }

      var lastDoc = snapshot.docs.last;
      query = query.startAfter(
        values: [
          if (orderByFields != null)
            for (var field in orderByFields) lastDoc.data[field],
          lastDoc.ref.id,
        ],
      );
    } while (snapshotSize >= stepSize);

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
  int? limit, // Needed for now as existing limit is overriden
  Iterable<String>? keepPaths,
  Iterable<String>? keepIds,
}) async {
  return await query.queryDelete(
    batchSize: batchSize,
    keepIds: (keepIds != null)
        ? keepIds
        : keepPaths?.map((path) => firestorePathGetId(path)),
    limit: limit,
  );
}
