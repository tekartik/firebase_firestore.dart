import 'dart:convert';
import 'dart:typed_data';

import 'package:cv/cv.dart';
import 'package:tekartik_common_utils/date_time_utils.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/snapshot_meta_data_mixin.dart';
import 'package:tekartik_firebase_firestore/src/firestore.dart';
import 'package:tekartik_firebase_firestore/src/record_data.dart';
import 'package:tekartik_firebase_firestore/utils/firestore_mixin.dart';

import 'common/firestore_mock.dart';
import 'common/reference_mixin.dart';

/// Json type field.
const String jsonTypeField = r'$t';

/// Json value field.
const String jsonValueField = r'$v';

/// DateTime type.
const String typeDateTime = 'DateTime';

/// Timestamp type.
const String typeTimestamp = 'Timestamp';

/// Vector type.
const String typeVector = 'Vector';

/// FieldValue type.
const String typeFieldValue = 'FieldValue';

/// DocumentReference type.
const String typeDocumentReference = 'DocumentReference';

/// GeoPoint type.
const String typeGeoPoint = 'GeoPoint';

/// Blob type.
const String typeBlob = 'Blob';

/// FieldValue delete value.
const String valueFieldValueDelete = '~delete';

/// FieldValue server timestamp value.
const String valueFieldValueServerTimestamp = '~serverTimestamp';

/// Type value to json.
Map<String, Object?> typeValueToJson(String type, dynamic value) {
  return <String, Object?>{jsonTypeField: type, jsonValueField: value};
}

/// DateTime to json value.
Map<String, Object?> dateTimeToJsonValue(DateTime dateTime) =>
    typeValueToJson(typeDateTime, dateTimeToString(dateTime));

/// Timestamp to json value.
Map<String, Object?> timestampToJsonValue(Timestamp timestamp) =>
    typeValueToJson(typeTimestamp, timestamp.toIso8601String());

/// Vector to json value.
Map<String, Object?> vectorToJsonValue(VectorValue vector) =>
    typeValueToJson(typeVector, vector.toArray());

/// DocumentReference to json value.
Map<String, Object?> documentReferenceToJsonValue(
  DocumentReference documentReference,
) => typeValueToJson(typeDocumentReference, documentReference.path);

/// Blob to json value.
Map<String, Object?> blobToJsonValue(Blob blob) =>
    typeValueToJson(typeBlob, base64.encode(blob.data));

/// FieldValue to json value.
Map<String, Object?> fieldValueToJsonValue(FieldValue fieldValue) {
  if (fieldValue == FieldValue.delete) {
    return typeValueToJson(typeFieldValue, valueFieldValueDelete);
  } else if (fieldValue == FieldValue.serverTimestamp) {
    return typeValueToJson(typeFieldValue, valueFieldValueServerTimestamp);
  }
  throw ArgumentError.value(
    fieldValue,
    '${fieldValue.runtimeType}',
    'Unsupported value for fieldValueToJsonValue',
  );
}

/// FieldValue from json value.
FieldValue fieldValueFromJsonValue(dynamic value) {
  if (value == valueFieldValueDelete) {
    return FieldValue.delete;
  } else if (value == valueFieldValueServerTimestamp) {
    return FieldValue.serverTimestamp;
  }
  throw ArgumentError.value(
    value,
    '${value.runtimeType}',
    'Unsupported value for fieldValueFromJsonValue',
  );
}

/// Json value to DateTime.
DateTime? jsonValueToDateTime(Map map) {
  assert(map[jsonTypeField] == typeDateTime);
  return anyToDateTime(map[jsonValueField]);
}

/// Json value to Timestamp.
Timestamp? jsonValueToTimestamp(Map map) {
  assert(
    map[jsonTypeField] == typeDateTime || map[jsonTypeField] == typeTimestamp,
  );
  return parseTimestamp(map[jsonValueField]);
}

/// Json value to DocumentReference.
DocumentReference jsonValueToDocumentReference(Firestore firestore, Map map) {
  assert(map[jsonTypeField] == typeDocumentReference);
  return firestore.doc(map[jsonValueField] as String);
}

