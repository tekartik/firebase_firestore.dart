import 'package:idb_shim/sdb.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_idb/src/firestore_sdb.dart'
    as firestore_sdb;

export 'package:tekartik_firebase_firestore/firestore.dart';

/// SdbFactory extension to get firestoreService.
extension TekartikFirebaseFirestoreSdbFactoryExt on SdbFactory {
  /// Get the firestore service.
  FirestoreService get firestoreService =>
      firestore_sdb.getFirestoreService(this);
}

/// Global firestore service for web using sdb.
FirestoreService get firestoreServiceSdbWeb =>
    firestore_sdb.getFirestoreService(sdbFactoryWeb);
