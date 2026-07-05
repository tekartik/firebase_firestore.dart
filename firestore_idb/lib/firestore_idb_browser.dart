/// Firebase Firestore on top of browser idb_shim.
library;

import 'package:idb_shim/idb_client_native.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_idb/src/firestore_idb.dart'
    as firestore_idb;

/// Browser firestore service.
@Deprecated('Use firestoreServiceIdbBrowser')
FirestoreService get firestoreService => firestoreServiceIdbBrowser;

/// Browser firestore service.
FirestoreService get firestoreServiceIdbBrowser =>
    firestore_idb.getFirestoreService(idbFactoryNative);
