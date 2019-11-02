import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart';
import 'package:tekartik_firebase_firestore_rest/src/import.dart';
import 'package:tekartik_firebase_firestore_rest/src/write_batch.dart';

class TransactionRestImpl extends WriteBatchRestImpl implements Transaction {
  TransactionRestImpl(FirestoreRestImpl firestoreRest) : super(firestoreRest);

  @override
  Future<DocumentSnapshot> get(DocumentReference documentRef) async {
    return firestoreRestImpl.getDocument(documentRef.path,
        transactionId: transactionId);
  }
}
