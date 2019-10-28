import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/document_reference_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore_rest/src/collection_reference_rest.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart';
import 'package:googleapis/firestore/v1.dart' as api;

class DocumentReferenceRestImpl
    with DocumentReferenceMixin, PathReferenceMixin, PathReferenceRestMixin
    implements DocumentReference {
  DocumentReferenceRestImpl(FirestoreRestImpl firestoreRest, String path) {
    init(firestoreRest, path);
  }

  @override
  Future delete() {
    // TODO: implement delete
    return null;
  }

  @override
  Future<DocumentSnapshot> get() => firestoreRestImpl.getDocument(path);

  @override
  Stream<DocumentSnapshot> onSnapshot() {
    // TODO: implement onSnapshot
    return null;
  }

  @override
  Future set(Map<String, dynamic> data, [SetOptions options]) =>
      firestoreRestImpl.patchDocument(path, data);

  @override
  Future update(Map<String, dynamic> data) {
    // TODO: implement update
    return null;
  }
}

class DocumentSnapshotRestImpl implements DocumentSnapshot {
  final FirestoreRestImpl firestoreRestImpl;
  final api.Document impl;

  DocumentSnapshotRestImpl(this.firestoreRestImpl, this.impl);
  @override
  Timestamp get createTime => Timestamp.tryParse(impl.createTime);

  @override
  Map<String, dynamic> get data =>
      mapFromFields(firestoreRestImpl, impl.fields);

  @override
  bool get exists => impl != null;

  @override
  DocumentReference get ref =>
      DocumentReferenceRestImpl(firestoreRestImpl, impl.name);

  @override
  Timestamp get updateTime => Timestamp.tryParse(impl.updateTime);
}
