/// Firebase Firestore on top of idb_shim.
library;

import 'package:idb_shim/idb.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_idb/src/firestore_idb.dart'
    as firestore_idb;

/// IdbFactory extension to get firestoreService.
extension TekartikFirebaseFirestoreIdbFactoryExt on IdbFactory {
  /// Get the firestore service.
  FirestoreService get firestoreService =>
      firestore_idb.getFirestoreService(this);
}

/// Helper method to get the firestore service.
@Deprecated('use idbFactory.firestoreService')
FirestoreService getFirestoreService(IdbFactory idbFactory) =>
    firestore_idb.getFirestoreService(idbFactory);
