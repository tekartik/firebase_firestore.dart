import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore/v1beta1.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart';

abstract class FirestoreDocumentContext {
  FirestoreRestImpl get impl;

  // Full name
  String getDocumentName(String path);
  // Path below documents
  String getDocumentPath(String name);
}

mixin DocumentContext {
  FirestoreDocumentContext get firestore;

  Value toRestValue(dynamic value) {
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
      restValue = _mapToRestValue(value);
    } else if (value is Iterable) {
      restValue = _listToRestValue(value);
    } else if (value is Blob) {
      restValue = Value()..bytesValueAsBytes = value.data;
    } else if (value is DocumentReference) {
      restValue = Value()
        ..referenceValue = firestore.getDocumentName(value.path);
      // else  if (value is FieldValue) {
      //restValue = Value()..nullValue= 'NULL_VALUE';
    } else if (value is FieldValue) {
      if (value == FieldValue.serverTimestamp) {
        // TODO for now use local date time
        restValue = Value()..timestampValue = Timestamp.now().toIso8601String();
      } else {
        throw UnsupportedError('type ${value.runtimeType}: $value');
      }

      //      throw UnsupportedError('type ${value.runtimeType}: $value');
    } else {
      throw UnsupportedError('type ${value.runtimeType}: $value');
    }
    return restValue;
  }

  Value _mapToRestValue(Map map) {
    var mapValue = MapValue()..fields = _mapToFields(map);
    return Value()..mapValue = mapValue;
  }

  Map<String, Value> _mapToFields(Map map) {
    if (map == null) {
      return null;
    }
    var fields =
        map.map((key, value) => MapEntry(key?.toString(), toRestValue(value)));
    return fields;
  }

  void fromMap(Map map) {
    if (map == null) {
      return null;
    }
    map.map((key, value) => MapEntry(key?.toString(), toRestValue(value)));
  }

  Value _listToRestValue(Iterable list) {
    var arrayValue = ArrayValue()
      ..values =
          list.map((value) => toRestValue(value))?.toList(growable: false);
    return Value()..arrayValue = arrayValue;
  }
}
