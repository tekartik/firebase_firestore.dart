@Deprecated('include reference_mixin - since 2020/05/07')
library tekartik_firebase_firestore.src.common.document_reference_mixin;

import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:path/path.dart';
export 'reference_mixin.dart';

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

  @override
  int get hashCode => path.hashCode;

  @override
  bool operator ==(other) {
    if (other is CollectionReferenceMixin) {
      if (firestore != (other).firestore) {
        return false;
      }
      if (path != (other).path) {
        return false;
      }
      return true;
    }
    return false;
  }
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
