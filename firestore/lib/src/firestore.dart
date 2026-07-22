import 'package:tekartik_firebase_firestore/src/common/import_firestore_mixin.dart';

// don't export it yet
/// Identifies which sentinel behavior a [FieldValue] represents.
enum FieldValueType {
  /// The field is replaced by the server's commit timestamp. See
  /// [FieldValue.serverTimestamp].
  serverTimestamp,

  /// The field is removed from the document. See [FieldValue.delete].
  delete,

  /// Elements are added to an existing array field. See
  /// [FieldValue.arrayUnion].
  arrayUnion,

  /// Elements are removed from an existing array field. See
  /// [FieldValue.arrayRemove].
  arrayRemove,
}

/// Converts [value] to local time if it is a UTC [DateTime]; returns [value]
/// unchanged otherwise (including when it is `null`).
DateTime? toLocaleTime(DateTime? value) {
  if (value == null || !value.isUtc) {
    return value;
  }
  return value.toLocal();
}

/// Parses [value] as a [DateTime].
///
/// Accepts a [DateTime] (returned as-is), or any value accepted by
/// [parseTimestamp] (converted through [Timestamp.toDateTime]). Returns
/// `null` if [value] cannot be interpreted as a date/time.
DateTime? parseDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  } else {
    return parseTimestamp(value)?.toDateTime();
  }
}

/// Parses [value] as a [Timestamp].
///
/// Accepts a [Timestamp] (returned as-is), a [DateTime] (converted through
/// [Timestamp.fromDateTime]), or a [String] parsed with [Timestamp.tryParse].
/// Returns `null` for any other type, or if a [String] value cannot be
/// parsed.
Timestamp? parseTimestamp(dynamic value) {
  if (value is Timestamp) {
    return value;
  } else if (value is DateTime) {
    return Timestamp.fromDateTime(value);
  } else if (value is String) {
    final text = value;
    return Timestamp.tryParse(text);
  }
  return null;
}

/// Converts [value] to a value suitable to be stored as (or nested within) a
/// Firestore document field.
///
/// Passes through `null`, [num], [bool], [String], [DateTime] and
/// [FieldValue] unchanged, recurses into [Iterable]s (returning a [List])
/// and [Map]s. Throws an [ArgumentError] for any other, unsupported value
/// type.
dynamic valueToDocumentValue(dynamic value) {
  if (value == null ||
      value is num ||
      value is bool ||
      value is String ||
      value is DateTime ||
      value is FieldValue) {
    return value;
  } else if (value is Iterable) {
    return value.map((item) => valueToDocumentValue(value)).toList();
  } else if (value is Map) {
    return value
        .map((key, value) => MapEntry(key, valueToDocumentValue(value)))
        .cast<String, Object?>();
  } else {
    throw ArgumentError.value(
      value,
      '${value.runtimeType}',
      'Unsupported value for fieldValueFromJsonValue',
    );
  }
}

/// Implementation of [DocumentData] backed by a plain
/// `Map<String, Object?>`.
class DocumentDataMap implements DocumentData {
  /// The backing map holding this document's field values.
  Map<String, Object?> get map => _map;
  late Map<String, Object?> _map;

  // use the given map as the data holder (so will be modified)
  /// Creates a new [DocumentDataMap].
  ///
  /// When [map] is provided it becomes the backing store (and will be
  /// mutated by subsequent writes); when omitted, a new empty map is used.
  DocumentDataMap({Map<String, Object?>? map}) {
    _map = map ?? {};
  }

  @override
  // Regular map
  Map<String, Object?> asMap() => map;

  @override
  String? getString(String key) => getValue(key) as String?;

  @override
  void setNull(String key) => setValue(key, null);

  /// Sets the raw, untyped [value] for the given [key] directly on the
  /// backing map, without any type coercion.
  void setValue(String key, dynamic value) => map[key] = value;

  /// Returns the value found by walking [fieldPath] (dot-separated nested
  /// keys) from the root of this document's data, or `null` if any
  /// intermediate segment is missing or not a map.
  Object? valueAtFieldPath(String fieldPath) {
    final parts = fieldPath.split('.');
    Map parent = map;
    Object? value;
    for (var i = 0; i < parts.length; i++) {
      var part = parts[i];
      value = parent[part];
      if (value is Map) {
        parent = value;
      } else if (i < parts.length - 1) {
        // end not reached, abort
        return null;
      }
    }
    return value;
  }

