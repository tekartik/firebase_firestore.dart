import 'package:tekartik_firebase_firestore/firestore.dart';

/// Backtick char code.
final backtickChrCode = '`'.codeUnitAt(0);

/// Check if a trick is enclosed by backticks
bool isBacktickEnclosed(String field) {
  final length = field?.length ?? 0;
  if (length < 2) {
    return false;
  }
  return field.codeUnitAt(0) == backtickChrCode &&
      field.codeUnitAt(length - 1) == backtickChrCode;
}

/// For merged values and filters
List<String> getFieldParts(String field) {
  if (isBacktickEnclosed(field)) {
    return [_unescapeKey(field)];
  }
  return getRawFieldParts(field);
}

String _unescapeKey(String field) => field.substring(1, field.length - 1);

/// Get field segments.
List<String> getRawFieldParts(String field) => field.split('.');

Map<String, dynamic> sanitizeInputEntry(Map map) {
  if (map == null) {
    return null;
  }
  var sanitized = <String, dynamic>{};
  map.forEach((k, v) {
    sanitized =
        mergeSanitizedMap(sanitized, sanitizeInputEntryKey(k as String, v));
  });
  return sanitized;
}

Map<String, dynamic> sanitizeInputEntryKey(String key, dynamic value) {
  var sanitized = <String, dynamic>{};
  var parts = getFieldParts(key);
  // var value = map[key];
  //if (parts.length == 1) {
  //  return <String, dynamic>{key: map[key]};
  //}
  Map<String, dynamic> currentChild = sanitized;

  for (int i = 0; i < parts.length; i++) {
    var part = parts[i];
    if (i < parts.length - 1) {
      var newChild = <String, dynamic>{};
      currentChild[part] = newChild;
      currentChild = newChild;
    } else {
      currentChild[part] = value;
    }
  }

  return sanitized;
}

/// Expand first level keys
Map expandUpdateData(Map value) {
  return sanitizeInputEntry(value);
}

String _escapeKey(String field) => '`$field`';

/// Escape a key.
String escapeKey(String field) {
  if (field == null) {
    return null;
  }
  if (isBacktickEnclosed(field)) {
    return _escapeKey(field);
  } else if (field.contains('.')) {
    return _escapeKey(field);
  }
  return field;
}

/// Clone a value.
///
/// No test on the value type
dynamic cloneValue(dynamic value) {
  if (value is Map) {
    return value.map<String, dynamic>(
        (key, value) => MapEntry(key as String, cloneValue(value)));
  }
  if (value is Iterable) {
    return value.map((value) => cloneValue(value)).toList();
  }
  return value;
  /*
  if (value is String) {
    return value;
  }
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value;
  }
  if (value == null) {
    return value;
  }
  throw ArgumentError(
      "value ${value} unsupported${value != null ? ' type ${value.runtimeType}' : ''}");

   */
}

Map<String, dynamic> _fixMap(Map map) {
  var fixedMap = <String, dynamic>{};
  map.forEach((key, value) {
    if (value != FieldValue.delete) {
      fixedMap[key as String] = _fixValue(value);
    }
  });
  return fixedMap;
}

dynamic _fixValue(dynamic value) {
  if (value is Map) {
    return _fixMap(value);
  }
  return value;
}

/// Merge an existing value with a new value, Map only!
Map<String, dynamic> mergeSanitizedMap(Map existingValue, Map newValue) {
//  allowDotsInKeys ??= false;

  if (newValue == null) {
    return existingValue?.cast<String, dynamic>();
  }

  Map<String, dynamic> mergedMap =
      cloneValue(existingValue) as Map<String, dynamic>;
  Map currentMap = mergedMap;
  Map currentExistingMap = currentMap;
  Map currentMergedMap = newValue;

  // Here we have the new key and values to merge
  void merge(key, value) {
    String stringKey = key as String;

    void _keep() {
      currentMap[key] = value;
    }

    if (value is Map) {
      var existing = currentExistingMap[stringKey];
      if (existing is Map) {
        var newValue = mergeSanitizedMap(existing, value);
        currentMap[key] = newValue;
      } else {
        _keep();
      }
    } else {
      _keep();
    }
  }

  currentMergedMap.forEach(merge);
  return mergedMap;
}
