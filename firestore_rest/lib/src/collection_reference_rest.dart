import 'package:path/path.dart';
import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/reference_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart';
import 'package:tekartik_firebase_firestore_rest/src/query.dart';

mixin PathReferenceRestMixin implements FirestorePathReference {
  FirestoreRestImpl get firestoreRestImpl => firestore as FirestoreRestImpl;
}

class CollectionReferenceRestImpl extends QueryRestImpl
    with CollectionReferenceMixin
    implements CollectionReference {
  CollectionReferenceRestImpl(FirestoreRestImpl firestoreRest, String path)
      : super(firestoreRest, path) {
    _checkCollectionRef(this);
  }

  @override
  Future<DocumentReference> add(Map<String, dynamic> data) =>
      firestoreRestImpl.createDocument(path, data);
}

List<String> fixedPathReferenceParts(String path) {
  var parts = url.split(path);
  if (parts.length > 6 &&
      parts[0] == 'projects' &&
      parts[2] == 'databases' &&
      parts[4] == 'documents') {
    parts = parts.sublist(5);
  }
  return parts;
}

void _checkCollectionRef(CollectionReference ref) {
  if (isDebug) {
    var parts = fixedPathReferenceParts(ref.path);
    assert(parts.length % 2 == 1,
        'Collection references must have an odd number of segments, but $ref ($parts) has ${parts.length}');
  }
}
