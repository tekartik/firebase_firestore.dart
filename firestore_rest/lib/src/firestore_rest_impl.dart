import 'dart:typed_data';

import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis/firestore/v1.dart' as api;
import 'package:path/path.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/document_reference_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore/src/common/firestore_service_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore/utils/firestore_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore/utils/json_utils.dart';
import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_firestore_rest/src/collection_reference_rest.dart';
import 'package:tekartik_firebase_firestore_rest/src/document_reference_rest.dart';
import 'package:tekartik_firebase_firestore_rest/src/firebase_app_rest.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore_rest/src/query.dart';
import 'package:tekartik_http/http.dart';

import 'import.dart';

bool debugRest = false; // devWarning(true);

dynamic fromRestValue(FirestoreRestImpl firestore, Value restValue) {
  if (restValue == null) {
    return null;
  } else if (restValue.nullValue == 'NULL VALUE') {
    return null;
  } else if (restValue.stringValue != null) {
    return restValue.stringValue;
  } else if (restValue.booleanValue != null) {
    return restValue.booleanValue;
  } else if (restValue.integerValue != null) {
    return int.tryParse(restValue.integerValue);
  } else if (restValue.doubleValue != null) {
    return restValue.doubleValue;
  } else if (restValue.geoPointValue != null) {
    return GeoPoint(
        restValue.geoPointValue.latitude, restValue.geoPointValue.longitude);
  } else if (restValue.timestampValue != null) {
    return Timestamp.tryParse(restValue.timestampValue);
  } else if (restValue.mapValue != null) {
    return mapFromMapValue(firestore, restValue.mapValue);
  } else if (restValue.arrayValue != null) {
    return _listFromArrayValue(firestore, restValue.arrayValue);
  } else if (restValue.bytesValue != null) {
    return Blob(Uint8List.fromList(restValue.bytesValueAsBytes));
  } else if (restValue.referenceValue != null) {
    return DocumentReferenceRestImpl(
        firestore, firestore.getDocumentPath(restValue.referenceValue));
  } else {
    throw UnsupportedError('type ${restValue.runtimeType}: $restValue');
  }
}

Value _mapToRestValue(FirestoreRestImpl firestore, Map map) {
  var mapValue = MapValue()..fields = _mapToFields(firestore, map);
  return Value()..mapValue = mapValue;
}

Map<String, Value> _mapToFields(FirestoreRestImpl firestore, Map map) {
  if (map == null) {
    return null;
  }
  var fields = map.map(
      (key, value) => MapEntry(key?.toString(), toRestValue(firestore, value)));
  return fields;
}

Map<String, dynamic> mapFromMapValue(
    FirestoreRestImpl firestore, MapValue mapValue) {
  if (mapValue != null) {
    return mapFromFields(firestore, mapValue.fields) ?? <String, dynamic>{};
  }
  return null;
}

Map<String, dynamic> mapFromFields(
    FirestoreRestImpl firestore, Map<String, Value> fields) {
  if (fields == null) {
    return null;
  }
  var map = fields.map((key, value) =>
      MapEntry(key.toString(), fromRestValue(firestore, value)));
  return map;
}

Value _listToRestValue(FirestoreRestImpl firestore, Iterable list) {
  var arrayValue = ArrayValue()
    ..values = list
        .map((value) => toRestValue(firestore, value))
        ?.toList(growable: false);
  return Value()..arrayValue = arrayValue;
}

List<dynamic> _listFromArrayValue(
    FirestoreRestImpl firestore, ArrayValue arrayValue) {
  var list = arrayValue?.values
      ?.map((restValue) => fromRestValue(firestore, restValue))
      ?.toList(growable: false);
  return list;
}

