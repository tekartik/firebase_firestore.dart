import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/reference_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore_rest/src/collection_reference_rest.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore/v1beta1.dart'
    as api;
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart';

class DocumentReferenceRestImpl
    with
        DocumentReferenceMixin,
        PathReferenceImplMixin,
        PathReferenceMixin,
        PathReferenceRestMixin
    implements DocumentReference {
  DocumentReferenceRestImpl(FirestoreRestImpl firestoreRest, String path) {
    init(firestoreRest, path);
    checkDocumentReferencePath(this.path);
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
      firestoreRestImpl.writeDocument(path, data, merge: options?.merge);

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

  /// Never null if it exists.
  @override
  Map<String, dynamic> get data => exists
      ? (mapFromFields(firestoreRestImpl, impl.fields) ?? <String, dynamic>{})
      : null;

  /// Sometimes in get we have a Document will all fields null.
  @override
  bool get exists => impl?.name != null;

  @override
  DocumentReference get ref => DocumentReferenceRestImpl(
      firestoreRestImpl, firestoreRestImpl.getDocumentPath(impl.name));

  @override
  Timestamp get updateTime => Timestamp.tryParse(impl.updateTime);
}
