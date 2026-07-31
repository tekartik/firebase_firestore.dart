import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:tekartik_common_utils/byte_utils.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_firestore/src/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/firestore_mixin.dart';

import 'firestore.dart';

export 'package:tekartik_firebase/firebase.dart';
export 'package:tekartik_firebase_firestore/src/collection_reference.dart'
    show CollectionReference;
export 'package:tekartik_firebase_firestore/src/firestore.dart'
    show FirestoreSettings, firestoreNameFieldPath;
export 'package:tekartik_firebase_firestore/src/firestore_path.dart'
    show
        firestorePathGetParent,
        firestoreCollPathGetParent,
        firestoreDocPathGetParent,
        firestorePathGetChild,
        firestorePathGetGenericPath,
        firestorePathReplaceId,
        firestorePathGetId;
export 'package:tekartik_firebase_firestore/src/timestamp.dart'
    show
        Timestamp,
        FirestoreTimestamp,
        TekartikFirestoreTimestamp,
        TekartikFirestoreTimestampExt;

export 'src/aggregate_field.dart' show AggregateField;
export 'src/aggregate_query.dart' show AggregateQuery;
export 'src/aggregate_query_snapshot.dart' show AggregateQuerySnapshot;
export 'src/document_reference.dart'
    show DocumentReference, DocumentReferenceListExtension;
export 'src/document_snapshot.dart' show DocumentSnapshot;
export 'src/firestore_exception.dart'
    show FirestoreErrorCode, FirestoreException;
export 'src/firestore_logger.dart'
    show FirestoreLoggerDebugExt, FirestoreServiceLoggerDebugExt;
export 'src/query.dart' show Query;
export 'src/query_snapshot.dart' show QuerySnapshotExtension, QuerySnapshot;
export 'src/snapshot_meta_data.dart' show SnapshotMetadata;
export 'src/vector_value.dart' show VectorValue;
export 'utils/run_transaction_support.dart';

/// The entry point for accessing a Firestore backend implementation
/// (REST, Node.js, Flutter native, in-memory mock, ...).
///
/// A [FirestoreService] is registered once per [App] and exposes both the
/// factory method used to obtain a [Firestore] instance for that app and a
/// set of `supportsXxx` capability flags. Since this package targets several
/// backends with different feature sets, callers should check the relevant
/// flag before relying on a feature that is not part of the common core API
/// (for example before using [FieldValue.arrayUnion] or before reading
/// [DocumentSnapshot.updateTime]).
///
/// You can get an instance by calling [Firestore.instance] then
/// [Firestore.service], or through the underlying [App]/[FirebaseAppProduct]
/// wiring.
abstract class FirestoreService implements FirebaseAppProductService {
  /// `true` if the implementation supports [Query.select] to restrict the
  /// fields returned by a query.
  ///
  /// When `false`, calling [Query.select] has no effect and the full
  /// document is returned.
  bool get supportsQuerySelect;

  /// `true` if the implementation supports [FieldValue.arrayUnion] and
  /// [FieldValue.arrayRemove] as values passed to `set`/`update`.
  bool get supportsFieldValueArray;

  /// `true` if the implementation supports cursor-based pagination using a
  /// [DocumentSnapshot], i.e. the `snapshot` parameter of [Query.startAt],
  /// [Query.startAfter], [Query.endAt] and [Query.endBefore].
  bool get supportsQuerySnapshotCursor;

  /// `true` if the implementation populates [DocumentSnapshot.updateTime] and
  /// [DocumentSnapshot.createTime].
  ///
  /// When `false`, those getters return `null`.
  bool get supportsDocumentSnapshotTime;

  /// `true` if the implementation supports storing and reading [Timestamp]
  /// values in document fields (as opposed to only [DateTime]).
  bool get supportsTimestamps;

  /// `true` if the implementation supports storing and reading [Blob] values
  /// in document fields.
  bool get supportsBlobs;

  /// `true` if the implementation returns [Timestamp] instances (rather than
  /// [DateTime]) for date/time fields found in [DocumentSnapshot.data].
  bool get supportsTimestampsInSnapshots;

  /// `true` if the implementation supports storing and reading [VectorValue]
  /// values in document fields.
  bool get supportsVectorValue;

