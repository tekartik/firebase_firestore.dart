import 'package:idb_shim/idb_client_native.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_idb/src/firestore_idb.dart'
    as firestore_idb;

@Deprecated('Use firestoreServiceIdbBrowser')
FirestoreService get firestoreService => firestoreServiceIdbBrowser;

FirestoreService get firestoreServiceIdbBrowser =>
    firestore_idb.getFirestoreService(idbFactoryNative);
