import 'dart:convert';

import 'package:path/path.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_firestore/src/firestore.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore/firestore.dart';

String _basePath(App app) {
  return "projects/${app.options?.projectId}/databases/(default)/documents";
}

Map<String, dynamic> documentDataToJson(App app, DocumentData data,
    {Map<String, dynamic> map}) {
  if (data == null) {
    return null;
  }
  map ??= <String, dynamic>{};
  map['fields'] = (data as DocumentDataMap).map.map<String, dynamic>(
      (key, value) => MapEntry(key, documentDataValueToJson(app, value)));
  return map;
}

Map<String, dynamic> snapshotToJson(App app, DocumentSnapshot snapshot) {
  if (!snapshot.exists) {
    return null;
  }
  var map = <String, dynamic>{
    'name': url.join(_basePath(app), snapshot.ref.path)
  };
  map = documentDataToJson(app, DocumentData(snapshot.data), map: map);
  map['createTime'] = snapshot.createTime?.toIso8601String();
  map['updateTime'] = snapshot.updateTime?.toIso8601String();
  return map;
}

DocumentData documentDataFromSnapshot(DocumentSnapshot snapshot) =>
    snapshot?.exists == true ? DocumentData(snapshot.data) : null;

dynamic documentDataValueToJson(App app, dynamic value) {
  if (value is String) {
    return <String, dynamic>{'stringValue': value};
  } else if (value is int) {
    return <String, dynamic>{'integerValue': value.toString()};
  } else if (value is num) {
    return <String, dynamic>{'doubleValue': value};
  } else if (value is bool) {
    return <String, dynamic>{'booleanValue': value};
  } else if (value is List) {
    return <String, dynamic>{
      'arrayValue': {
        'values':
            value.map((value) => documentDataValueToJson(app, value)).toList()
      }
    };
  } else if (value is Map) {
    return <String, dynamic>{
      'mapValue': {
        'fields': value.map<String, dynamic>((key, value) =>
            MapEntry(key as String, documentDataValueToJson(app, value)))
      }
    };
  } else if (value is DocumentData) {
    // Handle this that could happen from a map
    return documentDataValueToJson(app, (value as DocumentDataMap).map);
  } else if (value is DateTime) {
    return <String, dynamic>{'timestampValue': value.toUtc().toIso8601String()};
  } else if (value is Timestamp) {
    return <String, dynamic>{'timestampValue': value.toIso8601String()};
  } else if (value is DocumentReference) {
    return <String, dynamic>{
      "referenceValue": url.join(_basePath(app), value.path)
    };
  } else if (value is Blob) {
    return <String, dynamic>{'bytesValue': base64.encode(value.data)};
  } else if (value is GeoPoint) {
    return <String, dynamic>{
      'geoPointValue': {
        'latitude': value.latitude,
        'longitude': value.longitude
      }
    };
  } else {
    throw ArgumentError.value(value, "${value.runtimeType}",
        "Unsupported value for documentDataValueToJson");
  }
}
