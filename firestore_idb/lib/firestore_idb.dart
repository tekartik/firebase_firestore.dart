import 'package:idb_shim/idb.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_idb/src/firestore_idb.dart'
    as firestore_idb;

FirestoreService getFirestoreService(IdbFactory idbFactory) =>
    firestore_idb.getFirestoreService(idbFactory);