/// Json value to Blob.
Blob jsonValueToBlob(Map map) {
  assert(map[jsonTypeField] == typeBlob);
  var base64value = map[jsonValueField] as String?;
  if (base64value == null) {
    return Blob(Uint8List(0));
  } else {
    return Blob(base64.decode(base64value));
  }
}

/// Json value to Vector.
VectorValue jsonValueToVector(Map map) {
  assert(map[jsonTypeField] == typeVector);
  var array = (map[jsonValueField] as List)
      .cast<num>()
      .map((e) => e.toDouble())
      .toList();
  return VectorValue(array);
}

/// GeoPoint to json value.
Map<String, Object?> geoPointToJsonValue(GeoPoint geoPoint) {
  return typeValueToJson(typeGeoPoint, {
    'latitude': geoPoint.latitude,
    'longitude': geoPoint.longitude,
  });
}

/// Json value to GeoPoint.
GeoPoint jsonValueToGeoPoint(Map map) {
  assert(map[jsonTypeField] == typeGeoPoint);
  var valueMap = map[jsonValueField] as Map;
  return GeoPoint(valueMap['latitude'] as num, valueMap['longitude'] as num);
}

// utilities

// common value in both format
bool _isCommonValue(dynamic value) {
  return (value == null) ||
      (value is String) ||
      (value is num) ||
      (value is bool);
}

/// Root document data to json map.
Map<String, Object?> documentDataMapToJsonMap(Map documentDataMap) {
  return documentDataMap.map<String, Object?>(
    (key, value) => MapEntry(key as String, documentDataValueToJson(value)),
  );
}

/// Handle any document data source (map, DocumentData)
/// Convert to something that can be send, not a value to save.
Object? documentDataValueToJson(Object? value) {
  if (_isCommonValue(value)) {
    return value;
  } else if (value is List) {
    return value.map((value) => documentDataValueToJson(value)).toList();
  } else if (value is Map) {
    return documentDataMapToJsonMap(value);
  } else if (value is DocumentData) {
    // Handle this that could happen from a map
    return documentDataMapToJsonMap(value.asMap());
  } else if (value is DateTime) {
    return dateTimeToJsonValue(value);
  } else if (value is Timestamp) {
    return timestampToJsonValue(value);
  } else if (value is FieldValue) {
    return fieldValueToJsonValue(value);
  } else if (value is DocumentReference) {
    return documentReferenceToJsonValue(value);
  } else if (value is Blob) {
    return blobToJsonValue(value);
  } else if (value is GeoPoint) {
    return geoPointToJsonValue(value);
  } else {
    throw ArgumentError.value(
      value,
      '${value.runtimeType}',
      'Unsupported value for documentDataValueToJson',
    );
  }
}

final _firebaseMock = FirestoreMock();

/// Does not support record reference.
Model? jsonToDocumentDataValueNoFirestore(Map value) {
  return jsonToDocumentDataValue(_firebaseMock, value) as Model?;
}

/// Convert a json encoded value as a document data value
Object? jsonToDocumentDataValue(Firestore firestore, Object? value) {
  if (_isCommonValue(value)) {
    return value;
  } else if (value is List) {
    return value
        .map((value) => jsonToDocumentDataValue(firestore, value))
        .toList();
  } else if (value is Map) {
    // Check encoded value
    var type = value[jsonTypeField] as String?;
    if (type != null) {
      switch (type) {
        case typeDateTime:
          {
            var dateTime = anyToDateTime(value[jsonValueField])?.toLocal();
            if (firestoreTimestampsInSnapshots(firestore)) {
              return Timestamp.fromDateTime(dateTime!);
            }
            return dateTime;
          }
        case typeTimestamp:
          {
            var timestamp = parseTimestamp(value[jsonValueField]);
            if (firestoreTimestampsInSnapshots(firestore)) {
              return timestamp;
            }
            return timestamp!.toDateTime();
          }
        case typeFieldValue:
          return fieldValueFromJsonValue(value[jsonValueField]);
        case typeDocumentReference:
          return jsonValueToDocumentReference(firestore, value);
        case typeBlob:
          return jsonValueToBlob(value);
        case typeGeoPoint:
          return jsonValueToGeoPoint(value);
        case typeVector:
          return jsonValueToVector(value);

        default:
          throw UnsupportedError('value $value');
      }
    } else {
      return value.map<String, Object?>(
        (key, value) =>
            MapEntry(key as String, jsonToDocumentDataValue(firestore, value)),
      );
    }
  } else {
    throw ArgumentError.value(
      value,
      '${value.runtimeType}',
      'Unsupported value for jsonToDocumentDataValue',
    );
  }
}

