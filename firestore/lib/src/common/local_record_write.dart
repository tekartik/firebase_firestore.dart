// Write helpers shared by the local implementations (sembast, idb, sdb).
//
// Not exported, the implementations import it directly.
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/map_utils.dart';
import 'package:tekartik_firebase_firestore/src/common/time_mixin.dart';
import 'package:tekartik_firebase_firestore/src/firestore_common.dart';
import 'package:tekartik_firebase_firestore/src/record_data.dart';
import 'package:tekartik_firebase_firestore/utils/firestore_mixin.dart'
    show FirestoreDocumentsMixin;

import '../../firestore.dart';

export 'package:tekartik_firebase_firestore/src/firestore_common.dart'
    show WriteBatchOperation;

/// Exception thrown by the local implementations.
class FirestoreExceptionLocal extends FirestoreException {
  /// Constructor.
  FirestoreExceptionLocal(super.code, super.message);
}

/// Error of an update of the missing document at [path].
FirestoreException localUpdateNotFoundException(String path) =>
    FirestoreExceptionLocal(
      FirestoreErrorCode.notFound,
      'No document to update: $path',
    );

/// Sets the revision (incremented), the create time (kept) and the update
/// time (now) of [recordMap] written over [existing] (`null` if none).
void _setRecordMapMeta(
  Map<String, Object?> recordMap,
  Map<String, Object?>? existing,
) {
  var now = Timestamp.now();
  recordMap[revKey] =
      (existing == null ? 0 : (recordMapRev(existing) ?? 0)) + 1;
  recordMap[createTimeKey] =
      (existing == null ? now : recordMapCreateTime(existing)!)
          .toIso8601String();
  recordMap[updateTimeKey] = now.toIso8601String();
}

/// The record map stored by a set of [documentData] over [existing], the
/// current record map (`null` if the document does not exist).
///
/// A merge is done on the decoded data so that a map replaces a typed value
/// (Timestamp, reference...) as on Firestore.
Map<String, Object?> localRecordMapSet(
  Firestore firestore,
  Map<String, Object?>? existing,
  DocumentData documentData,
  SetOptions? options,
) {
  Map<String, Object?> recordMap;
  if (options?.merge == true) {
    DocumentData newDocumentData;
    if (existing != null) {
      newDocumentData = DocumentData(
        cloneMap(
          documentDataFromRecordMap(firestore, existing)!.asMap(),
        ).cast<String, Object?>(),
      );
    } else {
      newDocumentData = DocumentData();
    }
    newDocumentData.merge(documentData);
    recordMap = newDocumentData.toJsonRecordValueMap();
  } else {
    recordMap = documentData.toJsonRecordValueMap();
  }
  _setRecordMapMeta(recordMap, existing);
  return recordMap;
}

/// The record map stored by an update of [documentData] (field paths) over
/// [existing], the current record map.
///
/// It is done on the stored record so that the other values (Timestamp,
/// reference...) are kept as is.
Map<String, Object?> localRecordMapUpdate(
  Map<String, Object?> existing,
  DocumentData documentData,
) {
  var recordMap = recordMapUpdate(existing, documentData)!;
  _setRecordMapMeta(recordMap, existing);
  return recordMap;
}

/// A write computed by [localComputeWrites].
class LocalRecordWrite<R extends WriteResultBase> {
  /// Document path.
  final String path;

  /// The record map to store, `null` to delete the document.
  final Map<String, Object?>? recordMap;

  /// The result to notify once written.
  final R result;

  /// Constructor.
  LocalRecordWrite(this.path, this.recordMap, this.result);
}

/// Computes the writes of [operations] (set, update, delete) in order, the
/// current records being read with [read], each operation seeing the
/// previous ones.
///
/// Nothing is written so that a failing operation (update of a missing
/// document) leaves the database untouched.
Future<List<LocalRecordWrite<R>>> localComputeWrites<R extends WriteResultBase>(
  FirestoreDocumentsMixin firestore,
  Iterable<WriteBatchOperation> operations,
  Future<Map<String, Object?>?> Function(String path) read,
  R Function(String path) newResult,
) async {
  var pending = <String, Map<String, Object?>?>{};
  var writes = <LocalRecordWrite<R>>[];
  for (var operation in operations) {
    var ref = (operation as WriteBatchOperationBase).docRef!;
    var path = ref.path;
    var existing = pending.containsKey(path) ? pending[path] : await read(path);
    var result = newResult(path);
    result.previousSnapshot = firestore.documentFromRecordMap(ref, existing);
    Map<String, Object?>? recordMap;
    if (operation is WriteBatchOperationDelete) {
      recordMap = null;
    } else if (operation is WriteBatchOperationSet) {
      recordMap = localRecordMapSet(
        firestore,
        existing,
        operation.documentData,
        operation.options,
      );
    } else if (operation is WriteBatchOperationUpdate) {
      if (existing == null) {
        throw localUpdateNotFoundException(path);
      }
      recordMap = localRecordMapUpdate(existing, operation.documentData);
    } else {
      throw UnsupportedError('not supported $operation');
    }
    if (recordMap != null) {
      result.newSnapshot = firestore.documentFromRecordMap(ref, recordMap);
    }
    pending[path] = recordMap;
    writes.add(LocalRecordWrite<R>(path, recordMap, result));
  }
  return writes;
}

/// Computes the writes of [operations] (see [localComputeWrites]) then
/// writes them in order with [write] (a `null` record map deletes the
/// document) and returns their results.
Future<List<R>> localCommitWrites<R extends WriteResultBase>(
  FirestoreDocumentsMixin firestore,
  Iterable<WriteBatchOperation> operations, {
  required Future<Map<String, Object?>?> Function(String path) read,
  required Future<void> Function(String path, Map<String, Object?>? recordMap)
  write,
  required R Function(String path) newResult,
}) async {
  var writes = await localComputeWrites(firestore, operations, read, newResult);
  for (var recordWrite in writes) {
    await write(recordWrite.path, recordWrite.recordMap);
  }
  return writes.map((recordWrite) => recordWrite.result).toList();
}