Value toRestValue(FirestoreRestImpl firestore, dynamic value) {
  Value restValue;
  if (value == null) {
    restValue = Value()..nullValue = 'NULL_VALUE';
  } else if (value is String) {
    restValue = Value()..stringValue = value;
  } else if (value is bool) {
    restValue = Value()..booleanValue = value;
  } else if (value is int) {
    restValue = Value()..integerValue = value.toString();
  } else if (value is double) {
    restValue = Value()..doubleValue = value;
  } else if (value is GeoPoint) {
    var geoPointValue = LatLng()
      ..latitude = value.latitude?.toDouble()
      ..longitude = value.longitude?.toDouble();
    restValue = Value()..geoPointValue = geoPointValue;
  } else if (value is Timestamp) {
    restValue = Value()..timestampValue = value.toString();
  } else if (value is DateTime) {
    restValue = Value()
      ..timestampValue = Timestamp.fromDateTime(value).toIso8601String();
  } else if (value is Map) {
    restValue = _mapToRestValue(firestore, value);
  } else if (value is Iterable) {
    restValue = _listToRestValue(firestore, value);
  } else if (value is Blob) {
    restValue = Value()..bytesValueAsBytes = value.data;
  } else if (value is DocumentReference) {
    restValue = Value()..referenceValue = firestore.getDocumentName(value.path);
    // else  if (value is FieldValue) {
    //restValue = Value()..nullValue= 'NULL_VALUE';
  } else if (value is FieldValue) {
    if (value == FieldValue.serverTimestamp) {
      // TODO for now use local date time
      restValue = Value()..timestampValue = Timestamp.now().toIso8601String();
    } else {
      throw UnsupportedError('type ${value.runtimeType}: $value');
    }
  } else {
    throw UnsupportedError('type ${value.runtimeType}: $value');
  }
  return restValue;
}

class FirestoreRestImpl with FirestoreMixin implements Firestore {
  final AppRestImpl appImpl;

  String get projectId => appImpl.options.projectId;

  FirestoreRestImpl(this.appImpl) {
    assert(projectId != null);
  }

  @override
  WriteBatch batch() {
    // TODO: implement batch
    return null;
  }

  @override
  CollectionReference collection(String path) {
    return CollectionReferenceRestImpl(this, path);
  }

  // join('projects/${projectId}/databases/(default)/documents', path);
  String getDocumentName(String path) {
    return url.join('${getDatabaseName()}', 'documents', path);
  }

  String getDocumentPath(String name) {
    var parts = url.split(name);
    return url.joinAll(parts.sublist(5));
  }

  // 'projects/${projectId}/databases/(default)';
  String getDatabaseName() {
    return url.join('projects', projectId, 'databases', '(default)');
  }

  @override
  DocumentReference doc(String path) {
    return DocumentReferenceRestImpl(this, path);
  }

  Future<DocumentSnapshot> getDocument(String path) async {
    path = getDocumentName(path);
    try {
      var document =
          await appImpl.firestoreApi.projects.databases.documents.get(path);
      // devPrint(jsonPretty(document.toJson()));
      return DocumentSnapshotRestImpl(this, document);
    } catch (e) {
      if (e is api.DetailedApiRequestError) {
        // devPrint(e.status);
        if (e.status == httpStatusCodeNotFound) {
          return DocumentSnapshotRestImpl(this, null);
        }
      }
      rethrow;
    }
  }

  Future deleteDocument(String path) async {
    if (debugRest) {
      print('delete $path');
    }
    var name = getDocumentName(path);
    try {
      await appImpl.firestoreApi.projects.databases.documents.delete(name);
    } catch (e) {
      if (e is api.DetailedApiRequestError) {
        return;
      }
      rethrow;
    }
  }

  FirestoreApi get firestoreApi => appImpl.firestoreApi;

  @override
  Future<List<DocumentSnapshot>> getAll(List<DocumentReference> refs) async {
    /// Temp do in a loop
    var list = <DocumentSnapshot>[];
    for (var ref in refs) {
      list.add(await getDocument(ref.path));
    }
    return list;
    /*
    var request = BatchGetDocumentsRequest()
      ..documents =
          refs.map((ref) => getDocumentName(ref.path)).toList(growable: false);
    var response = await firestoreApi.projects.databases.documents
        .batchGet(request, getDatabaseName());
    devPrint('resp: ${response.toJson()}');
    return [];

     */
  }

  @override
  Future runTransaction(Function(Transaction transaction) updateFunction) {
    // TODO: implement runTransaction
    return null;
  }