// remove createTime and updateTime
/// Document data from snapshot json map.
DocumentData? documentDataFromSnapshotJsonMap(
  Firestore firestore,
  Map<String, Object?> map,
) {
  map.remove(createTimeKey);
  map.remove(updateTimeKey);
  return documentDataFromJsonMap(firestore, map);
}

/// Read a document data from a json map
DocumentData? documentDataFromJsonMap(
  Firestore firestore,
  Map<String, Object?>? map,
) {
  if (map == null) {
    return null;
  }
  return DocumentDataMap(
    map: jsonToDocumentDataValue(firestore, map) as Map<String, Object?>?,
  );
}

/// Read a document data from a json map without firestore (used only for references=
DocumentData? documentDataFromJsonMapNoFirestore(Map<String, Object?>? map) {
  if (map == null) {
    return null;
  }
  return DocumentDataMap(map: jsonToDocumentDataValueNoFirestore(map));
}

/// Json map to firestore document data map.
Map<String, Object?> documentDataMapFromJsonMap(
  Firestore firestore,
  Map<String, Object?> map,
) {
  return documentDataFromJsonMap(firestore, map)!.asMap();
}

/// will return null if map is null
DocumentData documentDataFromMap(Map<String, Object?> map) {
  return DocumentData(map);
}

/// Document data from snapshot.
DocumentData? documentDataFromSnapshot(DocumentSnapshot snapshot) =>
    snapshot.exists ? DocumentData(snapshot.data) : null;

/// Snapshot data to json map.
Map<String, Object?>? snapshotDataToJsonMap(DocumentSnapshot snapshot) {
  if (snapshot.exists) {
    var map = documentDataToJsonMap(documentDataFromSnapshot(snapshot));
    return map;
  } else {
    return null;
  }
}

/// Document data to json map.
Map<String, Object?>? documentDataToJsonMap(DocumentData? documentData) {
  if (documentData == null) {
    return null;
  }
  return documentData.toJsonRecordMap();
}

/// Order by info.
class OrderByInfo {
  /// Field path.
  String? fieldPath;

  /// Ascending.
  bool ascending;

  /// Constructor.
  OrderByInfo({required this.fieldPath, required this.ascending});

  @override
  String toString() => '$fieldPath ${ascending ? 'ASC' : 'DESC'}';
}

/// Limit info.
class LimitInfo {
  /// Document id.
  String? documentId;

  /// Values.
  List? values;

  /// Inclusive.
  late bool inclusive; // true = At
  /// Constructor.
  LimitInfo({this.documentId, this.values, bool? inclusive}) {
    if (inclusive != null) {
      this.inclusive = inclusive;
    }
  }

  /// Clone.
  LimitInfo clone() {
    return LimitInfo()
      ..documentId = documentId
      ..values = values
      ..inclusive = inclusive;
  }

  @override
  String toString() =>
      '${documentId ?? values} ${inclusive ? '(inclusive)' : ''}';
}

/// Where info.
class WhereInfo {
  /// Field path.
  String fieldPath;

