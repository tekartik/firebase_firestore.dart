import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:path/path.dart';

mixin PathReferenceMixin {
  Firestore firestore;
  String path;

  void init(Firestore firestore, String path) {
    this.firestore = firestore;
    this.path = path;
  }

  /// Parent path.
  String get parentPath => getParentPath(path);

  String get id => path == null ? null : url.basename(path);

  /// Child path
  String getChildPath(String child) => url.join(path, child);

  @override
  String toString() => 'path: $path';
}

String getParentPath(String path) {
  return url.dirname(path);
}

String getPathId(String path) => path == null ? null : url.basename(path);

mixin CollectionReferenceMixin
    implements CollectionReference, PathReferenceMixin {
  @override
  DocumentReference get parent => firestore.doc(parentPath);

  @override
  DocumentReference doc([String path]) => firestore.doc(getChildPath(path));
}
mixin DocumentReferenceMixin implements DocumentReference, PathReferenceMixin {
  @override
  CollectionReference get parent => firestore.collection(parentPath);

  @override
  CollectionReference collection(String path) =>
      firestore.collection(getChildPath(path));
}