  String get baseUri =>
      'https://firestore.googleapis.com/v1beta1/${projectId}/tekartik-free-dev/databases/(default)';

  String getUriPath(String path) {
    return url.join(baseUri, path);
  }

  Future<DocumentReference> createDocument(
      String path, Map<String, dynamic> data) async {
    var document = Document()..fields = _mapToFields(this, data);

    var parent = url.dirname(getDocumentName(path));
    var collectionId = getPathId(path);
    document = await firestoreApi.projects.databases.documents
        .createDocument(document, parent, collectionId);
    // devPrint(result);
    return DocumentReferenceRestImpl(this, document.name);
  }

  Future<DocumentReference> patchDocument(
      String path, Map<String, dynamic> data) async {
    var document = Document()..fields = _mapToFields(this, data);
    document = await firestoreApi.projects.databases.documents
        .patch(document, getDocumentName(path));
    return DocumentReferenceRestImpl(this, path);
  }

  Future<DocumentReference> updateDocument(
      String path, Map<String, dynamic> data) async {
    var document = Document()..fields = _mapToFields(this, data);
    document = await firestoreApi.projects.databases.documents
        .patch(document, getDocumentName(path), currentDocument_exists: true);
    return DocumentReferenceRestImpl(this, path);
  }

  Filter whereToFilter(WhereInfo whereInfo) {
    if (whereInfo.isNull == true) {
      return Filter()
        ..unaryFilter = (UnaryFilter()
          ..field = (FieldReference()..fieldPath = whereInfo.fieldPath)
          ..op = 'IS_NULL');
    }
    String op;
    dynamic value;
    if (whereInfo.isEqualTo != null) {
      op = 'EQUAL';
      value = whereInfo.isEqualTo;
    }
    if (op != null && value != null) {
      return Filter()
        ..fieldFilter = (FieldFilter()
          ..field = (FieldReference()..fieldPath = whereInfo.fieldPath)
          ..op = op
          ..value = toRestValue(this, value));
    }
    throw 'filter $whereInfo not supported';
  }

  StructuredQuery toStructuredQuery(QueryRestImpl queryRestImpl) {
    var queryInfo = queryRestImpl.queryInfo;
    var structuredQuery = StructuredQuery();
    if (queryInfo?.wheres?.isNotEmpty ?? false) {
      if (queryInfo.wheres.length == 1) {
        structuredQuery.where = whereToFilter(queryInfo.wheres.first);
      } else {
        structuredQuery.where = Filter()
          ..compositeFilter = (CompositeFilter()
            ..op = 'AND'
            ..filters = queryInfo.wheres
                .map((whereInfo) => whereToFilter(whereInfo))
                .toList(growable: false));
      }
    }
    return structuredQuery;
  }

  Future<QuerySnapshot> runQuery(QueryRestImpl queryRestImpl) async {
    var structuredQuery = toStructuredQuery(queryRestImpl);

    var request = RunQueryRequest()..structuredQuery = structuredQuery;
    // devPrint(request.toJson());
    var parent = url.dirname(getDocumentName(queryRestImpl.path));
    await firestoreApi.projects.databases.documents.runQuery(request, parent);
    // devPrint(response.document.toJson());
    return null;
  }
}

class FirestoreServiceRestImpl
    with FirestoreServiceMixin
    implements FirestoreServiceRest {
  @override
  Firestore firestore(App app) {
    // TODO: implement firestore
    return FirestoreRestImpl(app as AppRestImpl);
  }

  @override
  bool get supportsDocumentSnapshotTime => true;

  @override
  // TODO: implement supportsFieldValueArray
  bool get supportsFieldValueArray => null;

  @override
  // TODO: implement supportsQuerySelect
  bool get supportsQuerySelect => null;

  @override
  // TODO: implement supportsQuerySnapshotCursor
  bool get supportsQuerySnapshotCursor => null;

  @override
  bool get supportsTimestamps => true;

  @override
  bool get supportsTimestampsInSnapshots => true;

  @override
  bool get supportsTrackChanges => false;
}