  /// Constructor.
  WhereInfo(
    this.fieldPath, {
    this.isEqualTo,
    this.isLessThan,
    this.isLessThanOrEqualTo,
    this.isGreaterThan,
    this.isGreaterThanOrEqualTo,
    this.arrayContains,
    this.arrayContainsAny,
    this.whereIn,
    this.notIn,
    this.isNull,
  }) {
    assert(
      isEqualTo != null ||
          isLessThan != null ||
          isLessThanOrEqualTo != null ||
          isGreaterThan != null ||
          isGreaterThanOrEqualTo != null ||
          arrayContains != null ||
          arrayContainsAny != null ||
          whereIn != null ||
          notIn != null ||
          isNull != null,
      'Empty where',
    );
    assert(
      arrayContainsAny == null || arrayContainsAny!.isNotEmpty,
      'Invalid Query. A non-empty array is required for \'array-contains-any\' filters.',
    );
    assert(
      whereIn == null || whereIn!.isNotEmpty,
      'Invalid Query. A non-empty array is required for \'in\' filters.',
    );
    assert(
      notIn == null || notIn!.isNotEmpty,
      'Invalid Query. A non-empty array is required for \'in\' filters.',
    );
  }

  /// Is equal to.
  dynamic isEqualTo;

  /// Is less than.
  dynamic isLessThan;

  /// Is less than or equal to.
  dynamic isLessThanOrEqualTo;

  /// Is greater than.
  dynamic isGreaterThan;

  /// Is greater than or equal to.
  dynamic isGreaterThanOrEqualTo;

  /// Array contains.
  dynamic arrayContains;

  /// Array contains any.
  List<Object>? arrayContainsAny;

  /// Where in.
  List<Object>? whereIn;

  /// Not in.
  List<Object>? notIn;

  /// Is null.
  bool? isNull;

  @override
  String toString() {
    if (isNull != null) {
      return '$fieldPath is null';
    } else if (isEqualTo != null) {
      return '$fieldPath == $isEqualTo';
    } else if (isLessThan != null) {
      return '$fieldPath < $isLessThan';
    } else if (isLessThanOrEqualTo != null) {
      return '$fieldPath <= $isLessThanOrEqualTo';
    } else if (isGreaterThan != null) {
      return '$fieldPath > $isGreaterThan';
    } else if (isGreaterThanOrEqualTo != null) {
      return '$fieldPath >= $isGreaterThanOrEqualTo';
    } else if (arrayContains != null) {
      return '$fieldPath array-contains $arrayContains';
    } else if (arrayContainsAny != null) {
      return '$fieldPath array-contains-any $arrayContainsAny';
    } else if (whereIn != null) {
      return '$fieldPath in $whereIn';
    } else if (notIn != null) {
      return '$fieldPath not-in $notIn';
    }
    return super.toString();
  }
}

// Mutable, must be clone before
/// Query info.
class QueryInfo {
  /// Select key paths.
  List<String>? selectKeyPaths;

  /// Order bys.
  List<OrderByInfo> orderBys = [];

  /// Start limit.
  LimitInfo? startLimit;

  /// End limit.
  LimitInfo? endLimit;

  /// Limit.
  int? limit;

  /// Offset.
  int? offset;

  /// Wheres.
  List<WhereInfo> wheres = [];

  /// Clone.
  QueryInfo clone() {
    return QueryInfo()
      ..limit = limit
      ..offset = offset
      ..startLimit = startLimit?.clone()
      ..endLimit = endLimit?.clone()
      ..wheres = List.from(wheres)
      ..selectKeyPaths = selectKeyPaths
      ..orderBys = List.from(orderBys);
  }

  /// Start at.
  void startAt({DocumentSnapshot? snapshot, List? values}) =>
      startLimit = (LimitInfo()
        ..documentId = snapshot?.ref.id
        ..values = values
        ..inclusive = true);

  /// Start after.
  void startAfter({DocumentSnapshot? snapshot, List? values}) =>
      startLimit = (LimitInfo()
        ..documentId = snapshot?.ref.id
        ..values = values
        ..inclusive = false);

  /// End at.
  void endAt({DocumentSnapshot? snapshot, List? values}) =>
      endLimit = (LimitInfo()
        ..documentId = snapshot?.ref.id
        ..values = values
        ..inclusive = true);

  /// End before.
  void endBefore({DocumentSnapshot? snapshot, List? values}) =>
      endLimit = (LimitInfo()
        ..documentId = snapshot?.ref.id
        ..values = values
        ..inclusive = false);

