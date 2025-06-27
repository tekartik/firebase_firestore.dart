import 'package:cv/cv.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/map_utils.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/time_mixin.dart';
import 'package:tekartik_firebase_firestore/src/common/value_key_mixin.dart';
import 'package:tekartik_firebase_firestore/src/firestore.dart';

import 'firestore_common.dart';

const revKey = r'$rev';

int? recordMapRev(Map<String, Object?> recordMap) => recordMap[revKey] as int?;

Timestamp? recordMapUpdateTime(Map<String, Object?> recordMap) =>
    mapUpdateTime(recordMap);

Timestamp? recordMapCreateTime(Map<String, Object?> recordMap) =>
    mapCreateTime(recordMap);

/// Merge documentData onto existing recordMap
Map<String, Object?>? recordMapMerge(
  Map<String, Object?>? existing,
  DocumentData? documentData,
) {
  if (documentData == null) {
    return existing;
  }
  var newDocumentData = DocumentData(existing);
  newDocumentData.merge(documentData);
  return newDocumentData.asMap();
}

/// Generic record update using documentData
Map<String, Object?>? recordMapUpdate(
  Map<String, Object?>? existing,
  DocumentData? documentData,
) {
  if (documentData == null) {
    return existing;
  }
  final recordMap = (existing != null)
      ? cloneMap(existing).cast<String, Object?>()
      : <String, Object?>{};

  var map = expandUpdateData(documentDataMap(documentData)!.map)!;
  map.forEach((String key, value) {
    // devPrint('key $key');
    // special delete field
    if (value == FieldValue.delete) {
      // remove
      recordMap.remove(key);
    } else if (value is FieldValueArray) {
      recordMap[key] = fieldArrayValueMergeValue(value, recordMap[key]);
    } else {
      recordMap[key] = valueToJsonRecordValue(value);
    }
  });
  return recordMap;
}

DocumentDataMap? documentDataFromRecordMap(
  Firestore firestore,
  Map<String, Object?>? recordMap, [
  DocumentData? documentData,
]) {
  if (documentData == null && recordMap == null) {
    return null;
  }
  documentData ??= DocumentData();
  if (recordMap != null) {
    recordMap.forEach((String key, value) {
      // ignore rev
      if (key == revKey) {
        return;
      }
      // ignore updateTime
      if (key == updateTimeKey) {
        return;
      }
      // ignore createTime
      if (key == createTimeKey) {
        return;
      }
      // call setValue to prevent checking type again
      (documentData as DocumentDataMap).setValue(
        key,
        recordValueToValue(firestore, value),
      );
    });
  }
  return documentData as DocumentDataMap;
}

dynamic recordValueToValue(Firestore firestore, dynamic recordValue) {
  if (recordValue == null ||
      recordValue is num ||
      recordValue is bool ||
      recordValue is String) {
    return recordValue;
  } else if (recordValue is Map) {
    if (recordValue.containsKey(jsonTypeField)) {
      return jsonToDocumentDataValue(firestore, recordValue);
    } else {
      return recordValue
          .map(
            (key, recordValue) =>
                MapEntry(key, recordValueToValue(firestore, recordValue)),
          )
          .cast<String, Object?>();
    }
  } else if (recordValue is Iterable) {
    return recordValue
        .map((recordValue) => recordValueToValue(firestore, recordValue))
        .toList();
  } else if (recordValue is FieldValueArray) {
    if (recordValue.type == FieldValueType.arrayRemove) {
      return null;
    } else {
      return recordValue.data;
    }
  }
  throw 'recordValueToValue not supported $recordValue ${recordValue.runtimeType}';
}

/// TODO make non nullable
DocumentDataMap? documentDataMap(DocumentData? documentData) =>
    documentData as DocumentDataMap?;

DocumentDataMap? documentDataMapOrNull(DocumentData? documentData) =>
    documentData as DocumentDataMap?;

extension DocumentDataExt on DocumentData {
  /// Map
  Map<String, Object?> asMap() {
    return documentDataMapOrNull(this)!.map;
  }

  Map _mergeMap(Map map, Map override) {
    override.forEach((key, value) {
      // special delete field
      if (value == FieldValue.delete) {
        // remove
        map.remove(key);
      } else if (value is FieldValueArray) {
        map[key.toString()] = fieldArrayValueMergeValue(value, map[key]);
      } else {
        if (value is Map) {
          var overrideMap = value;
          var existingMap = map[key];
          Map subMap;
          if (existingMap is Map) {
            subMap = existingMap;
          } else {
            subMap = newModel();
          }
          value = _mergeMap(subMap, overrideMap);
        }
        map[key] = value;
      }
    });
    return map;
  }

  /// Modify in place!
  void merge(DocumentData other) {
    var map = this.asMap();
    _mergeMap(map, other.asMap());
  }

  /// Root document
  Map<String, Object?> toJsonRecordMap() {
    return documentDataMapToJsonMap(this.asMap());
  }

  /// Filled data (server timestamp to timestamp)
  Map<String, Object?> toJsonRecordValueMap() {
    return valueToJsonRecordValue(this.asMap()) as Model;
  }
}

