import 'package:tekartik_firebase_firestore/src/common/import_firestore_mixin.dart';

// don't export it yet
enum FieldValueType { serverTimestamp, delete, arrayUnion, arrayRemove }

DateTime? toLocaleTime(DateTime? value) {
  if (value == null || !value.isUtc) {
    return value;
  }
  return value.toLocal();
}

/// Parse a date time from a dynamic value
DateTime? parseDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  } else {
    return parseTimestamp(value)?.toDateTime();
  }
}

/// Parse a timestamp from a dynamic value
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

/// Convert a dynamic value to a document value
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

/// IMplementation of [DocumentData] using a map
class DocumentDataMap implements DocumentData {
  Map<String, Object?> get map => _map;
  late Map<String, Object?> _map;

  // use the given map as the data holder (so will be modified)
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

  void setValue(String key, dynamic value) => map[key] = value;

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

enum FieldValueMapValue { delete, serverTimestamp }

/// Special name field representing the document id (for sort order)
const String firestoreNameFieldPath = '__name__';

class FirestoreSettings {
  /// Enables the use of `Timestamp`s for timestamp fields in
  /// `DocumentSnapshot`s.
  @Deprecated('No longer needed')
  final bool? timestampsInSnapshots;

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