  /// `true` if the implementation supports tracking changes, both for a
  /// single document ([supportsRecordTrackChanges]) and for queries.
  bool get supportsTrackChanges;

  /// `true` if the implementation supports tracking changes for a single
  /// document read/write.
  bool get supportsRecordTrackChanges;

  /// `true` if the implementation supports [Firestore.listCollections] (and
  /// [DocumentReference.listCollections]).
  ///
  /// When `false`, calling those methods throws.
  bool get supportsListCollections;

  /// `true` if the implementation supports aggregate queries created through
  /// [Query.aggregate] (count, sum, average).
  bool get supportsAggregateQueries;

  /// Returns the [Firestore] instance bound to [app], creating and caching
  /// it on first call.
  ///
  /// Subsequent calls with the same [app] return the same instance.
  Firestore firestore(App app);
}

/// Represents a Firestore Database and is the entry point for all
/// Firestore operations.
abstract class Firestore implements FirebaseAppProduct<Firestore> {
  /// Gets a [CollectionReference] for the specified Firestore [path].
  ///
  /// [path] must point to a collection, i.e. it must have an odd number of
  /// `/`-separated segments (for example `'users'` or `'users/123/posts'`).
  /// The reference is returned even if no document currently has that
  /// collection; no network or storage access is performed by this call.
  CollectionReference collection(String path);

  /// Gets a [Query] over all collections (at any depth) whose id equals
  /// [collectionId], commonly known as a collection group query.
  ///
  /// [collectionId] is the last segment of the collections to match, not a
  /// full path. Not all implementations support collection group queries;
  /// see [FirestoreService] documentation for the concrete backend.
  Query collectionGroup(String collectionId);

  /// Gets a [DocumentReference] for the specified Firestore [path].
  ///
  /// [path] must point to a document, i.e. it must have an even number of
  /// `/`-separated segments (for example `'users/123'`). The reference is
  /// returned even if no document currently exists at that path; no network
  /// or storage access is performed by this call.
  DocumentReference doc(String path);

  /// Creates a write batch, used for performing multiple writes as a single
  /// atomic operation.
  ///
  /// Writes queued through [WriteBatch.set], [WriteBatch.update] and
  /// [WriteBatch.delete] are staged locally and only applied once
  /// [WriteBatch.commit] is called.
  WriteBatch batch();

  /// Executes the given [action] and commits the changes applied within
  /// the transaction.
  ///
  /// You can use the [Transaction] object passed to [action] to read and
  /// modify Firestore documents under lock. Transactions are committed once
  /// [action] resolves and are retried (attempted up to five times) if the
  /// commit fails, for example because a document read by the transaction was
  /// concurrently modified.
  ///
  /// Returns the same value as the `Future`/value returned by [action] if the
  /// transaction completed successfully. If [action] throws, or if the
  /// returned `Future` completes with an error, the transaction is aborted
  /// and the returned `Future` completes with the same error.
  Future<T> runTransaction<T>(
    FutureOr<T> Function(Transaction transaction) action,
  );

  /// Specifies custom [settings] to be used to configure this [Firestore]
  /// instance.
  ///
  /// Can only be invoked once and before any other [Firestore] method.
  /// Most implementations throw a [StateError] if called more than once.
  void settings(FirestoreSettings settings);

  /// Retrieves multiple documents from Firestore in one call.
  ///
  /// [refs] is the list of [DocumentReference]s to fetch; it may be empty, in
  /// which case an empty list is returned. The returned list has the same
  /// length and order as [refs]; each [DocumentSnapshot] has
  /// [DocumentSnapshot.exists] set to `false` when the corresponding
  /// document does not exist.
  Future<List<DocumentSnapshot>> getAll(List<DocumentReference> refs);

  /// Lists all root collections, if supported by the backend.
  ///
  /// Returns an empty list if there are no root collections. Check
  /// [FirestoreService.supportsListCollections] before calling this method;
  /// implementations that don't support it throw.
  Future<List<CollectionReference>> listCollections();

  /// The [FirestoreService] that created this [Firestore] instance, used to
  /// query backend capabilities (`supportsXxx` flags) or to obtain other
  /// [Firestore] instances.
  FirestoreService get service;