  /// Returns the raw, untyped value stored for the top-level [key], without
  /// any type coercion.
  dynamic getValue(String key) => map[key];

  @override
  void setString(String key, String value) => setValue(key, value);

  @override
  bool containsKey(String key) => _map.containsKey(key);

  @override
  void setFieldValue(String key, FieldValue value) => setValue(key, value);

  @override
  void setInt(String key, int value) => setValue(key, value);

  @override
  int? getInt(String key) => getValue(key) as int?;

  @override
  bool? getBool(String key) => getValue(key) as bool?;

  @override
  num? getNum(String key) => getValue(key) as num?;

  @override
  void setBool(String key, bool value) => setValue(key, value);

  @override
  void setNum(String key, num value) => setValue(key, value);

  @override
  DateTime? getDateTime(String key) =>
      toLocaleTime(parseDateTime(getValue(key)));

  @override
  void setDateTime(String key, DateTime value) => setValue(key, value);

  @override
  DocumentData? getData(String key) {
    var value = getValue(key);
    if (value is Map) {
      return DocumentDataMap()..map.addAll(value.cast<String, Object?>());
    }
    return null;
  }

  @override
  void setData(String key, DocumentData? value) =>
      setValue(key, (value as DocumentDataMap).map);

  @override
  dynamic getProperty(String key) => getValue(key);

  @override
  bool has(String key) => containsKey(key);

  @override
  Iterable<String> get keys => map.keys;

  @override
  void setProperty(String key, value) {
    setValue(key, valueToDocumentValue(value));
  }

  @override
  List<T>? getList<T>(String key) => (getValue(key) as List?)?.cast<T>();

  @override
  void setList<T>(String key, List<T> list) => setValue(key, list);

  @override
  DocumentReference? getDocumentReference(String key) =>
      getValue(key) as DocumentReference?;

  @override
  void setDocumentReference(String key, DocumentReference? doc) =>
      setValue(key, doc);

  @override
  Blob? getBlob(String key) => getValue(key) as Blob?;

  @override
  void setBlob(String key, Blob? blob) {
    setValue(key, blob);
  }

  @override
  GeoPoint? getGeoPoint(String key) => getValue(key) as GeoPoint?;

  @override
  void setGeoPoint(String key, GeoPoint? geoPoint) {
    setValue(key, geoPoint);
  }

  @override
  Timestamp? getTimestamp(String key) {
    return parseTimestamp(getValue(key));
  }

  @override
  void setTimestamp(String key, Timestamp? value) {
    setValue(key, value);
  }

  @override
  String toString() => asMap().toString();
}

/// Sentinel kinds mirroring [FieldValueType.delete] and
/// [FieldValueType.serverTimestamp] for map-based encodings.
enum FieldValueMapValue {
  /// Mirrors [FieldValueType.delete].
  delete,

  /// Mirrors [FieldValueType.serverTimestamp].
  serverTimestamp,
}

/// Special field name representing the document id, usable as the
/// [Query.orderBy] key (or in a `where` filter) to sort/filter by document
/// id rather than by a data field.
const String firestoreNameFieldPath = '__name__';

/// Custom settings used to configure a [Firestore] instance through
/// [Firestore.settings].
class FirestoreSettings {
  /// Enables the use of `Timestamp`s for timestamp fields in
  /// `DocumentSnapshot`s.
  @Deprecated('No longer needed')
  final bool? timestampsInSnapshots;

  /// Creates a new [FirestoreSettings], optionally passing
  /// [timestampsInSnapshots] (deprecated, no longer needed).
  // ignore: deprecated_member_use_from_same_package
  FirestoreSettings({
    @Deprecated('No longer needed') this.timestampsInSnapshots,
  });

  @override
  String toString() {
    // ignore: deprecated_member_use_from_same_package
    var map = {'timestampsInSnapshots': timestampsInSnapshots};
    return map.toString();
  }
}
