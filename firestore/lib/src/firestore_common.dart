import 'dart:convert';
import 'dart:typed_data';

import 'package:tekartik_common_utils/date_time_utils.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/snapshot_meta_data_mixin.dart';
import 'package:tekartik_firebase_firestore/src/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/firestore_mixin.dart';
import 'package:tekartik_firebase_firestore/utils/timestamp_utils.dart';

import 'common/reference_mixin.dart';

const String jsonTypeField = r'$t';
const String jsonValueField = r'$v';
const String typeDateTime = 'DateTime';
const String typeTimestamp = 'Timestamp';
const String typeFieldValue = 'FieldValue';
const String typeDocumentReference = 'DocumentReference';
const String typeGeoPoint = 'GeoPoint';
const String typeBlob = 'Blob';
const String valueFieldValueDelete = '~delete';
const String valueFieldValueServerTimestamp = '~serverTimestamp';

Map<String, Object?> typeValueToJson(String type, dynamic value) {
  return <String, Object?>{jsonTypeField: type, jsonValueField: value};
}

Map<String, Object?> dateTimeToJsonValue(DateTime dateTime) =>
    typeValueToJson(typeDateTime, dateTimeToString(dateTime));

Map<String, Object?> timestampToJsonValue(Timestamp timestamp) =>
    typeValueToJson(typeTimestamp, timestamp.toIso8601String());

Map<String, Object?> documentReferenceToJsonValue(
        DocumentReference documentReference) =>
    typeValueToJson(typeDocumentReference, documentReference.path);

Map<String, Object?> blobToJsonValue(Blob blob) =>
    typeValueToJson(typeBlob, base64.encode(blob.data));

Map<String, Object?> fieldValueToJsonValue(FieldValue fieldValue) {
  if (fieldValue == FieldValue.delete) {
    return typeValueToJson(typeFieldValue, valueFieldValueDelete);
  } else if (fieldValue == FieldValue.serverTimestamp) {
    return typeValueToJson(typeFieldValue, valueFieldValueServerTimestamp);
  }
  throw ArgumentError.value(fieldValue, '${fieldValue.runtimeType}',
      'Unsupported value for fieldValueToJsonValue');
}

FieldValue fieldValueFromJsonValue(dynamic value) {
  if (value == valueFieldValueDelete) {
    return FieldValue.delete;
  } else if (value == valueFieldValueServerTimestamp) {
    return FieldValue.serverTimestamp;
  }
  throw ArgumentError.value(value, '${value.runtimeType}',
      'Unsupported value for fieldValueFromJsonValue');
}

DateTime? jsonValueToDateTime(Map map) {
  assert(map[jsonTypeField] == typeDateTime);
  return anyToDateTime(map[jsonValueField]);
}

Timestamp? jsonValueToTimestamp(Map map) {
  assert(map[jsonTypeField] == typeDateTime ||
      map[jsonTypeField] == typeTimestamp);
  return parseTimestamp(map[jsonValueField]);
}

DocumentReference jsonValueToDocumentReference(Firestore firestore, Map map) {
  assert(map[jsonTypeField] == typeDocumentReference);
  return firestore.doc(map[jsonValueField] as String);
}

Blob jsonValueToBlob(Map map) {
  assert(map[jsonTypeField] == typeBlob);
  var base64value = map[jsonValueField] as String?;
  if (base64value == null) {
    return Blob(Uint8List(0));
  } else {
    return Blob(base64.decode(base64value));
  }
}

Map<String, Object?> geoPointToJsonValue(GeoPoint geoPoint) {
  return typeValueToJson(typeGeoPoint,
      {'latitude': geoPoint.latitude, 'longitude': geoPoint.longitude});
}

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

dynamic documentDataValueToJson(dynamic value) {
  if (_isCommonValue(value)) {
    return value;
  } else if (value is List) {
    return value.map((value) => documentDataValueToJson(value)).toList();
  } else if (value is Map) {
    return value.map<String, Object?>((key, value) =>
        MapEntry(key as String, documentDataValueToJson(value)));
  } else if (value is DocumentData) {
    // Handle this that could happen from a map
    return documentDataValueToJson((value as DocumentDataMap).map);
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
    throw ArgumentError.value(value, '${value.runtimeType}',
        'Unsupported value for documentDataValueToJson');
  }
}

dynamic jsonToDocumentDataValue(Firestore firestore, dynamic value) {
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
        default:
          throw UnsupportedError('value $value');
      }
    } else {
      return value.map<String, Object?>((key, value) =>
          MapEntry(key as String, jsonToDocumentDataValue(firestore, value)));
    }
  } else {
    throw ArgumentError.value(value, '${value.runtimeType}',
        'Unsupported value for jsonToDocumentDataValue');
  }
}

// remove createTime and updateTime
DocumentData? documentDataFromSnapshotJsonMap(
    Firestore firestore, Map<String, Object?> map) {
  map.remove(createTimeKey);
  map.remove(updateTimeKey);
  return documentDataFromJsonMap(firestore, map);
}