  /// Add where.
  void addWhere(WhereInfo where) {
    wheres.add(where);
  }

  /// Debug check.
  void debugCheck() {
    if (orderBys.isNotEmpty) {
      var orderByKeys = orderBys.map((e) => e.fieldPath).toSet();

      var whereKeys = wheres
          .where(
            (e) =>
                e.isGreaterThanOrEqualTo != null ||
                e.isGreaterThan != null ||
                e.isLessThan != null ||
                e.isLessThanOrEqualTo != null,
          )
          .map((e) => e.fieldPath)
          .toSet();
      for (var whereKey in whereKeys) {
        if (!orderByKeys.contains(whereKey)) {
          throw StateError(
            'Missing orderBy for where $whereKey in $orderByKeys',
          );
        }
      }
      for (var valuesList in [startLimit?.values, endLimit?.values]) {
        if (valuesList != null) {
          if (orderBys.length != valuesList.length) {
            throw StateError(
              'Value count in $valuesList not matching order list $orderByKeys',
            );
          }
        }
      }
    }
  }
}

/// Where info from json map.
WhereInfo whereInfoFromJsonMap(Firestore firestore, Map<String, Object?> map) {
  bool? isNull;
  Object? isEqualTo;
  var value = jsonToDocumentDataValue(firestore, map['value']);
  var operator = map['operator'];
  if (operator == operatorEqual) {
    if (value == null) {
      isNull = true;
    } else {
      isEqualTo = value;
    }
  } else if (operator == operatorLessThan) {}
  var whereInfo = WhereInfo(
    map['fieldPath'] as String,
    isEqualTo: isEqualTo,
    isNull: isNull,
    isLessThan: (operator == operatorLessThan) ? value : null,
    isLessThanOrEqualTo: (operator == operatorLessThanOrEqual) ? value : null,
    isGreaterThan: (operator == operatorGreaterThan) ? value : null,
    isGreaterThanOrEqualTo: (operator == operatorGreaterThanOrEqual)
        ? value
        : null,
    arrayContains: (operator == operatorArrayContains) ? value : null,
    arrayContainsAny: (operator == operatorArrayContainsAny)
        ? (value as List).cast<Object>()
        : null,
    whereIn: (operator == operatorIn) ? (value as List).cast<Object>() : null,
    notIn: (operator == operatorNotIn) ? (value as List).cast<Object>() : null,
  );

  return whereInfo;
}

/// Order by info from json map.
OrderByInfo orderByInfoFromJsonMap(Map<String, Object?> map) {
  var orderByInfo = OrderByInfo(
    fieldPath: map['fieldPath'] as String?,
    ascending: (map['direction'] as String?) != orderByDescending,
  );
  return orderByInfo;
}

const _operatorKey = 'operator';
const _valueKey = 'value';

/// Where info to json map.
Map<String, Object?> whereInfoToJsonMap(WhereInfo whereInfo) {
  var map = <String, Object?>{'fieldPath': whereInfo.fieldPath};
  if (whereInfo.isEqualTo != null) {
    map[_operatorKey] = operatorEqual;
    map[_valueKey] = documentDataValueToJson(whereInfo.isEqualTo);
  } else if (whereInfo.isLessThanOrEqualTo != null) {
    map[_operatorKey] = operatorLessThanOrEqual;
    map[_valueKey] = documentDataValueToJson(whereInfo.isLessThanOrEqualTo);
  } else if (whereInfo.isLessThan != null) {
    map[_operatorKey] = operatorLessThan;
    map[_valueKey] = documentDataValueToJson(whereInfo.isLessThan);
  } else if (whereInfo.isGreaterThanOrEqualTo != null) {
    map[_operatorKey] = operatorGreaterThanOrEqual;
    map[_valueKey] = documentDataValueToJson(whereInfo.isGreaterThanOrEqualTo);
  } else if (whereInfo.isGreaterThan != null) {
    map[_operatorKey] = operatorGreaterThan;
    map[_valueKey] = documentDataValueToJson(whereInfo.isGreaterThan);
  } else if (whereInfo.arrayContains != null) {
    map[_operatorKey] = operatorArrayContains;
    map[_valueKey] = documentDataValueToJson(whereInfo.arrayContains);
  } else if (whereInfo.isNull != null) {
    map[_operatorKey] = operatorEqual;
    map[_valueKey] = null;
  } else if (whereInfo.arrayContainsAny != null) {
    map[_operatorKey] = operatorArrayContainsAny;
    map[_valueKey] = documentDataValueToJson(whereInfo.arrayContainsAny);
  } else if (whereInfo.whereIn != null) {
    map[_operatorKey] = operatorIn;
    map[_valueKey] = documentDataValueToJson(whereInfo.whereIn);
  } else if (whereInfo.notIn != null) {
    map[_operatorKey] = operatorNotIn;
    map[_valueKey] = documentDataValueToJson(whereInfo.notIn);
  }
  return map;
}