  /// The default [Firestore] instance, bound to the default [FirebaseApp].
  ///
  /// Throws if no Firestore product was registered for the default app.
  static Firestore get instance =>
      (FirebaseApp.instance as FirebaseAppMixin).getProduct<Firestore>()!;

  /// Some service might have different behavior depending on the login used
  /// in rest email/login password does not support transaction
  bool get supportsTransaction;
}

/// A typed, mutable view over Firestore document data (a `Map<String, Object?>`
/// under the hood), used to build the payload passed to `set`/`update` or
/// returned while building a [DocumentSnapshot].
///
/// All `getXxx`/`setXxx` typed accessors operate on top-level fields only; use
/// [getData]/[setData] to work with nested maps. Every getter returns `null`
/// (rather than throwing) when [key] is absent or holds a value that does not
/// match the requested type.
abstract class DocumentData {
  /// Creates a new [DocumentData], optionally initialized from [map].
  ///
  /// When [map] is provided it becomes the backing store: further reads and
  /// writes on the returned [DocumentData] operate on (and can mutate) that
  /// same map. When omitted, a new empty map is used.
  factory DocumentData([Map<String, Object?>? map]) =>
      DocumentDataMap(map: map);

  /// Sets the value for the given [key] to the [String] [value].
  void setString(String key, String value);

  /// Returns the value for the given [key] as a [String], or `null` if the
  /// key is absent or not a [String].
  String? getString(String key);

  /// Sets the value for the given [key] to `null`.
  void setNull(String key);

  /// Sets the value for the given [key] to the sentinel [value], for example
  /// [FieldValue.serverTimestamp] or [FieldValue.delete].
  void setFieldValue(String key, FieldValue value);

  /// Sets the value for the given [key] to the [int] [value].
  void setInt(String key, int value);

  /// Returns the value for the given [key] as an [int], or `null` if the key
  /// is absent or not an [int].
  int? getInt(String key);

  /// Sets the value for the given [key] to the [num] [value].
  void setNum(String key, num value);

  /// Sets the value for the given [key] to the [bool] [value].
  void setBool(String key, bool value);

  /// Returns the value for the given [key] as a [num], or `null` if the key
  /// is absent or not a [num].
  num? getNum(String key);

  /// Returns the value for the given [key] as a [bool], or `null` if the key
  /// is absent or not a [bool].
  bool? getBool(String key);

  /// Sets the value for the given [key] to the [DateTime] [value].
  void setDateTime(String key, DateTime value);

  /// Returns the value for the given [key] as a [DateTime], or `null` if the
  /// key is absent or does not hold a date/time value. The value is
  /// converted to local time.
  DateTime? getDateTime(String key);

  /// Sets the value for the given [key] to the [Timestamp] [value].
  void setTimestamp(String key, Timestamp value);

  /// Returns the value for the given [key] as a [Timestamp], or `null` if the
  /// key is absent or does not hold a date/time value.
  Timestamp? getTimestamp(String key);

  /// Sets the value for the given [key] to the [list].
  void setList<T>(String key, List<T> list);

  /// Returns the value for the given [key] as a `List<T>`, or `null` if the
  /// key is absent or not a [List].
  List<T>? getList<T>(String key);

  /// Returns the value for the given [key] as a nested [DocumentData], or
  /// `null` if the key is absent or not a map.
  DocumentData? getData(String key);

  /// Sets the value for the given [key] to the nested [DocumentData] [value].
  void setData(String key, DocumentData value);

  /// Returns the raw, untyped value stored for the given [key], or `null` if
  /// absent.
  dynamic getProperty(String key);

  /// Sets the raw, untyped [value] for the given [key].
  ///
  /// The [value] is converted through the same coercion used for `set`/
  /// `update` payloads; unsupported types throw an [ArgumentError].
  void setProperty(String key, dynamic value);

  /// Returns `true` if the document data contains the given [key], even if
  /// its value is `null`.
  bool has(String key);

  /// The top-level field names present in this document data.
  Iterable<String> get keys;

