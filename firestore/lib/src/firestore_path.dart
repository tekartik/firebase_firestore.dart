import 'package:path/path.dart';

import 'common/reference_mixin.dart';

/// Returns the parent path of [path] (the path with its last segment
/// removed), or `null` if [path] is a root-level path with no parent (a
/// single segment, e.g. a root collection id).
String? firestorePathGetParent(String path) => getParentPathOrNull(path);

/// Returns the parent (collection) path of a document [path].
///
/// Unlike [firestorePathGetParent], this always returns a non-null path
/// since every document has a parent collection.
String firestoreDocPathGetParent(String path) => getParentPath(path);

/// Returns the parent (document) path of a collection [path], or `null` if
/// [path] is a root collection with no parent document.
String? firestoreCollPathGetParent(String path) => getParentPathOrNull(path);

/// Joins [path] and [child] into a single path, for example
/// `firestorePathGetChild('users', '123')` returns `'users/123'`.
String firestorePathGetChild(String path, String child) =>
    url.join(path, child);

/// Returns the last segment (id) of [path].
String firestorePathGetId(String path) => url.basename(path);

/// Returns [path] with its last segment replaced by [id].
///
/// If [path] has no parent (a single segment), simply returns [id].
String firestorePathReplaceId(String path, String id) {
  var parent = firestorePathGetParent(path);
  if (parent == null) {
    return id;
  }
  return firestorePathGetChild(parent, id);
}

/// Returns a generic form of [path] where every document id segment (the
/// segments at odd index, i.e. `1`, `3`, `5`, ...) is replaced by `*`, while
/// collection name segments (at even index) are left untouched.
///
/// For example `firestorePathGetGenericPath('users/123/posts/456')` returns
/// `'users/*/posts/*'`. Useful for grouping paths that share the same
/// collection structure regardless of document ids, for example when
/// defining Firestore security rules.
String firestorePathGetGenericPath(String path) => url.joinAll(
  url
      .split(path)
      .indexed
      .map<String>((item) => ((item.$1 % 2 == 0) ? item.$2 : '*')),
);
