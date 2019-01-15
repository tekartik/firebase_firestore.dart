import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:idb_shim/idb_client_native.dart';
import 'package:tekartik_firebase_firestore_idb/src/firestore_idb.dart'
    as firestore_idb;

FirestoreService get firestoreService =>
    firestore_idb.getFirestoreService(idbNativeFactory);