/// Order by info to json map.
Map<String, Object?> orderByInfoToJsonMap(OrderByInfo orderByInfo) {
  var map = <String, Object?>{
    'fieldPath': orderByInfo.fieldPath,
    'direction': orderByInfo.ascending ? orderByAscending : orderByDescending,
  };
  return map;
}

/// Limit info to json map.
Map<String, Object?> limitInfoToJsonMap(LimitInfo limitInfo) {
  var map = <String, Object?>{};
  if (limitInfo.inclusive) {
    map['inclusive'] = true;
  }
  if (limitInfo.values != null) {
    map['values'] = limitInfo.values!
        .map((value) => documentDataValueToJson(value))
        .toList();
  }
  if (limitInfo.documentId != null) {
    map['documentId'] = limitInfo.documentId;
  }
  return map;
}

/// Limit info from json map.
LimitInfo limitInfoFromJsonMap(Firestore firestore, Map<String, Object?> map) {
  var limitInfo = LimitInfo();

  limitInfo.inclusive = map['inclusive'] == true;

  if (map.containsKey('values')) {
    limitInfo.values = (map['values'] as List)
        .map((value) => jsonToDocumentDataValue(firestore, value))
        .toList();
  } else if (map.containsKey('documentId')) {
    limitInfo.documentId = map['documentId'] as String?;
  }
  return limitInfo;
}

/// Query info to json map.
Map<String, Object?> queryInfoToJsonMap(QueryInfo queryInfo) {
  var map = <String, Object?>{};
  if (queryInfo.limit != null) {
    map['limit'] = queryInfo.limit;
  }
  if (queryInfo.offset != null) {
    map['offset'] = queryInfo.offset;
  }
  if (queryInfo.wheres.isNotEmpty) {
    map['wheres'] = queryInfo.wheres
        .map((whereInfo) => whereInfoToJsonMap(whereInfo))
        .toList();
  }
  if (queryInfo.orderBys.isNotEmpty) {
    map['orderBys'] = queryInfo.orderBys
        .map((orderBy) => orderByInfoToJsonMap(orderBy))
        .toList();
  }
  if (queryInfo.selectKeyPaths != null) {
    map['selectKeyPaths'] = queryInfo.selectKeyPaths;
  }
  if (queryInfo.startLimit != null) {
    map['startLimit'] = limitInfoToJsonMap(queryInfo.startLimit!);
  }
  if (queryInfo.endLimit != null) {
    map['endLimit'] = limitInfoToJsonMap(queryInfo.endLimit!);
  }
  return map;
}