  /// Returns this document data as a `Map<String, Object?>`.
  ///
  /// Some implementations return the live backing map (mutations to it are
  /// reflected in this [DocumentData]); others return a copy. Do not rely on
  /// either behavior.
  Map<String, Object?> asMap();

  /// Use [has] instead.
  @Deprecated('Use hasProperty')
  bool containsKey(String key);

  /// Sets the value for the given [key] to the [DocumentReference] [doc].
  void setDocumentReference(String key, DocumentReference doc);

  /// Returns the value for the given [key] as a [DocumentReference], or
  /// `null` if the key is absent or not a document reference.
  DocumentReference? getDocumentReference(String key);

  /// Sets the value for the given [key] to the [Blob] [blob].
  void setBlob(String key, Blob blob);

  /// Returns the value for the given [key] as a [Blob], or `null` if the key
  /// is absent or not a [Blob].
  Blob? getBlob(String key);

  /// Sets the value for the given [key] to the [GeoPoint] [geoPoint].
  void setGeoPoint(String key, GeoPoint geoPoint);

  /// Returns the value for the given [key] as a [GeoPoint], or `null` if the
  /// key is absent or not a [GeoPoint].
  GeoPoint? getGeoPoint(String key);
}

/// An extension on [DocumentSnapshot] to provide helper methods.
extension DocumentSnapshotExt on DocumentSnapshot {
  /// Returns the document's data as a `Map<String, Object?>`, or `null` if the
  /// document does not exist.
  Map<String, Object?>? get dataOrNull => exists ? data : null;
}

/// Sentinel values that can be used when writing document fields with `set` or
/// `update`.
///
/// Assign one of these (via [serverTimestamp], [delete], [arrayUnion] or
/// [arrayRemove]) as the value of a field instead of a regular value; the
/// backend replaces it with the described behavior instead of storing it
/// literally.
class FieldValue {
  /// The payload associated with this [FieldValue], if any (for example the
  /// elements passed to [arrayUnion]/[arrayRemove]). `null` for sentinels
  /// that don't carry data, such as [serverTimestamp] and [delete].
  Object? get data => null;

  /// Identifies which sentinel behavior this [FieldValue] represents.
  final FieldValueType type;

  /// A sentinel that tells the server to replace the field with the
  /// timestamp at which the write is committed on the server.
  static final FieldValue serverTimestamp = FieldValue(
    FieldValueType.serverTimestamp,
  );

  /// A sentinel for use with `update()` (or `set()` with merge) to mark a
  /// field for deletion from the document.
  static final FieldValue delete = FieldValue(FieldValueType.delete);

  /// A sentinel value that can be used with `set(merge: true)` or `update()`
  /// that tells the server to union [data] with any array value that
  /// already exists for the field on the server.
  ///
  /// Each element of [data] that doesn't already exist in the array is added
  /// to the end. If the field being modified is not already an array it is
  /// overwritten with an array containing exactly the elements of [data].
  /// Check [FirestoreService.supportsFieldValueArray] before use.
  factory FieldValue.arrayUnion(List<Object?> data) {
    return FieldValueArray(FieldValueType.arrayUnion, data);
  }

  /// A sentinel value that can be used with `set(merge: true)` or `update()`
  /// that tells the server to remove [data] from any array value that
  /// already exists for the field on the server.
  ///
  /// All instances of each element of [data] are removed from the array. If
  /// the field being modified is not already an array it is overwritten with
  /// an empty array. Check [FirestoreService.supportsFieldValueArray] before
  /// use.
  factory FieldValue.arrayRemove(List<Object?> data) {
    return FieldValueArray(FieldValueType.arrayRemove, data);
  }

  /// Creates a new [FieldValue] sentinel of the given [type].
  ///
  /// Prefer the named constructors/statics ([serverTimestamp], [delete],
  /// [arrayUnion], [arrayRemove]) over calling this directly.
  FieldValue(this.type);

  @override
  String toString() {
    return '$type${data != null ? '($data)' : ''}';
  }
}

/// A blob of raw bytes that can be stored in a document field.
///
/// Check [FirestoreService.supportsBlobs] before relying on this type being
/// preserved by a given backend.
class Blob {
  final Uint8List _data;

