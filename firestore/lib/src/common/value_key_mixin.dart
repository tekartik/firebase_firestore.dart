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

/// Expand first level keys
Map expandUpdateData(Map value) {
  var expanded = <String, dynamic>{};
  value?.forEach((k, v) {
    var key = k as String;
    var parts = getFieldParts(key);
    if (parts.length > 1) {
      var first = parts.first;
      var child = <String, dynamic>{};
      expanded[first] = child;

      var currentChild = child;
      for (int i = 1; i < parts.length; i++) {
        if (i < parts.length - 1) {
          var part = parts[i];
          var newChild = <String, dynamic>{};
          currentChild[part] = newChild;
          currentChild = newChild;
        } else {
          var part = parts.last;
          currentChild[part] = v;
        }
      }
    } else {
      expanded[key] = v;
    }
  });
  return expanded;
  /*
  allowDotsInKeys ??= false;

  if (newValue == null) {
    return existingValue;
  }

  if (!(existingValue is Map)) {
    return _fixValue(newValue);
  }
  if (!(newValue is Map)) {
    return newValue;
  }

  Map<String, dynamic> mergedMap =
  cloneValue(existingValue) as Map<String, dynamic>;
  Map currentMap = mergedMap;

  // Here we have the new key and values to merge
  void merge(key, value) {
    String stringKey = key as String;
    // Handle a.b.c or `` `a.b.c` ``
    List<String> keyParts;
    if (allowDotsInKeys) {
      keyParts = [stringKey];
    } else {
      keyParts = getFieldParts(stringKey);
    }
    if (keyParts.length == 1) {
      stringKey = keyParts[0];
      // delete the field?
      if (value == FieldValue.delete) {
        currentMap.remove(stringKey);
      } else {
        // Replace the content. We don't want to merge here since we are the
        // last part of the path specification
        currentMap[stringKey] = value;
      }
    } else {
      if (value == FieldValue.delete) {
        Map map = currentMap;
        for (String part in keyParts.sublist(0, keyParts.length - 1)) {
          dynamic sub = map[part];
          if (sub is Map) {
            map = sub;
          } else {
            map = null;
            break;
          }
        }
        if (map != null) {
          map.remove(keyParts.last);
        }
      } else {
        Map map = currentMap;
        for (String part in keyParts.sublist(0, keyParts.length - 1)) {
          dynamic sub = map[part];
          if (sub is Map) {
            map = sub;
          } else {
            // create sub part
            sub = <String, dynamic>{};
            map[part] = sub;
            map = sub as Map;
          }
        }
        var previousMap = currentMap;
        currentMap = map;
        merge(keyParts.last, value);
        currentMap = previousMap;
      }
    }
  }

  (newValue as Map).forEach(merge);
  return mergedMap;
  */
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