/// Query info from json map.
QueryInfo queryInfoFromJsonMap(Firestore firestore, Map<String, Object?> map) {
  final queryInfo = QueryInfo();
  if (map.containsKey('limit')) {
    queryInfo.limit = map['limit'] as int?;
  }
  if (map.containsKey('offset')) {
    queryInfo.offset = map['offset'] as int?;
  }
  if (map.containsKey('wheres')) {
    queryInfo.wheres = (map['wheres'] as List)
        .map<WhereInfo>(
          (map) => whereInfoFromJsonMap(firestore, map as Map<String, Object?>),
        )
        .toList();
  }
  if (map.containsKey('orderBys')) {
    queryInfo.orderBys = (map['orderBys'] as List)
        .map<OrderByInfo>(
          (map) => orderByInfoFromJsonMap(map as Map<String, Object?>),
        )
        .toList();
  }
  if (map.containsKey('selectKeyPaths')) {
    queryInfo.selectKeyPaths = (map['selectKeyPaths'] as List).cast<String>();
  }
  if (map.containsKey('startLimit')) {
    queryInfo.startLimit = limitInfoFromJsonMap(
      firestore,
      map['startLimit'] as Map<String, Object?>,
    );
  }
  if (map.containsKey('endLimit')) {
    queryInfo.endLimit = limitInfoFromJsonMap(
      firestore,
      map['endLimit'] as Map<String, Object?>,
    );
  }
  return queryInfo;
}

/// Change type added.
const changeTypeAdded = 'added';

/// Change type modified.
const changeTypeModified = 'modified';

/// Change type removed.
const changeTypeRemoved = 'removed';

/// Document change type from string.
DocumentChangeType? documentChangeTypeFromString(String type) {
  // [:added:], [:removed:] or [:modified:]
  if (type == changeTypeAdded) {
    return DocumentChangeType.added;
  } else if (type == changeTypeRemoved) {
    return DocumentChangeType.removed;
  } else if (type == changeTypeModified) {
    return DocumentChangeType.modified;
  }
  return null;
}

/// Document change type to string.
String? documentChangeTypeToString(DocumentChangeType type) {
  switch (type) {
    case DocumentChangeType.added:
      return changeTypeAdded;
    case DocumentChangeType.removed:
      return changeTypeRemoved;
    case DocumentChangeType.modified:
      return changeTypeModified;
  }
}

