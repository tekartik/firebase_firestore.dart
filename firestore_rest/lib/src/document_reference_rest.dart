import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/document_reference_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore_rest/src/collection_reference_rest.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore/v1beta1.dart'
    as api;

class DocumentReferenceRestImpl
    with DocumentReferenceMixin, PathReferenceMixin, PathReferenceRestMixin
    implements DocumentReference {
  DocumentReferenceRestImpl(FirestoreRestImpl firestoreRest, String path) {
    init(firestoreRest, path);
  }

  @override
  Future delete() => firestoreRestImpl.deleteDocument(path);

  @override
  Future<DocumentSnapshot> get() => firestoreRestImpl.getDocument(path);

  @override
  Stream<DocumentSnapshot> onSnapshot() =>
      throw UnsupportedError('onSnapshot not supported');

  @override
  Future set(Map<String, dynamic> data, [SetOptions options]) =>
      firestoreRestImpl.patchDocument(path, data, merge: options?.merge);

  @override
  Future update(Map<String, dynamic> data) =>
      firestoreRestImpl.updateDocument(path, data);
}

class DocumentSnapshotRestImpl implements DocumentSnapshot {
  final FirestoreRestImpl firestoreRestImpl;
  final api.Document impl;

  DocumentSnapshotRestImpl(this.firestoreRestImpl, this.impl);
  @override
  Timestamp get createTime => Timestamp.tryParse(impl.createTime);

  /// Never null
  @override
  Map<String, dynamic> get data =>
      mapFromFields(firestoreRestImpl, impl.fields) ?? <String, dynamic>{};

  /// Sometimes in get we have a Document will all fields null.
  @override
  bool get exists => impl?.name != null;

  @override
  DocumentReference get ref => DocumentReferenceRestImpl(
      firestoreRestImpl, firestoreRestImpl.getDocumentPath(impl.name));

  @override
  Timestamp get updateTime => Timestamp.tryParse(impl.updateTime);
}
