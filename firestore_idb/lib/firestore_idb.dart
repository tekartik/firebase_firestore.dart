import 'package:idb_shim/idb.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_idb/src/firestore_idb.dart'
    as firestore_idb;

extension TekartikFirebaseFirestoreIdbFactoryExt on IdbFactory {
  FirestoreService get firestoreService =>
      firestore_idb.getFirestoreService(this);
}

@Deprecated('use idbFactory.firestoreService')
FirestoreService getFirestoreService(IdbFactory idbFactory) =>
    firestore_idb.getFirestoreService(idbFactory);