/// Sanitize reference path.
String sanitizeReferencePath(String path) {
  if (path.startsWith('/')) {
    path = path.substring(1);
  }
  if (path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  return path;
}

/// Is document reference path.
bool isDocumentReferencePath(String path) {
  var count = localPathReferenceParts(path).length;
  return (count % 2) == 0;
}

/// Is collection reference path.
bool isCollectionReferencePath(String path) => !isDocumentReferencePath(path);

/// Write batch base.
abstract class WriteBatchBase implements WriteBatch {
  /// Operations.
  final List<WriteBatchOperation> operations = [];

  @override
  void delete(DocumentReference documentRef) =>
      operations.add(WriteBatchOperationDelete(documentRef));

  @override
  void set(
    DocumentReference documentRef,
    Map<String, Object?> data, [
    SetOptions? options,
  ]) {
    operations.add(
      WriteBatchOperationSet(documentRef, DocumentData(data), options),
    );
  }

  @override
  void update(DocumentReference documentRef, Map<String, Object?> data) {
    operations.add(WriteBatchOperationUpdate(documentRef, DocumentData(data)));
  }
}

/// Write batch operation.
abstract class WriteBatchOperation {}

/// Write batch operation base.
class WriteBatchOperationBase implements WriteBatchOperation {
  /// Document reference.
  final DocumentReference? docRef;

  /// Constructor.
  WriteBatchOperationBase(this.docRef);

  @override
  String toString() => '$runtimeType(${docRef!.path})';
}

/// Write batch operation delete.
class WriteBatchOperationDelete extends WriteBatchOperationBase {
  /// Constructor.
  WriteBatchOperationDelete(super.docRef);
}

/// Write batch operation set.
class WriteBatchOperationSet extends WriteBatchOperationBase {
  /// Document data.
  final DocumentData documentData;

  /// Set options.
  final SetOptions? options;

  /// Constructor.
  WriteBatchOperationSet(
    DocumentReference super.docRef,
    this.documentData,
    this.options,
  );
}

/// Write batch operation update.
class WriteBatchOperationUpdate extends WriteBatchOperationBase {
  /// Document data.
  final DocumentData documentData;

  /// Constructor.
  WriteBatchOperationUpdate(DocumentReference super.docRef, this.documentData);
}

/// Write result base.
abstract class WriteResultBase {
  /// The path of the document
  final String path;

  /// Constructor
  WriteResultBase(this.path);

  /// Added if previous does not exist and new exists
  bool get added => newExists && !previousExists;

  /// Removed if previous exists and new does not
  bool get removed => previousExists && !newExists;

  /// Modified if both previous and new exists
  bool get modified => previousExists && newExists;

  /// Exists if new exists
  bool get exists => newExists;

  /// Previous exists
  bool get previousExists => previousSnapshot?.exists == true;

  /// New exists
  bool get newExists => newSnapshot?.exists == true;

  /// Previous snapshot
  DocumentSnapshot? previousSnapshot;

  /// New snapshot (can be null for delete)
  DocumentSnapshot? newSnapshot;

  /// Either previous or new should exists
  bool get shouldNotify => previousExists || newExists;

  @override
  String toString() {
    return '$path added $added removed $removed old ${previousSnapshot?.exists} new ${newSnapshot?.exists}';
  }
}

/// Document change base.
class DocumentChangeBase implements DocumentChange {
  /// Constructor.
  DocumentChangeBase(this.type, this.document, this.newIndex, this.oldIndex);

  // Change later once building the array
  @override
  DocumentChangeType type;

  @override
  final DocumentSnapshot document;

  @override
  final int newIndex;

  @override
  final int oldIndex;

  /// Document base.
  DocumentSnapshotBase get documentBase => document as DocumentSnapshotBase;

  @override
  String toString() => '${document.ref.path} $type $oldIndex $newIndex';
}

/// Document snapshot base.
abstract class DocumentSnapshotBase
    with DocumentSnapshotMixin
    implements DocumentSnapshot {
  /// Meta data.
  final RecordMetaData? meta;
  @override
  final DocumentReference ref;

  /// Revision.
  int? get rev => meta?.rev;

  @override
  Timestamp? get updateTime => meta?.updateTime;

  @override
  Timestamp? get createTime => meta?.createTime;

  /// Document data.
  final DocumentData? documentData;

  late bool _exists;

  @override
  bool get exists => _exists;

  /// Constructor.
  DocumentSnapshotBase(this.ref, this.meta, this.documentData, {bool? exists}) {
    _exists = exists ?? (documentData != null);
  }

  @override
  Map<String, Object?> get data => documentData!.asMap();

  @override
  SnapshotMetadata get metadata => _snapshotMetadataSembast;
}

/// Document snapshot base extension.
extension DocumentSnapshotBaseExtension on DocumentSnapshotBase {
  /// Value at field path.
  Object? valueAtFieldPath(String fieldPath) {
    return (documentData as DocumentDataMap).valueAtFieldPath(fieldPath);
  }
}

/// Meta data always ok.
/// Snapshot metadata sembast.
class SnapshotMetadataSembast
    with SnapshotMetadataMixin
    implements SnapshotMetadata {
  @override
  bool get hasPendingWrites => false;

  @override
  bool get isFromCache => false;
}

/// Re-use it!
final _snapshotMetadataSembast = SnapshotMetadataSembast();

/// Query snapshot base.
class QuerySnapshotBase implements QuerySnapshot {
  /// Constructor.
  QuerySnapshotBase(this.docs, this.documentChanges);

  @override
  final List<DocumentSnapshot> docs;

  @override
  final List<DocumentChange> documentChanges;

  /// Check if it contains a document.
  bool contains(DocumentSnapshotBase document) {
    for (var doc in docs) {
      if (doc.ref.path == document.ref.path) {
        return true;
      }
    }
    return false;
  }

  @override
  String toString() =>
      'docs: ${docs.length} changes: ${documentChanges.length}';
}

// TODO handle sub field name
/// To selected map.
Map<String, Object?> toSelectedMap(Map map, List<String> fields) {
  var selectedMap = <String, Object?>{};
  for (var key in fields) {
    if (map.containsKey(key)) {
      selectedMap[key] = map[key];
    }
  }
  return selectedMap;
}
