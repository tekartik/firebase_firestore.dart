import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/document_reference_mixin.dart'; // ignore: implementation_imports

import 'package:tekartik_firebase_firestore/src/common/query_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore/utils/json_utils.dart';
import 'package:tekartik_firebase_firestore_rest/src/collection_reference_rest.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart';

class QueryRestImpl
    with QueryMixin, PathReferenceMixin, PathReferenceRestMixin
    implements Query {
  QueryRestImpl(FirestoreRestImpl firestoreRest, String path) {
    init(firestoreRest, path);
  }

  @override
  Stream<QuerySnapshot> onSnapshot() =>
      throw UnsupportedError('onSnapshot not supported');

  @override
  QueryMixin clone() {
    return QueryRestImpl(firestoreRestImpl, path)
      ..queryInfo = (queryInfo?.clone() ?? QueryInfo());
  }

  @override
  Future<QuerySnapshot> get() => firestoreRestImpl.runQuery(this);
}

class QuerySnapshotRestImpl implements QuerySnapshot {
  @override
  List<DocumentSnapshot> get docs => null;

  @override
  List<DocumentChange> get documentChanges => null;
}
