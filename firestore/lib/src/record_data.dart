import 'package:tekartik_common_utils/map_utils.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/value_key_mixin.dart';
import 'package:tekartik_firebase_firestore/src/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/json_utils.dart';
import 'package:tekartik_firebase_firestore/utils/timestamp_utils.dart';

const revKey = r'$rev';

int? recordMapRev(Map<String, Object?> recordMap) => recordMap[revKey] as int?;

Timestamp? recordMapUpdateTime(Map<String, Object?> recordMap) =>
    mapUpdateTime(recordMap);

Timestamp? recordMapCreateTime(Map<String, Object?> recordMap) =>
    mapCreateTime(recordMap);

/// Generic record update
Map<String, Object?>? recordMapUpdate(
    Map<String, Object?>? existing, DocumentData? documentData) {
  if (documentData == null) {
    return null;
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
      recordMap[key] = valueToRecordValue(value);
    }
  });
  return recordMap;
}

DocumentDataMap? documentDataFromRecordMap(
    Firestore firestore, Map<String, Object?>? recordMap,
    [DocumentData? documentData]) {
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
      (documentData as DocumentDataMap)
          .setValue(key, recordValueToValue(firestore, value));
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
          .map((key, recordValue) =>
              MapEntry(key, recordValueToValue(firestore, recordValue)))
          .cast<String, Object?>();
    }
  } else if (recordValue is Iterable) {
    return recordValue
        .map((recordValue) => recordValueToValue(firestore, recordValue))
        .toList();
  }
  throw 'recordValueToValue not supported $recordValue ${recordValue.runtimeType}';
}

DocumentDataMap? documentDataMap(DocumentData? documentData) =>
    documentData as DocumentDataMap?;

// merge with existing record map if any
Map<String, Object?>? documentDataToRecordMap(DocumentData? documentData,

    /// Needed for arrayRemove
    [Map<String, Object?>? recordMap]) {
  if (documentData == null && recordMap == null) {
    return null;
  }
  var existingRecordMap = recordMap ?? {};
  recordMap = (recordMap != null)
      ? cloneMap(recordMap).cast<String, Object?>()
      : <String, Object?>{};
  if (documentData == null) {
    return recordMap;
  }
  documentDataMap(documentData)!.map.forEach((String key, value) {
    // special delete field
    if (value == FieldValue.delete) {
      // remove
      recordMap!.remove(key);
    } else if (value is FieldValueArray) {
      recordMap![key] =
          fieldArrayValueMergeValue(value, existingRecordMap[key]);
    } else {
      recordMap![key] = valueToRecordValue(value);
    }
  });
  return recordMap;
}

/// To handle arrayUnion and ArrayDelete
class FieldValueArray extends FieldValue {
  @override
  final List<Object?> data;

  FieldValueArray(FieldValueType type, this.data) : super(type);
}

dynamic fieldArrayValueMergeValue(
    FieldValueArray fieldValueArray, dynamic existing) {
  // get the list
  var existingIterable = existing;
  List list;
  if (existingIterable is Iterable) {
    list = existingIterable.toList().cast<Object?>();
  } else {
    list = [];
  }
  if (fieldValueArray.type == FieldValueType.arrayUnion) {
    list.addAll(List.from(fieldValueArray.data)
      ..removeWhere((value) => list.contains(value)));
  } else if (fieldValueArray.type == FieldValueType.arrayRemove) {
    list.removeWhere((item) => fieldValueArray.data.contains(item));
  }
  return list;
}

dynamic valueToRecordValue(dynamic value,
    [dynamic Function(dynamic value)? chainConverter]) {
  chainConverter ??= valueToRecordValue;
  if (value == null || value is num || value is bool || value is String) {
    return value;
  } else if (value == FieldValue.serverTimestamp) {
    return dateTimeToRecordValue(DateTime.now());
  } else if (value is DateTime) {
    return dateTimeToRecordValue(value);
  } else if (value is Timestamp) {
    return timestampToRecordValue(value);
  } else if (value is Map) {
    return value.map((key, value) => MapEntry(key, chainConverter!(value)));
  } else if (value is List) {
    return value.map((subValue) => chainConverter!(subValue)).toList();
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
    return value;
  }
  throw 'not supported $value ${value.runtimeType}';
}

// Stored as timestamp
Map<String, Object?> dateTimeToRecordValue(DateTime dateTime) =>
    timestampToRecordValue(Timestamp.fromDateTime(dateTime));
// For now it is still a date
Map<String, Object?> timestampToRecordValue(Timestamp timestamp) =>
    timestampToJsonValue(timestamp);

Map<String, Object?> documentReferenceToRecordValue(
        DocumentReference documentReference) =>
    documentReferenceToJsonValue(documentReference);

DateTime? recordValueToDateTime(Map map) => jsonValueToDateTime(map)?.toLocal();

DocumentReference recordValueToDocumentReference(
        Firestore firestore, Map map) =>
    jsonValueToDocumentReference(firestore, map);

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
