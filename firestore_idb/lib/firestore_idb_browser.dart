import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:idb_shim/idb_client_native.dart';
import 'src/firestore_idb.dart' as _;

FirestoreService get firestoreService =>
    _.getFirestoreService(idbNativeFactory);