  /// Creates a new [Blob] from the given [data], copying it into a
  /// [Uint8List] if it isn't one already.
  Blob.fromList(List<int> data) : _data = asUint8List(data);

  /// The bytes of the blob. Same value as [data].
  Uint8List get bytes => _data;

  /// The bytes of the blob. Same value as [bytes].
  Uint8List get data => _data;

  /// Creates a new [Blob] wrapping the given [Uint8List] bytes.
  Blob(this._data);

  @override
  int get hashCode => (_data.isNotEmpty) ? _data.first.hashCode : 0;

  @override
  bool operator ==(other) {
    if (other is Blob) {
      return const ListEquality<int>().equals(other.data, _data);
    }
    return false;
  }

  @override
  String toString() {
    return base64.encode(data);
  }
}

/// A geographical point represented by latitude and longitude.
class GeoPoint {
  /// The latitude of this `GeoPoint`.
  final num latitude;

  /// The longitude of this `GeoPoint`.
  final num longitude;

  /// Creates a new [GeoPoint] with the given [latitude] and [longitude].
  const GeoPoint(this.latitude, this.longitude);

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is GeoPoint) {
      final point = other;
      return latitude == point.latitude && longitude == point.longitude;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => latitude.hashCode * 17 + longitude.hashCode;

  @override
  String toString() => '[$latitude° N, $longitude° E]';
}

/// An options object that configures the behavior of `set()` calls, passed to
/// [DocumentReference.set], [WriteBatch.set] and [Transaction.set].
class SetOptions {
  /// When `true`, changes the behavior of a `set()` call to only replace the
  /// values specified in the data argument, leaving fields omitted from the
  /// data argument untouched instead of overwriting the whole document.
  ///
  /// When `false` or `null` (the default), `set()` overwrites the entire
  /// document, removing any field not present in the data argument.
  bool? merge;

  /// Creates a new [SetOptions] object. Pass [merge] to `true` to merge the
  /// written fields into the existing document instead of replacing it.
  SetOptions({this.merge});
}

/// The `=` relational operator, used to build query filters for equality
/// comparisons.
const String operatorEqual = '=';

/// The `<` relational operator, used to build query filters for
/// less-than comparisons.
const String operatorLessThan = '<';

/// The `>` relational operator, used to build query filters for
/// greater-than comparisons.
const String operatorGreaterThan = '>';

/// The `<=` relational operator, used to build query filters for
/// less-than-or-equal comparisons.
const String operatorLessThanOrEqual = '<=';

/// The `>=` relational operator, used to build query filters for
/// greater-than-or-equal comparisons.
const String operatorGreaterThanOrEqual = '>=';

/// The `array-contains` relational operator, used to build query filters
/// that match documents whose array field contains a given value.
const String operatorArrayContains = 'array-contains';

/// The `array-contains-any` relational operator, used to build query filters
/// that match documents whose array field contains at least one of a given
/// set of values.
const String operatorArrayContainsAny = 'array-contains-any';

/// The `in` relational operator, used to build query filters that match
/// documents whose field equals one of a given set of values.
const String operatorIn = 'in';

/// The `not-in` relational operator, used to build query filters that match
/// documents whose field does not equal any of a given set of values.
const String operatorNotIn = 'not-in';

/// compat 2019-10-24, fix mistake
@Deprecated('Typo use operatorArrayContains')
const String opeatorArrayContains = operatorArrayContains;

/// The ascending direction of a query's sort order, as used by
/// [Query.orderBy].
const orderByAscending = 'asc';

/// The descending direction of a query's sort order, as used by
/// [Query.orderBy].
const orderByDescending = 'desc';

/// A write batch, used to perform multiple writes as a single atomic unit.
///
/// A [WriteBatch] object can be acquired by calling [Firestore.batch]. It
/// provides methods for adding writes to the write batch. None of the writes
/// will be committed (or visible locally) until [WriteBatch.commit] is called.
abstract class WriteBatch {
  /// Queues the deletion of the document referred to by [ref].
  ///
  /// The delete is only applied once [commit] is called.
  void delete(DocumentReference ref);

