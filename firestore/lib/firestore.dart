import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_firestore/src/firestore.dart';
import 'package:tekartik_firebase_firestore/src/timestamp.dart';
import 'package:tekartik_firebase_firestore/utils/firestore_mixin.dart';

export 'package:tekartik_firebase_firestore/src/firestore.dart'
    show FirestoreSettings, firestoreNameFieldPath;
export 'package:tekartik_firebase_firestore/src/timestamp.dart' show Timestamp;

abstract class FirestoreService {
  // True if query supporting selecting a set of fields
  bool get supportsQuerySelect;

  // Temporary flag
  bool get supportsFieldValueArray;
  // True if startAt/startAfter/endAt/endAfter can be used with snapshot
  bool get supportsQuerySnapshotCursor;

  bool get supportsDocumentSnapshotTime;

  /// Where it supports timestamp precision on date and time values in document data
  bool get supportsTimestamps;
  bool get supportsTimestampsInSnapshots;

  /// Return true if it supports tracking changes
  bool get supportsTrackChanges;

  Firestore firestore(App app);
}

/// Represents a Firestore Database and is the entry point for all
/// Firestore operations.
abstract class Firestore {
  /// Gets a [CollectionReference] for the specified Firestore path.
  CollectionReference collection(String path);

  /// Gets a [DocumentReference] for the specified Firestore path.
  DocumentReference doc(String path);

  /// Creates a write batch, used for performing multiple writes as a single
  /// atomic operation.
  WriteBatch? batch();

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
      FutureOr<T> Function(Transaction transaction) action);

  /// Specifies custom settings to be used to configure the `Firestore`
  /// instance.
  ///
  /// Can only be invoked once and before any other [Firestore] method.
  void settings(FirestoreSettings settings);

  /// Retrieves multiple documents from Firestore.
  Future<List<DocumentSnapshot>> getAll(List<DocumentReference> refs);
}

abstract class CollectionReference extends Query {
  String get path;

  String get id;

  DocumentReference? get parent;

  DocumentReference doc(String path);

  Future<DocumentReference> add(Map<String, Object?> data);
}

abstract class DocumentReference {
  String get id;

  String get path;

  CollectionReference? get parent;

  CollectionReference collection(String path);

  Future<void> delete();

  Future<DocumentSnapshot> get();

  Future<void> set(Map<String, Object?> data, [SetOptions? options]);

  Future<void> update(Map<String, Object?> data);

  Stream<DocumentSnapshot> onSnapshot();
}

abstract class DocumentData {
  factory DocumentData([Map<String, Object?>? map]) =>
      DocumentDataMap(map: map);

  void setString(String key, String value);

  String? getString(String key);

  void setNull(String key);

  void setFieldValue(String key, FieldValue value);

  void setInt(String key, int value);

  int? getInt(String key);

  void setNum(String key, num value);

  void setBool(String key, bool value);

  num? getNum(String key);

  bool? getBool(String key);

  void setDateTime(String key, DateTime value);

  DateTime? getDateTime(String key);

  void setTimestamp(String key, Timestamp value);

  Timestamp? getTimestamp(String key);

  void setList<T>(String key, List<T> list);

  List<T>? getList<T>(String key);

  DocumentData? getData(String key);

  void setData(String key, DocumentData value);

  // Return the native property
  dynamic getProperty(String key);

  // Set the native property
  void setProperty(String key, dynamic value);

  // Check the native property
  bool has(String key);

  // Return the key list
  Iterable<String> get keys;

  Map<String, Object?> asMap();

  // use hasProperty
  @deprecated
  bool containsKey(String key);

  // Document reference
  void setDocumentReference(String key, DocumentReference doc);

  // Document reference
  DocumentReference? getDocumentReference(String key);

  // blob
  void setBlob(String key, Blob blob);

  Blob? getBlob(String key);

  void setGeoPoint(String key, GeoPoint geoPoint);

  GeoPoint? getGeoPoint(String key);
}

/// A DocumentSnapshot contains data read from a document in your Cloud
/// Firestore database.
abstract class DocumentSnapshot {
  /// Gets the reference to the document.
  DocumentReference get ref;

  /// Returns the fields of the document as a Map.
  Map<String, Object?> get data;

  /// true if the document existed in this snapshot.
  bool get exists;

  /// The time the document was last updated (at the time the snapshot was
  /// generated). Not set for documents that don't exist.
  Timestamp? get updateTime;

  /// The time the document was created. Not set for documents that don't
  /// exist.
  Timestamp? get createTime;
}

/// Sentinel values for update/set
class FieldValue {
  dynamic get data => null;
  final FieldValueType type;

  /// Set the field as the current timestamp value.
  static final FieldValue serverTimestamp =
      FieldValue(FieldValueType.serverTimestamp);

  /// Delete the field.
  static final FieldValue delete = FieldValue(FieldValueType.delete);

  // Returns a sentinel value that can be used with set(merge: true) or update()
  // that tells the server to union the given elements with any array value that
  // already exists on the server. Each specified element that doesn't already
  // exist in the array will be added to the end. If the field being modified
  // is not already an array it will be overwritten with an array containing
  // exactly the specified elements.
  factory FieldValue.arrayUnion(List<Object?> data) {
    return FieldValueArray(FieldValueType.arrayUnion, data);
  }

  // Returns a sentinel value that can be used with set(merge: true) or
  // update() that tells
  // the server to remove the given elements from any array value that already
  // exists on the server. All instances of each element specified will be
  // removed from the array. If the field being modified is not already an array
  // it will be overwritten with an empty array.
  factory FieldValue.arrayRemove(List<Object?> data) {
    return FieldValueArray(FieldValueType.arrayRemove, data);
  }
  FieldValue(this.type);
  @override
  String toString() {
    return '$type${data != null ? '($data)' : ''}';
  }
}

