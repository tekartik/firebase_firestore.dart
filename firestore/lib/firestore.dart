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
    show Timestamp, TekartikFirestoreTimestampExt;

export 'src/aggregate_field.dart' show AggregateField;
export 'src/aggregate_query.dart' show AggregateQuery;
export 'src/aggregate_query_snapshot.dart' show AggregateQuerySnapshot;
export 'src/document_reference.dart'
    show DocumentReference, DocumentReferenceListExtension;
export 'src/document_snapshot.dart' show DocumentSnapshot;
export 'src/firestore_logger.dart'
    show FirestoreLoggerDebugExt, FirestoreServiceLoggerDebugExt;
export 'src/query.dart' show Query;
export 'src/query_snapshot.dart' show QuerySnapshotExtension, QuerySnapshot;
export 'src/snapshot_meta_data.dart' show SnapshotMetadata;
export 'src/vector_value.dart' show VectorValue;

/// The entry point for accessing a Firestore.
///
/// You can get an instance by calling [Firestore.instance].
abstract class FirestoreService implements FirebaseAppProductService {
  /// Returns `true` if the implementation supports query select.
  ///
  /// When `false`, `select` is ignored.
  bool get supportsQuerySelect;

  /// Returns `true` if the implementation supports [FieldValue.arrayUnion] and
  /// [FieldValue.arrayRemove].
  bool get supportsFieldValueArray;

  /// Returns `true` if the implementation supports `startAtDocument`,
  /// `startAfterDocument`, `endAtDocument`, and `endBeforeDocument`.
  bool get supportsQuerySnapshotCursor;

  /// Returns `true` if the implementation supports [DocumentSnapshot.updateTime] and
  /// [DocumentSnapshot.createTime].
  bool get supportsDocumentSnapshotTime;

  /// Returns `true` if the implementation supports [Timestamp] in documents.
  bool get supportsTimestamps;

  /// Returns `true` if the implementation supports [Timestamp] in snapshots.
  bool get supportsTimestampsInSnapshots;

  /// Returns `true` if the implementation supports [VectorValue].
  bool get supportsVectorValue;

  /// Returns `true` if the implementation supports tracking changes.
  bool get supportsTrackChanges;

  /// Returns `true` if the implementation supports [Firestore.listCollections].
  bool get supportsListCollections;

  /// Returns `true` if the implementation supports aggregate queries.
  bool get supportsAggregateQueries;

  /// Returns a [Firestore] instance for the given [App].
  Firestore firestore(App app);
}

/// Represents a Firestore Database and is the entry point for all
/// Firestore operations.
abstract class Firestore implements FirebaseAppProduct<Firestore> {
  /// Gets a [CollectionReference] for the specified Firestore path.
  CollectionReference collection(String path);

  /// Gets a [Query] for the specified collection group.
  Query collectionGroup(String collectionId);

  /// Gets a [DocumentReference] for the specified Firestore path.
  DocumentReference doc(String path);

  /// Creates a write batch, used for performing multiple writes as a single
  /// atomic operation.
  WriteBatch batch();

  /// Executes the given [updateFunction] and commits the changes applied within
  /// the transaction.
  ///
  /// You can use the transaction object passed to [updateFunction] to read and
  /// modify Firestore documents under lock. Transactions are committed once
  /// [updateFunction] resolves and attempted up to five times on failure.
  ///
  /// Returns the same `Future` returned by [updateFunction] if transaction
  /// completed successfully of was explicitly aborted by returning a Future
  /// with an error. If [updateFunction] throws then returned Future completes
  /// with the same error.
  Future<T> runTransaction<T>(
    FutureOr<T> Function(Transaction transaction) action,
  );

  /// Specifies custom settings to be used to configure the `Firestore`
  /// instance.
  ///
  /// Can only be invoked once and before any other [Firestore] method.
  void settings(FirestoreSettings settings);

  /// Retrieves multiple documents from Firestore.
  Future<List<DocumentSnapshot>> getAll(List<DocumentReference> refs);

  /// If supported list all root collections
  Future<List<CollectionReference>> listCollections();

  /// The [FirestoreService] for this instance.
  FirestoreService get service;

