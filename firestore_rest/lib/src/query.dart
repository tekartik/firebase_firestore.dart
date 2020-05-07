import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/reference_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore/src/common/query_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore/utils/json_utils.dart';
import 'package:tekartik_firebase_firestore_rest/src/collection_reference_rest.dart';
import 'package:tekartik_firebase_firestore_rest/src/document_reference_rest.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore/v1beta1.dart'
    show RunQueryFixedResponse;
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart';

class QueryRestImpl
    with
        QueryMixin,
        PathReferenceMixin,
        PathReferenceImplMixin,
        PathReferenceRestMixin
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
  final FirestoreRestImpl firestoreRest;
  final RunQueryFixedResponse response;

  QuerySnapshotRestImpl(this.firestoreRest, this.response);

  List<DocumentSnapshot> _docs;

  @override
  List<DocumentSnapshot> get docs => _docs ??= () {
        return response?.documents
            ?.map((document) =>
                DocumentSnapshotRestImpl(firestoreRest, document.document))
            ?.where((snapshot) => isDocumentSnapshot(snapshot))
            ?.toList(growable: false);
      }();

  @override
  List<DocumentChange> get documentChanges => null;
}

/// For empty result we get this: [{readTime: 2019-11-02T15:24:14.458076Z}]
bool isDocumentSnapshot(DocumentSnapshotRestImpl snapshot) {
  return snapshot.exists ?? false;
}