/// Use UInt8Array as much as possible
class Blob {
  final Uint8List? _data;

  Blob.fromList(List<int> data) : _data = Uint8List.fromList(data);

  Uint8List? get data => _data;

  Blob(this._data);

  @override
  int get hashCode => (_data?.isNotEmpty == true) ? _data!.first.hashCode : 0;

  @override
  bool operator ==(other) {
    if (other is Blob) {
      return const ListEquality().equals(other.data, _data);
    }
    return false;
  }

  @override
  String toString() {
    return base64.encode(data!);
  }
}

class GeoPoint {
  final num? latitude;
  final num? longitude;

  GeoPoint(this.latitude, this.longitude);

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

class SetOptions {
  /// Set to true to replace only the values from the new data.
  /// Fields omitted will remain untouched.
  bool? merge;

  SetOptions({this.merge});
}

const String operatorEqual = '=';
const String operatorLessThan = '<';
const String operatorGreaterThan = '>';
const String operatorLessThanOrEqual = '<=';
const String operatorGreaterThanOrEqual = '>=';
const String operatorArrayContains = 'array-contains';

// compat 2019-10-24, fix mistake
@deprecated
const String opeatorArrayContains = operatorArrayContains;

const orderByAscending = 'asc';
const orderByDescending = 'desc';

abstract class WriteBatch {
  void delete(DocumentReference? ref);

  void set(DocumentReference ref, Map<String, Object?> data,
      [SetOptions? options]);

  void update(DocumentReference ref, Map<String, Object?> data);

  Future commit();
}

abstract class QuerySnapshot {
  List<DocumentSnapshot> get docs;

  /// An array of the documents that changed since the last snapshot. If this
  /// is the first snapshot, all documents will be in the list as Added changes.
  List<DocumentChange> get documentChanges;
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

/// A DocumentChange represents a change to the documents matching a query.
///
/// It contains the document affected and the type of change that occurred
/// (added, modified, or removed).
abstract class DocumentChange {
  /// The type of change that occurred (added, modified, or removed).
  ///
  /// Can be `null` if this document change was returned from [DocumentQuery.get].
  DocumentChangeType get type;

  /// The index of the changed document in the result set immediately prior to
  /// this [DocumentChange] (i.e. supposing that all prior DocumentChange objects
  /// have been applied).
  ///
  /// -1 for [DocumentChangeType.added] events.
  int get oldIndex;

  /// The index of the changed document in the result set immediately after this
  /// DocumentChange (i.e. supposing that all prior [DocumentChange] objects
  /// and the current [DocumentChange] object have been applied).
  ///
  /// -1 for [DocumentChangeType.removed] events.
  int get newIndex;

  /// The document affected by this change.
  DocumentSnapshot get document;
}

abstract class Query {
  Future<QuerySnapshot> get();

  Stream<QuerySnapshot> onSnapshot();

  Query limit(int limit);

  Query orderBy(String key, {bool? descending});

  Query select(List<String> keyPaths);

  // Query offset(int offset);

  Query startAt({DocumentSnapshot? snapshot, List<Object?>? values});

  Query startAfter({DocumentSnapshot? snapshot, List<Object?>? values});

  Query endAt({DocumentSnapshot? snapshot, List<Object?>? values});

  Query endBefore({DocumentSnapshot? snapshot, List<Object?>? values});

  Query where(
    String fieldPath, {
    dynamic isEqualTo,
    dynamic isLessThan,
    dynamic isLessThanOrEqualTo,
    dynamic isGreaterThan,
    dynamic isGreaterThanOrEqualTo,
    dynamic arrayContains,
    List<Object>? arrayContainsAny,
    List<Object>? whereIn,
    bool? isNull,
  });
}

// get must be done first
abstract class Transaction {
  /// Deletes the document referred to by the provided [DocumentReference].
  ///
  /// The [DocumentReference] parameter is a reference to the document to be
  /// deleted. Value must not be null.
  void delete(DocumentReference documentRef);

  /// Reads the document referenced by the provided [DocumentReference].
  ///
  /// The [DocumentReference] parameter is a reference to the document to be
  /// retrieved. Value must not be null.
  ///
  /// Returns non-null [Future] of the read data in a [DocumentSnapshot].
  Future<DocumentSnapshot> get(DocumentReference documentRef);

  /// Writes to the document referred to by the provided [DocumentReference].
  /// If the document does not exist yet, it will be created.
  /// If you pass [options], the provided data can be merged into the existing
  /// document.
  ///
  /// The [DocumentReference] parameter is a reference to the document to be
  /// created. Value must not be null.
  ///
  /// The [data] paramater is object of the fields and values for
  /// the document. Value must not be null.
  ///
  /// The optional [SetOptions] is an object to configure the set behavior.
  /// Pass [: {merge: true} :] to only replace the values specified in the
  /// data argument. Fields omitted will remain untouched.
  /// Value must not be null.
  void set(DocumentReference documentRef, Map<String, Object?> data,
      [SetOptions? options]);

  /// Updates fields in the document referred to by this [DocumentReference].
  /// The update will fail if applied to a document that does not exist.
  /// The value must not be null.
  ///
  /// Nested fields can be updated by providing dot-separated field path strings
  /// or by providing [FieldPath] objects.
  ///
  /// The [data] param is the object containing all of the fields and values
  /// to update.
  ///
  /// The [fieldsAndValues] param is the List alternating between fields
  /// (as String or [FieldPath] objects) and values.
  void update(DocumentReference documentRef, Map<String, Object?> data);
}