/// Read a document data from a json map
DocumentData? documentDataFromJsonMap(
    Firestore firestore, Map<String, Object?>? map) {
  if (map == null) {
    return null;
  }
  return DocumentDataMap(
      map: jsonToDocumentDataValue(firestore, map) as Map<String, Object?>?);
}

/// Json map to firestore document data map.
Map<String, Object?> documentDataMapFromJsonMap(
    Firestore firestore, Map<String, Object?> map) {
  return documentDataFromJsonMap(firestore, map)!.asMap();
}

/// Firestore document data to json map.
Map<String, Object?> documentDataMapToJsonMap(Map<String, Object?> map) {
  return documentDataToJsonMap(documentDataFromMap(map))!;
}

/// will return null if map is null
DocumentData documentDataFromMap(Map<String, Object?> map) {
  return DocumentData(map);
}

DocumentData? documentDataFromSnapshot(DocumentSnapshot snapshot) =>
    snapshot.exists == true ? DocumentData(snapshot.data) : null;

Map<String, Object?>? snapshotToJsonMap(DocumentSnapshot snapshot) {
  if (snapshot.exists == true) {
    var map = documentDataToJsonMap(documentDataFromSnapshot(snapshot));
    return map;
  } else {
    return null;
  }
}

Map<String, Object?>? documentDataToJsonMap(DocumentData? documentData) {
  if (documentData == null) {
    return null;
  }
  return documentDataValueToJson((documentData as DocumentDataMap).map)
      as Map<String, Object?>?;
}

class OrderByInfo {
  String? fieldPath;
  bool ascending;

  OrderByInfo({required this.fieldPath, required this.ascending});

  @override
  String toString() => '$fieldPath ${ascending ? 'ASC' : 'DESC'}';
}

class LimitInfo {
  String? documentId;
  List? values;
  late bool inclusive; // true = At

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

class WhereInfo {
  String fieldPath;

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
        'Empty where');
    assert(arrayContainsAny == null || arrayContainsAny!.isNotEmpty,
        'Invalid Query. A non-empty array is required for \'array-contains-any\' filters.');
    assert(whereIn == null || whereIn!.isNotEmpty,
        'Invalid Query. A non-empty array is required for \'in\' filters.');
    assert(notIn == null || notIn!.isNotEmpty,
        'Invalid Query. A non-empty array is required for \'in\' filters.');
  }

  dynamic isEqualTo;
  dynamic isLessThan;
  dynamic isLessThanOrEqualTo;
  dynamic isGreaterThan;
  dynamic isGreaterThanOrEqualTo;
  dynamic arrayContains;
  List<Object>? arrayContainsAny;
  List<Object>? whereIn;
  List<Object>? notIn;
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
class QueryInfo {
  List<String>? selectKeyPaths;
  List<OrderByInfo> orderBys = [];

  LimitInfo? startLimit;
  LimitInfo? endLimit;

  int? limit;
  int? offset;
  List<WhereInfo> wheres = [];

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

  void startAt({DocumentSnapshot? snapshot, List? values}) =>
      startLimit = (LimitInfo()
        ..documentId = snapshot?.ref.id
        ..values = values
        ..inclusive = true);

  void startAfter({DocumentSnapshot? snapshot, List? values}) =>
      startLimit = (LimitInfo()
        ..documentId = snapshot?.ref.id
        ..values = values
        ..inclusive = false);

  void endAt({DocumentSnapshot? snapshot, List? values}) =>
      endLimit = (LimitInfo()
        ..documentId = snapshot?.ref.id
        ..values = values
        ..inclusive = true);

  void endBefore({DocumentSnapshot? snapshot, List? values}) =>
      endLimit = (LimitInfo()
        ..documentId = snapshot?.ref.id
        ..values = values
        ..inclusive = false);

  void addWhere(WhereInfo where) {
    wheres.add(where);
  }
}

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
    isGreaterThanOrEqualTo:
        (operator == operatorGreaterThanOrEqual) ? value : null,
    arrayContains: (operator == operatorArrayContains) ? value : null,
    arrayContainsAny: (operator == operatorArrayContainsAny)
        ? (value as List).cast<Object>()
        : null,
    whereIn: (operator == operatorIn) ? (value as List).cast<Object>() : null,
    notIn: (operator == operatorNotIn) ? (value as List).cast<Object>() : null,
  );

  return whereInfo;
}

OrderByInfo orderByInfoFromJsonMap(Map<String, Object?> map) {
  var orderByInfo = OrderByInfo(
      fieldPath: map['fieldPath'] as String?,
      ascending: (map['direction'] as String?) != orderByDescending);
  return orderByInfo;
}

const _operatorKey = 'operator';
const _valueKey = 'value';

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

Map<String, Object?> orderByInfoToJsonMap(OrderByInfo orderByInfo) {
  var map = <String, Object?>{
    'fieldPath': orderByInfo.fieldPath,
    'direction':
        orderByInfo.ascending == true ? orderByAscending : orderByDescending
  };
  return map;
}

