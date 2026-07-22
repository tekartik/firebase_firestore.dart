import 'package:path/path.dart';
import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/firestore_common.dart';

/// A location identified by a slash-separated [path], shared by document and
/// collection references.
abstract class PathReference {
  /// The full, slash-separated path to this location.
  String get path;

  /// The path of the parent location, or `null` if [path] has no parent
  /// (a single, root-level segment).
  String? get parentPath;

  /// The last segment of [path].
  String get id;

  /// Joins [path] and [child] into a single path.
  String getChildPath(String child);
}

/// A [PathReference] bound to a specific [Firestore] instance.
abstract class FirestorePathReference extends PathReference {
  /// The [Firestore] instance this reference belongs to.
  Firestore get firestore;
}

/// Implementation helper mixin storing the [firestore]/[path] pair backing a
/// [FirestorePathReference], for implementations that need mutable,
/// late-initialized storage rather than constructor-injected fields.
mixin PathReferenceImplMixin implements FirestorePathReference {
  late Firestore _firestore;
  late String _path;

  @override
  Firestore get firestore => _firestore;

  @override
  String get path => _path;

  /// Initializes this reference with the given [firestore] instance and
  /// [path]. Must be called before [firestore] or [path] are read.
  void init(Firestore firestore, String path) {
    _firestore = firestore;
    _path = path;
  }
}

/// [PathReference] mixin deriving [parentPath], [id] and [getChildPath] from
/// [path] alone, using `/`-based path semantics (via `package:path`'s `url`
/// style).
mixin PathReferenceMixin implements PathReference {
  /// Parent path.
  @override
  String? get parentPath => getParentPathOrNull(path);

  @override
  String get id => getPathId(path);

  /// Child path
  @override
  String getChildPath(String child) => url.join(path, child);

  @override
  String toString() => 'path: $path';
}

/// Returns the parent path of [path] (the path with its last segment
/// removed).
///
/// Throws if [path] has no parent (a single, root-level segment); use
/// [getParentPathOrNull] for a null-safe alternative.
String getParentPath(String path) {
  return getParentPathOrNull(path)!;
}

/// Returns the parent path of [path] (the path with its last segment
/// removed), or `null` if [path] is a single, root-level segment with no
/// parent.
String? getParentPathOrNull(String path) {
  var dirname = url.dirname(path);
  if (dirname == '.' || dirname == '/') {
    return null;
  }
  return dirname;
}

/// Returns the last segment (id) of [path].
String getPathId(String path) => url.basename(path);

/// [CollectionReference] mixin providing [parent], [doc], equality and
/// [hashCode] purely from [path] and [firestore], for backends that don't
/// need any other shared state.
mixin CollectionReferenceMixin
    implements CollectionReference, PathReferenceMixin, FirestorePathReference {
  @override
  DocumentReference? get parent {
    var parentPath = this.parentPath;
    return parentPath == null ? null : firestore.doc(parentPath);
  }

  @override
  DocumentReference doc(String path) => firestore.doc(getChildPath(path));

  @override
  int get hashCode => path.hashCode;

  @override
  bool operator ==(other) {
    if (other is CollectionReferenceMixin) {
      /*
      No longer check firestore to support logger
      if (firestore != (other).firestore) {
        return false;
      }
       */
      if (path != (other).path) {
        return false;
      }
      return true;
    }
    return false;
  }
}

/// [DocumentReference] mixin providing a [listCollections] implementation
/// that always throws [UnimplementedError], for backends that don't support
/// listing sub-collections.
mixin DocumentReferenceDefaultMixin implements DocumentReference {
  @override
  Future<List<CollectionReference>> listCollections() {
    throw UnimplementedError();
  }
}

/// [DocumentReference] mixin providing [parent], [collection], equality and
/// [hashCode] purely from [FirestorePathReference.path] and
/// [FirestorePathReference.firestore], for backends that don't need any
/// other shared state.
mixin DocumentReferenceMixin
    implements DocumentReference, FirestorePathReference {
  @override
  CollectionReference get parent {
    var parentPath = this.parentPath!;
    return firestore.collection(parentPath);
  }

  @override
  CollectionReference collection(String path) =>
      firestore.collection(getChildPath(path));

  @override
  int get hashCode => path.hashCode;

  @override
  bool operator ==(other) {
    if (other is DocumentReference) {
      /*
      No longer check firestore to support logger
      if (firestore != (other).firestore) {
        return false;
      }*/
      if (path != (other).path) {
        return false;
      }
      return true;
    }
    return false;
  }
}

/// Splits [path] into its `/`-separated segments, stripping a leading
/// `projects/<project>/databases/(default)/documents` prefix if present
/// (as returned by some backend's fully-qualified resource names).
List<String> localPathReferenceParts(String path) {
  var parts = url.split(sanitizeReferencePath(path));
  if (parts.length > 6 &&
      parts[0] == 'projects' &&
      parts[2] == 'databases' &&
      parts[4] == 'documents') {
    parts = parts.sublist(5);
  }
  return parts;
}

/// Returns [path] with a leading
/// `projects/<project>/databases/(default)/documents` prefix stripped, if
/// present (as returned by some backend's fully-qualified resource names).
/// Otherwise returns [path] unchanged.
String localPathReferencePath(String path) {
  var parts = url.split(sanitizeReferencePath(path));
  if (parts.length > 6 &&
      parts[0] == 'projects' &&
      parts[2] == 'databases' &&
      parts[4] == 'documents') {
    parts = parts.sublist(5);
    return url.joinAll(parts);
  }
  return path;
}

/// Asserts, in debug mode only (see `isDebug`), that [path] is a valid
/// collection path (an odd number of segments).
///
/// A no-op in release mode. Throws an [AssertionError] via `assert` if
/// [path] does not have an odd number of segments.
void checkCollectionReferencePath(String path) {
  if (isDebug) {
    var parts = localPathReferenceParts(path);
    assert(
      isCollectionReferencePath(path),
      'Collection references must have an odd number of segments, but $path ($parts) has length ${parts.length}',
    );
  }
}

/// Asserts, in debug mode only (see `isDebug`), that [path] is a valid
/// document path (an even number of segments).
///
/// A no-op in release mode. Throws an [AssertionError] via `assert` if
/// [path] does not have an even number of segments.
void checkDocumentReferencePath(String path) {
  if (isDebug) {
    var parts = localPathReferenceParts(path);
    assert(
      isDocumentReferencePath(path),
      'Document references must have an even number of segments, but $path ($parts) has length ${parts.length}',
    );
  }
}
