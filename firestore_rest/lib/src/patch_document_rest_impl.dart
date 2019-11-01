import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_rest/src/document_rest_impl.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart';
import 'package:path/path.dart';

import 'firestore/v1beta1.dart';

class PatchDocument with DocumentContext {
  @override
  final FirestoreDocumentContext firestore;
  final document = Document();
  List<String> fieldPaths;
  Map<String, Value> _fields;

  PatchDocument(this.firestore, Map data) {
    _fromMap(data);
    document.fields = _fields;

    // add all other field name
    if (_fields != null) {
      fieldPaths ??= [];
      fieldPaths.addAll(_fields.keys);
    }
  }

  Map<String, Value> get fields => document.fields;

  void _fromMap(Map map) {
    if (map == null) {
      return null;
    }
    _currentParent = null;
    _fields = _mapToFields(null, map);
  }

  String _currentParent;
  Value patchToRestValue(String key, dynamic value) {
    var me = _currentParent == null ? key : url.join(_currentParent, key);

    if (value is Map) {
      return _pathMapToRestValue(me, value);
    }

    return super.toRestValue(value);
  }

  Map<String, Value> _mapToFields(String me, Map map) {
    if (map == null) {
      return null;
    }
    var fields = <String, Value>{};
    map.forEach((key, value) {
      String stringKey = key.toString();

      if (value == FieldValue.delete) {
        // Don't set it  in the fileds but add
        // it to fieldPaths.
        fieldPaths ??= [];
        fieldPaths.add(pathJoin(me, stringKey));
      } else {
        fields[stringKey] = patchToRestValue(stringKey, value);
      }
    });
    return fields;
  }

  Value _pathMapToRestValue(String me, Map value) {
    var oldCurrent = _currentParent;
    try {
      _currentParent = me;
      return _mapToRestValue(me, value);
    } finally {
      _currentParent = oldCurrent;
    }
  }

  Value _mapToRestValue(String me, Map map) {
    var mapValue = MapValue()..fields = _mapToFields(me, map);
    return Value()..mapValue = mapValue;
  }
}