  /// Queues writing [data] to the document referred to by [ref].
  ///
  /// If the document does not yet exist, it will be created. If [options]
  /// is passed with [SetOptions.merge] set to `true`, [data] is merged into
  /// the existing document instead of replacing it. The write is only
  /// applied once [commit] is called.
  void set(
    DocumentReference ref,
    Map<String, Object?> data, [
    SetOptions? options,
  ]);

  /// Queues updating fields in the document referred to by [ref] with
  /// [data].
  ///
  /// The update is only applied once [commit] is called, and fails at commit
  /// time if applied to a document that does not exist.
  void update(DocumentReference ref, Map<String, Object?> data);

  /// Commits all of the writes queued in this write batch as a single atomic
  /// unit.
  ///
  /// The returned `Future` completes once the batch has been committed, or
  /// with an error if the commit failed (in which case none of the queued
  /// writes are applied).
  Future<void> commit();
}

/// An enumeration of document change types.
enum DocumentChangeType {
  /// Indicates a new document was added to the set of documents matching the
  /// query.
  added,

  /// Indicates a document within the query was modified.
  modified,

  /// Indicates a document within the query was removed (either deleted or no
  /// longer matches the query).
  removed,
}

/// A `DocumentChange` represents a change to the documents matching a query,
/// as reported in [QuerySnapshot.documentChanges].
///
/// It contains the document affected and the type of change that occurred
/// (added, modified, or removed).
abstract class DocumentChange {
  /// The type of change that occurred (added, modified, or removed).
  DocumentChangeType get type;

  /// The index of the changed document in the result set immediately prior to
  /// this `DocumentChange` (i.e. supposing that all prior `DocumentChange` objects
  /// have been applied).
  ///
  /// -1 for [DocumentChangeType.added] events.
  int get oldIndex;

  /// The index of the changed document in the result set immediately after this
  /// `DocumentChange` (i.e. supposing that all prior `DocumentChange` objects
  /// and the current `DocumentChange` object have been applied).
  ///
  /// -1 for [DocumentChangeType.removed] events.
  int get newIndex;

  /// The document affected by this change.
  DocumentSnapshot get document;
}

/// A transaction, used for atomic multi-document reads and writes.
///
/// A [Transaction] object is passed to the callback given to
/// [Firestore.runTransaction] and can be used to read and write multiple
/// documents atomically: either all of its operations are applied, or none
/// are (in which case the whole action may be retried).
abstract class Transaction {
  /// Queues the deletion of the document referred to by [documentRef].
  ///
  /// The delete is only applied when the enclosing transaction commits.
  void delete(DocumentReference documentRef);

  /// Reads the document referenced by [documentRef] within this transaction.
  ///
  /// The returned `Future` completes with the document's [DocumentSnapshot],
  /// which has [DocumentSnapshot.exists] set to `false` if the document does
  /// not exist. All reads in a transaction must be performed before any
  /// writes; most implementations throw if this order is violated.
  Future<DocumentSnapshot> get(DocumentReference documentRef);

  /// Queues writing [data] to the document referred to by [documentRef].
  ///
  /// If the document does not exist yet, it will be created. If [options]
  /// is passed with [SetOptions.merge] set to `true`, [data] is merged into
  /// the existing document instead of replacing it. The write is only
  /// applied when the enclosing transaction commits.
  void set(
    DocumentReference documentRef,
    Map<String, Object?> data, [
    SetOptions? options,
  ]);

  /// Queues updating fields in the document referred to by [documentRef]
  /// with [data].
  ///
  /// The update is only applied when the enclosing transaction commits, and
  /// fails at commit time if applied to a document that does not exist.
  void update(DocumentReference documentRef, Map<String, Object?> data);
}

/// Firebase helper extension exposing the [Firestore] product for a
/// [FirebaseApp].
extension TekartikFirestoreFirebaseAppExt on FirebaseApp {
  /// Returns the [Firestore] product instance registered for this app.
  ///
  /// Throws a [StateError] if no Firestore product was registered for this
  /// app (typically because the Firestore plugin was never initialized).
  Firestore firestore() {
    var firestore = getProduct<Firestore>();
    if (firestore == null) {
      throw StateError('No firestore product for app $name');
    } else {
      return firestore;
    }
  }
}
