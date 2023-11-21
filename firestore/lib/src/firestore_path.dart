import 'package:path/path.dart';

import 'common/reference_mixin.dart';

/// Get a parent path or null.
String? firestorePathGetParent(String path) => getParentPathOrNull(path);

/// Get a doc parent path.
String firestoreDocPathGetParent(String path) => getParentPath(path);

/// Get a cool parent path.
String? firestoreCollPathGetParent(String path) => getParentPathOrNull(path);

/// Child path
String firestorePathGetChild(String path, String child) =>
    url.join(path, child);

/// Replace last path segment
String firestorePathReplaceId(String path, String id) {
  var parent = firestorePathGetParent(path);
  if (parent == null) {
    return id;
  }
  return firestorePathGetChild(parent, id);
}

/// Get a parent as a generic path, replacing id by *
String firestorePathGetGenericPath(String path) => url.joinAll(url
    .split(path)
    .indexed
    .map<String>((item) => ((item.$1 % 2 == 0) ? item.$2 : '*')));