// merge with existing record map if any
@Deprecated('Use DocumentData, merge if needed and toJsonRecordValueMap')
Map<String, Object?>? documentDataToRecordMap(
  DocumentData? documentData, [

  /// Needed for arrayRemove and merge, this is the existing record map!
  Map<String, Object?>? recordMap,
]) {
  if (documentData == null && recordMap == null) {
    return null;
  }
  recordMap = (recordMap != null)
      ? cloneMap(recordMap).cast<String, Object?>()
      : <String, Object?>{};
  if (documentData == null) {
    return recordMap;
  }

  void fixMap(Map map, Map override) {
    override.forEach((key, value) {
      devPrint('map $map override $override (key $key value $value)');
      // special delete field
      if (value == FieldValue.delete) {
        // remove
        map.remove(key);
      } else if (value is FieldValueArray) {
        map[key] = fieldArrayValueMergeValue(value, map[key]);
      } else {
        /// recursive
        if (value is Map && map[key] is Map) {
          fixMap(map[key]! as Map, value);
        } else {
          map[key] = valueToRecordValue(value);
        }
      }
    });
  }

  fixMap(recordMap, documentDataMap(documentData)!.map);

  return recordMap;
}

/// To handle arrayUnion and ArrayDelete
class FieldValueArray extends FieldValue {
  @override
  final List<Object?> data;

  FieldValueArray(super.type, this.data);

  @override
  String toString() => 'FieldValueArray($type, $data)';
}

List fieldArrayValueMergeValue(
  FieldValueArray fieldValueArray,
  Object? existing,
) {
  // get the list
  var existingIterable = existing;
  List list;
  if (existingIterable is Iterable) {
    list = existingIterable.toList().cast<Object?>();
  } else {
    list = [];
  }
  if (fieldValueArray.type == FieldValueType.arrayUnion) {
    list.addAll(
      List.from(fieldValueArray.data)
        ..removeWhere((value) => list.contains(value)),
    );
  } else if (fieldValueArray.type == FieldValueType.arrayRemove) {
    list.removeWhere((item) => fieldValueArray.data.contains(item));
  }
  return list;
}

/// Handle merge when no existing.
List<Object?> fieldArrayValueToRecordMapNoMerge(
  FieldValueArray fieldValueArray,
) {
  if (fieldValueArray.type == FieldValueType.arrayRemove) {
    return [];
  } else {
    return List.from(fieldValueArray.data);
  }
}

@Deprecated('Use valueToJsonRecordValue')
dynamic valueToRecordValue(
  dynamic value, [
  dynamic Function(dynamic value)? chainConverter,
]) {
  return valueToJsonRecordValue(value, chainConverter);
}

/// Convert to real value for saving
Model mapValueToJsonRecordMapValue(
  Map map, [
  dynamic Function(dynamic value)? chainConverter,
]) {
  return map.map<String, Object?>(
    (key, value) => MapEntry(key.toString(), chainConverter!(value)),
  );
}

/// Convert to real value for saving
List listValueToJsonRecordListValue(
  List list, [
  dynamic Function(dynamic value)? chainConverter,
]) {
  return list.map((subValue) => chainConverter!(subValue)).toList();
}

//@Deprecated('Use documentDataValueToJson')
/// Convert to real value for saving
/// Cannot be FieldValue
dynamic valueToJsonRecordValue(
  dynamic value, [
  dynamic Function(dynamic value)? chainConverter,
]) {
  chainConverter ??= valueToJsonRecordValue;
  if (value == null || value is num || value is bool || value is String) {
    return value;
  } else if (value == FieldValue.serverTimestamp) {
    return dateTimeToRecordValue(DateTime.now());
  } else if (value is DateTime) {
    return dateTimeToRecordValue(value);
  } else if (value is Timestamp) {
    return timestampToRecordValue(value);
  } else if (value is Map) {
    return mapValueToJsonRecordMapValue(value, chainConverter);
  } else if (value is List) {
    return listValueToJsonRecordListValue(value, chainConverter);
  } else if (value is DocumentDataMap) {
    // this happens when it is a list item
    return value.map.map((key, value) => MapEntry(key, chainConverter!(value)));
  } else if (value is DocumentReference) {
    return documentReferenceToRecordValue(value);
  } else if (value is Blob) {
    return blobToJsonValue(value);
  } else if (value is GeoPoint) {
    return geoPointToJsonValue(value);
  } else if (value is FieldValueArray) {
    if (value.type == FieldValueType.arrayUnion) {
      return listValueToJsonRecordListValue(value.data, chainConverter);
    } else if (value.type == FieldValueType.arrayRemove) {
      return <Object>[];
    }
  } else if (value is VectorValue) {
    return vectorToRecordValue(value);
  }
  throw 'not supported $value ${value.runtimeType}';
}

// Stored as timestamp
Map<String, Object?> dateTimeToRecordValue(DateTime dateTime) =>
    timestampToRecordValue(Timestamp.fromDateTime(dateTime));
// For now it is still a date
Map<String, Object?> timestampToRecordValue(Timestamp timestamp) =>
    timestampToJsonValue(timestamp);
Map<String, Object?> vectorToRecordValue(VectorValue vector) =>
    vectorToJsonValue(vector);
Map<String, Object?> documentReferenceToRecordValue(
  DocumentReference documentReference,
) => documentReferenceToJsonValue(documentReference);

DateTime? recordValueToDateTime(Map map) => jsonValueToDateTime(map)?.toLocal();

DocumentReference recordValueToDocumentReference(
  Firestore firestore,
  Map map,
) => jsonValueToDocumentReference(firestore, map);

class RecordMetaData {
  int? rev;
  Timestamp? createTime;
  Timestamp? updateTime;

  RecordMetaData.fromRecordMap(Map<String, Object?> recordMap) {
    rev = recordMapRev(recordMap);
    createTime = recordMapCreateTime(recordMap);
    updateTime = recordMapUpdateTime(recordMap);
  }

  @override
  String toString() {
    return 'rev; $rev, createTime: $createTime, updateTime: $updateTime';
  }
}
