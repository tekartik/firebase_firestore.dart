import 'package:tekartik_firebase_firestore/firestore.dart';

/// Backtick char code.
final backtickChrCode = '`'.codeUnitAt(0);

/// Check if a trick is enclosed by backticks
bool isBacktickEnclosed(String field) {
  final length = field.length;
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

/// Sanitize a map
Map<String, Object?>? sanitizeInputEntry(Map map) {
  Map<String, Object?>? sanitized = <String, Object?>{};
  map.forEach((k, v) {
    sanitized =
        mergeSanitizedMap(sanitized, sanitizeInputEntryKey(k as String, v));
  });
  return sanitized;
}

/// Sanitize a map entry
Map<String, Object?> sanitizeInputEntryKey(String key, dynamic value) {
  var sanitized = <String, Object?>{};
  var parts = getFieldParts(key);
  // var value = map[key];
  //if (parts.length == 1) {
  //  return <String, Object?>{key: map[key]};
  //}
  var currentChild = sanitized;

  for (var i = 0; i < parts.length; i++) {
    var part = parts[i];
    if (i < parts.length - 1) {
      var newChild = <String, Object?>{};
      currentChild[part] = newChild;
      currentChild = newChild;
    } else {
      currentChild[part] = value;
    }
  }

  return sanitized;
}

/// Expand first level keys
Map<String, Object?>? expandUpdateData(Map value) {
  return sanitizeInputEntry(value);
}

String _escapeKey(String field) => '`$field`';

/// Escape a key.
String escapeKey(String field) {
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
    return value.map<String, Object?>(
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

Map<String, Object?> _fixMap(Map map) {
  var fixedMap = <String, Object?>{};
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
Map<String, Object?>? mergeSanitizedMap(Map? existingValue, Map? newValue) {
//  allowDotsInKeys ??= false;

  if (newValue == null) {
    return existingValue?.cast<String, Object?>();
  }

  final mergedMap = cloneValue(existingValue) as Map<String, Object?>?;
  final currentMap = mergedMap;
  final currentExistingMap = currentMap;
  final currentMergedMap = newValue;

  // Here we have the new key and values to merge
  void merge(dynamic key, dynamic value) {
    final stringKey = key.toString();

    void keep() {
      currentMap![stringKey] = value;
    }

    if (value is Map) {
      var existing = currentExistingMap![stringKey];
      if (existing is Map) {
        var newValue = mergeSanitizedMap(existing, value);
        currentMap![stringKey] = newValue;
      } else {
        keep();
      }
    } else {
      keep();
    }
  }

  currentMergedMap.forEach(merge);
  return mergedMap;
}
