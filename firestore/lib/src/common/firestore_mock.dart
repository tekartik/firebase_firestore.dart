import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_firestore/src/firestore_common.dart';

import 'import_firestore_mixin.dart';

class FirestoreServiceMock with FirestoreServiceDefaultMixin {
  @override
  Firestore firestore(App app) {
    return FirestoreMock();
  }
}

class FirestoreMock with FirestoreDefaultMixin, FirestoreMixin {
  @override
  final FirestoreServiceMock service;

  FirestoreMock({FirestoreServiceMock? service})
      : service = service ?? FirestoreServiceMock();
  @override
  WriteBatch batch() {
    throw UnimplementedError();
  }

  @override
  CollectionReference collection(String path) {
    checkCollectionReferencePath(path);
    return CollectionReferenceMock(this, path);
  }

  @override
  DocumentReference doc(String path) {
    checkDocumentReferencePath(path);
    return DocumentReferenceMock(this, path);
  }

  @override
  Future<T> runTransaction<T>(
      FutureOr<T> Function(Transaction transaction) updateFunction) {
    throw UnimplementedError();
  }
}

class DocumentSnapshotMock
    with DocumentSnapshotMixin
    implements DocumentSnapshot {
  @override
  final DocumentReferenceMock ref;

  DocumentSnapshotMock(this.ref);

  @override
  Map<String, Object?> get data => throw UnimplementedError();

  @override
  bool get exists => throw UnimplementedError();

  @override
  Timestamp? get updateTime => throw UnimplementedError();

  @override
  Timestamp? get createTime => throw UnimplementedError();
}

class CollectionReferenceMock
    with
        QueryDefaultMixin,
        CollectionReferenceMixin,
        PathReferenceImplMixin,
        PathReferenceMixin,
        FirestoreQueryExecutorMixin,
        FirestoreQueryMixin {
  CollectionReferenceMock(FirestoreMock firestoreMock, String path) {
    init(firestoreMock, path);
  }

  @override
  Future<DocumentReference> add(Map<String, Object?> data) {
    throw UnimplementedError();
  }

  @override
  FirestoreQueryMixin clone() {
    return QueryMock(this, QueryInfo());
  }

  @override
  Future<List<DocumentSnapshot>> getCollectionDocuments() {
    throw UnimplementedError();
  }

  @override
  QueryInfo? get queryInfo => null;
}

class DocumentReferenceMock
    with
        DocumentReferenceDefaultMixin,
        DocumentReferenceMixin,
        PathReferenceImplMixin,
        PathReferenceMixin {
  DocumentReferenceMock(FirestoreMock firestoreMock, String path) {
    init(firestoreMock, path);
  }

  @override
  Future<void> delete() async {
    throw UnimplementedError();
  }

  @override
  Future<DocumentSnapshot> get() {
    throw UnimplementedError();
  }

  @override
  Stream<DocumentSnapshot> onSnapshot({bool includeMetadataChanges = false}) {
    throw UnimplementedError();
  }

  @override
  Future<void> set(Map<String, Object?> data, [SetOptions? options]) {
    throw UnimplementedError();
  }

  @override
  Future<void> update(Map<String, Object?> data) {
    throw UnimplementedError();
  }
}

class QueryMock
    with
        QueryDefaultMixin,
        FirestoreQueryExecutorMixin,
        AttributesMixin,
        FirestoreQueryMixin {
  final CollectionReferenceMock collMock;
  @override
  final QueryInfo queryInfo;
  QueryMock(this.collMock, this.queryInfo);

  @override
  FirestoreQueryMixin clone() {
    return QueryMock(collMock, queryInfo.clone());
  }

  @override
  Firestore get firestore => collMock.firestore;

  @override
  Future<List<DocumentSnapshot>> getCollectionDocuments() {
    throw UnimplementedError();
  }

  @override
  String get path => collMock.path;
}
