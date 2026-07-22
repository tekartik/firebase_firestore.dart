import 'package:tekartik_firebase_firestore/firestore.dart';

/// The character code of the backtick (`` ` ``) character, used to escape
/// field names that contain a literal `.`.
final backtickChrCode = '`'.codeUnitAt(0);

/// Returns `true` if [field] is enclosed in a single pair of backticks
/// (`` `like.this` ``), used to escape a field name containing a literal
/// `.` so it isn't split into nested-field segments.
bool isBacktickEnclosed(String field) {
  final length = field.length;
  if (length < 2) {
    return false;
  }
  return field.codeUnitAt(0) == backtickChrCode &&
      field.codeUnitAt(length - 1) == backtickChrCode;
}

/// Splits a field path [field] into its nested-key segments, honoring
/// backtick-escaping (see [isBacktickEnclosed]): a backtick-enclosed field
/// is treated as a single segment even if it contains `.`, otherwise it is
/// split on `.` via [getRawFieldParts]. Used when building merged update
/// maps and query filters.
List<String> getFieldParts(String field) {
  if (isBacktickEnclosed(field)) {
    return [_unescapeKey(field)];
  }
  return getRawFieldParts(field);
}

String _unescapeKey(String field) => field.substring(1, field.length - 1);

/// Splits [field] into segments on `.`, without any backtick handling.
List<String> getRawFieldParts(String field) => field.split('.');

/// Expands every dotted-path key of [map] (e.g. `'a.b'`) into nested maps
/// (`{'a': {'b': ...}}`), merging entries that share a prefix.
///
/// Returns the sanitized map, or an empty map if [map] is empty.
Map<String, Object?>? sanitizeInputEntry(Map map) {
  Map<String, Object?>? sanitized = <String, Object?>{};
  map.forEach((k, v) {
    sanitized = mergeSanitizedMap(
      sanitized,
      sanitizeInputEntryKey(k as String, v),
    );
  });
  return sanitized;
}

/// Expands a single dotted-path [key] (e.g. `'a.b'`) associated with
/// [value] into a nested map (`{'a': {'b': value}}`), per [getFieldParts].
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

/// Expands every dotted-path key of the top-level update map [value] (e.g.
/// `'a.b'`) into nested maps, as an alias for [sanitizeInputEntry].
Map<String, Object?>? expandUpdateData(Map value) {
  return sanitizeInputEntry(value);
}

String _escapeKey(String field) => '`$field`';

/// Wraps [field] in backticks if it needs escaping (is already
/// backtick-enclosed, or contains a literal `.`), so it round-trips through
/// [getFieldParts] as a single segment. Returns [field] unchanged otherwise.
String escapeKey(String field) {
  if (isBacktickEnclosed(field)) {
    return _escapeKey(field);
  } else if (field.contains('.')) {
    return _escapeKey(field);
  }
  return field;
}

/// Recursively deep-clones [value].
///
/// [Map]s and [Iterable]s are cloned into new `Map<String, Object?>`/`List`
/// instances (with elements cloned recursively); every other value is
/// returned unchanged (no type checking is performed on leaf values).
dynamic cloneValue(dynamic value) {
  if (value is Map) {
    return value.map<String, Object?>(
      (key, value) => MapEntry(key as String, cloneValue(value)),
    );
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

/// Recursively merges [newValue] onto a clone of [existingValue] (maps
/// only): nested maps are merged key by key, other values in [newValue]
/// replace the corresponding entry, and a value equal to [FieldValue.delete]
/// removes the corresponding key instead.
///
/// Returns a clone of [existingValue] (cast to `Map<String, Object?>`) when
/// [newValue] is `null`; returns `null` when both are `null`.
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