  /// The default [Firestore] instance.
  static Firestore get instance =>
      (FirebaseApp.instance as FirebaseAppMixin).getProduct<Firestore>()!;
}

/// Represents firestore document data.
abstract class DocumentData {
  /// Creates a new [DocumentData] object.
  factory DocumentData([Map<String, Object?>? map]) =>
      DocumentDataMap(map: map);

  /// Sets the value for the given [key] to a [String].
  void setString(String key, String value);

  /// Returns the value for the given [key] as a [String].
  String? getString(String key);

  /// Sets the value for the given [key] to `null`.
  void setNull(String key);

  /// Sets the value for the given [key] to a [FieldValue].
  void setFieldValue(String key, FieldValue value);

  /// Sets the value for the given [key] to an [int].
  void setInt(String key, int value);

  /// Returns the value for the given [key] as an [int].
  int? getInt(String key);

  /// Sets the value for the given [key] to a [num].
  void setNum(String key, num value);

  /// Sets the value for the given [key] to a [bool].
  void setBool(String key, bool value);

  /// Returns the value for the given [key] as a [num].
  num? getNum(String key);

  /// Returns the value for the given [key] as a [bool].
  bool? getBool(String key);

  /// Sets the value for the given [key] to a [DateTime].
  void setDateTime(String key, DateTime value);

  /// Returns the value for the given [key] as a [DateTime].
  DateTime? getDateTime(String key);

  /// Sets the value for the given [key] to a [Timestamp].
  void setTimestamp(String key, Timestamp value);

  /// Returns the value for the given [key] as a [Timestamp].
  Timestamp? getTimestamp(String key);

  /// Sets the value for the given [key] to a [List].
  void setList<T>(String key, List<T> list);

  /// Returns the value for the given [key] as a [List].
  List<T>? getList<T>(String key);

  /// Returns the value for the given [key] as a [DocumentData].
  DocumentData? getData(String key);

  /// Sets the value for the given [key] to a [DocumentData].
  void setData(String key, DocumentData value);

  /// Returns the native property for the given [key].
  dynamic getProperty(String key);

  /// Sets the native property for the given [key].
  void setProperty(String key, dynamic value);

  /// Returns `true` if the document contains the given [key].
  bool has(String key);

  /// Returns an `Iterable` of all keys in the document.
  Iterable<String> get keys;

  /// Returns the document as a `Map<String, Object?>`.
  Map<String, Object?> asMap();

  /// use hasProperty
  @Deprecated('Use hasProperty')
  bool containsKey(String key);

  /// Sets the value for the given [key] to a [DocumentReference].
  void setDocumentReference(String key, DocumentReference doc);

  /// Returns the value for the given [key] as a [DocumentReference].
  DocumentReference? getDocumentReference(String key);

  /// Sets the value for the given [key] to a [Blob].
  void setBlob(String key, Blob blob);

  /// Returns the value for the given [key] as a [Blob].
  Blob? getBlob(String key);

  /// Sets the value for the given [key] to a [GeoPoint].
  void setGeoPoint(String key, GeoPoint geoPoint);

  /// Returns the value for the given [key] as a [GeoPoint].
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
class FieldValue {
  /// The data associated with the `FieldValue`.
  Object? get data => null;

  /// The type of the `FieldValue`.
  final FieldValueType type;

  /// Returns a sentinel that resolves to the server's timestamp.
  static final FieldValue serverTimestamp = FieldValue(
    FieldValueType.serverTimestamp,
  );

  /// Returns a sentinel for use with update() to mark a field for deletion.
  static final FieldValue delete = FieldValue(FieldValueType.delete);

  /// Returns a sentinel value that can be used with set(merge: true) or update()
  /// that tells the server to union the given elements with any array value that
  /// already exists on the server. Each specified element that doesn't already
  /// exist in the array will be added to the end. If the field being modified
  /// is not already an array it will be overwritten with an array containing
  /// exactly the specified elements.
  factory FieldValue.arrayUnion(List<Object?> data) {
    return FieldValueArray(FieldValueType.arrayUnion, data);
  }

