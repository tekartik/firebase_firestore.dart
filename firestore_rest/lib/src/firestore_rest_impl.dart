import 'dart:typed_data';

import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis/firestore/v1.dart' as api;
import 'package:path/path.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/document_reference_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore/src/common/firestore_service_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore/utils/firestore_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_firestore_rest/src/collection_reference_rest.dart';
import 'package:tekartik_firebase_firestore_rest/src/document_reference_rest.dart';
import 'package:tekartik_firebase_firestore_rest/src/firebase_app_rest.dart'; // ignore: implementation_imports
import 'package:tekartik_http/http.dart';

import 'import.dart';

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
    return mapFromFields(firestore, restValue.mapValue.fields);
  } else if (restValue.arrayValue != null) {
    return _listFromArrayValue(firestore, restValue.arrayValue);
  } else if (restValue.bytesValue != null) {
    return Blob(Uint8List.fromList(restValue.bytesValueAsBytes));
  } else if (restValue.referenceValue != null) {
    return DocumentReferenceRestImpl(firestore, restValue.referenceValue);
  } else {
    throw UnsupportedError('type ${restValue.runtimeType}: $restValue');
  }
}

Value _mapToRestValue(FirestoreRestImpl firestore, Map map) {
  var mapValue = MapValue()..fields = _mapToFields(firestore, map);
  return Value()..mapValue = mapValue;
}

Map<String, Value> _mapToFields(FirestoreRestImpl firestore, Map map) {
  var fields = map.map(
      (key, value) => MapEntry(key?.toString(), toRestValue(firestore, value)));
  return fields;
}

Map<String, dynamic> mapFromFields(
    FirestoreRestImpl firestore, Map<String, Value> fields) {
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
    restValue = Value()..referenceValue = firestore.toReferencePath(value.path);
    // else  if (value is FieldValue) {
    //restValue = Value()..nullValue= 'NULL_VALUE';
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

  String toReferencePath(String path) {
    return url.join(
        'projects/${projectId}/databases/(default)/documents', path);
  }

  @override
  DocumentReference doc(String path) {
    return DocumentReferenceRestImpl(this, path);
  }

  Future<DocumentSnapshot> getDocument(String path) async {
    path = toReferencePath(path);
    try {
      var document =
          await appImpl.firestoreApi.projects.databases.documents.get(path);
      // devPrint(document);
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

  @override
  Future<List<DocumentSnapshot>> getAll(List<DocumentReference> refs) {
    // TODO: implement getAll
    return null;
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

    var parent = url.dirname(toReferencePath(path));
    var collectionId = getPathId(path);
    document = await appImpl.firestoreApi.projects.databases.documents
        .createDocument(document, parent, collectionId);
    // devPrint(result);
    return DocumentReferenceRestImpl(this, document.name);
  }

  Future<DocumentReference> patchDocument(
      String path, Map<String, dynamic> data) async {
    var document = Document()..fields = _mapToFields(this, data);
    document = await appImpl.firestoreApi.projects.databases.documents
        .patch(document, toReferencePath(path));
    return DocumentReferenceRestImpl(this, path);
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
  // TODO: implement supportsDocumentSnapshotTime
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
}
