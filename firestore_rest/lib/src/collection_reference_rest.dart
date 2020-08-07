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
    checkCollectionReferencePath(path);
  }

  @override
  Future<DocumentReference> add(Map<String, dynamic> data) =>
      firestoreRestImpl.createDocument(path, data);
}