  /// Returns a sentinel value that can be used with set(merge: true) or
  /// update() that tells
  /// the server to remove the given elements from any array value that already
  /// exists on the server. All instances of each element specified will be
  /// removed from the array. If the field being modified is not already an array
  /// it will be overwritten with an empty array.
  factory FieldValue.arrayRemove(List<Object?> data) {
    return FieldValueArray(FieldValueType.arrayRemove, data);
  }

  /// Creates a new [FieldValue].
  FieldValue(this.type);

  @override
  String toString() {
    return '$type${data != null ? '($data)' : ''}';
  }
}

/// A blob of bytes.
class Blob {
  final Uint8List _data;

  /// Creates a new [Blob] from a `List<int>`.
  Blob.fromList(List<int> data) : _data = asUint8List(data);

  /// The bytes of the blob.
  Uint8List get bytes => _data;

  /// The bytes of the blob.
  Uint8List get data => _data;

  /// Creates a new [Blob] from a `Uint8List`.
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

/// An options object that configures the behavior of `set()` calls.
class SetOptions {
  /// Changes the behavior of a `set()` call to only replace the values specified
  /// in the data argument.
  ///
  /// Fields omitted from the data argument remain untouched.
  bool? merge;

  /// Creates a new [SetOptions] object.
  SetOptions({this.merge});
}

/// The relational operator for query comparisons.
const String operatorEqual = '=';

/// The relational operator for query comparisons.
const String operatorLessThan = '<';

/// The relational operator for query comparisons.
const String operatorGreaterThan = '>';

/// The relational operator for query comparisons.
const String operatorLessThanOrEqual = '<=';

/// The relational operator for query comparisons.
const String operatorGreaterThanOrEqual = '>=';

/// The relational operator for query comparisons.
const String operatorArrayContains = 'array-contains';

/// The relational operator for query comparisons.
const String operatorArrayContainsAny = 'array-contains-any';

/// The relational operator for query comparisons.
const String operatorIn = 'in';

/// The relational operator for query comparisons.
const String operatorNotIn = 'not-in';

/// compat 2019-10-24, fix mistake
@Deprecated('Typo use operatorArrayContains')
const String opeatorArrayContains = operatorArrayContains;

/// The direction of a query's sort order.
const orderByAscending = 'asc';

/// The direction of a query's sort order.
const orderByDescending = 'desc';

/// A write batch, used to perform multiple writes as a single atomic unit.
///
/// A [WriteBatch] object can be acquired by calling [Firestore.batch]. It
/// provides methods for adding writes to the write batch. None of the writes
/// will be committed (or visible locally) until [WriteBatch.commit] is called.
abstract class WriteBatch {
  /// Deletes the document referred to by the provided [DocumentReference].
  void delete(DocumentReference ref);

  /// Writes to the document referred to by the provided [DocumentReference].
  ///
  /// If the document does not yet exist, it will be created. If you pass
  /// [SetOptions], the provided data can be merged into an existing document.
  void set(
    DocumentReference ref,
    Map<String, Object?> data, [
    SetOptions? options,
  ]);

  /// Updates fields in the document referred to by the provided
  /// [DocumentReference].
  ///
  /// The update will fail if applied to a document that does not exist.
  void update(DocumentReference ref, Map<String, Object?> data);

  /// Commits all of the writes in this write batch as a single atomic unit.
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

/// A `DocumentChange` represents a change to the documents matching a query.
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

/// A transaction, used for atomic multi-document writes.
///
/// A [Transaction] object can be used to read and write multiple documents
/// atomically.
abstract class Transaction {
  /// Deletes the document referred to by the provided [DocumentReference].
  void delete(DocumentReference documentRef);

  /// Reads the document referenced by the provided [DocumentReference].
  Future<DocumentSnapshot> get(DocumentReference documentRef);

  /// Writes to the document referred to by the provided [DocumentReference].
  ///
  /// If the document does not exist yet, it will be created. If you pass
  /// [SetOptions], the provided data can be merged into an existing document.
  void set(
    DocumentReference documentRef,
    Map<String, Object?> data, [
    SetOptions? options,
  ]);

  /// Updates fields in the document referred to by this [DocumentReference].
  ///
  /// The update will fail if applied to a document that does not exist.
  void update(DocumentReference documentRef, Map<String, Object?> data);
}