Map<String, Object?> limitInfoToJsonMap(LimitInfo limitInfo) {
  var map = <String, Object?>{};
  if (limitInfo.inclusive == true) {
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
        .map<WhereInfo>((map) =>
            whereInfoFromJsonMap(firestore, map as Map<String, Object?>))
        .toList();
  }
  if (map.containsKey('orderBys')) {
    queryInfo.orderBys = (map['orderBys'] as List)
        .map<OrderByInfo>(
            (map) => orderByInfoFromJsonMap(map as Map<String, Object?>))
        .toList();
  }
  if (map.containsKey('selectKeyPaths')) {
    queryInfo.selectKeyPaths = (map['selectKeyPaths'] as List).cast<String>();
  }
  if (map.containsKey('startLimit')) {
    queryInfo.startLimit = limitInfoFromJsonMap(
        firestore, map['startLimit'] as Map<String, Object?>);
  }
  if (map.containsKey('endLimit')) {
    queryInfo.endLimit = limitInfoFromJsonMap(
        firestore, map['endLimit'] as Map<String, Object?>);
  }
  return queryInfo;
}

const changeTypeAdded = 'added';
const changeTypeModified = 'modified';
const changeTypeRemoved = 'removed';

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

String sanitizeReferencePath(String path) {
  if (path.startsWith('/')) {
    path = path.substring(1);
  }
  if (path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  return path;
}

bool isDocumentReferencePath(String path) {
  var count = localPathReferenceParts(path).length;
  return (count % 2) == 0;
}

bool isCollectionReferencePath(String path) => !isDocumentReferencePath(path);

abstract class WriteBatchBase implements WriteBatch {
  final List<WriteBatchOperation> operations = [];

  @override
  void delete(DocumentReference documentRef) =>
      operations.add(WriteBatchOperationDelete(documentRef));

  @override
  void set(DocumentReference documentRef, Map<String, Object?> data,
      [SetOptions? options]) {
    operations
        .add(WriteBatchOperationSet(documentRef, DocumentData(data), options));
  }

  @override
  void update(DocumentReference documentRef, Map<String, Object?> data) {
    operations.add(WriteBatchOperationUpdate(documentRef, DocumentData(data)));
  }
}

abstract class WriteBatchOperation {}

class WriteBatchOperationBase implements WriteBatchOperation {
  final DocumentReference? docRef;

  WriteBatchOperationBase(this.docRef);

  @override
  String toString() => '$runtimeType(${docRef!.path})';
}

class WriteBatchOperationDelete extends WriteBatchOperationBase {
  WriteBatchOperationDelete(DocumentReference? docRef) : super(docRef);
}

class WriteBatchOperationSet extends WriteBatchOperationBase {
  final DocumentData documentData;
  final SetOptions? options;

  WriteBatchOperationSet(
      DocumentReference docRef, this.documentData, this.options)
      : super(docRef);
}

class WriteBatchOperationUpdate extends WriteBatchOperationBase {
  final DocumentData documentData;

  WriteBatchOperationUpdate(DocumentReference docRef, this.documentData)
      : super(docRef);
}

abstract class WriteResultBase {
  final String path;

  WriteResultBase(this.path);

  bool get added => newExists && !previousExists;

  bool get removed => previousExists && !newExists;

  bool get exists => newExists;

  bool get previousExists => previousSnapshot?.exists == true;

  bool get newExists => newSnapshot?.exists == true;

  DocumentSnapshot? previousSnapshot;
  DocumentSnapshot? newSnapshot;

  bool get shouldNotify => previousExists || newExists;

  @override
  String toString() {
    return '$path added $added removed $removed old ${previousSnapshot?.exists} new ${newSnapshot?.exists}';
  }
}

class DocumentChangeBase implements DocumentChange {
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

  DocumentSnapshotBase get documentBase => document as DocumentSnapshotBase;

  @override
  String toString() => '${document.ref.path} $type $oldIndex $newIndex';
}

abstract class DocumentSnapshotBase //with DocumentSnapshotMixin
    implements
        DocumentSnapshot {
  final RecordMetaData? meta;
  @override
  final DocumentReference ref;

  int? get rev => meta?.rev;

  @override
  Timestamp? get updateTime => meta?.updateTime;

  @override
  Timestamp? get createTime => meta?.createTime;
  final DocumentData? documentData;

  late bool _exists;

  @override
  bool get exists => _exists;

  DocumentSnapshotBase(this.ref, this.meta, this.documentData, {bool? exists}) {
    _exists = exists ?? (documentData != null);
  }

  @override
  Map<String, Object?> get data => documentData!.asMap();

  @override
  SnapshotMetadata get metadata => _snapshotMetadataSembast;

  @override
  String toString() {
    return 'DocumentSnapshot(ref: $ref, exists: $exists, meta $meta)';
  }
}

/// Meta data always ok.
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

class QuerySnapshotBase implements QuerySnapshot {
  QuerySnapshotBase(this.docs, this.documentChanges);

  @override
  final List<DocumentSnapshot> docs;

  @override
  final List<DocumentChange> documentChanges;

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
Map<String, Object?> toSelectedMap(Map map, List<String> fields) {
  var selectedMap = <String, Object?>{};
  for (var key in fields) {
    if (map.containsKey(key)) {
      selectedMap[key] = map[key];
    }
  }
  return selectedMap;
}
