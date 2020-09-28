import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_sembast/src/firestore_sembast.dart'
    as firestore_sembast;

/// In memory service
FirestoreService get firestoreServiceMemory =>
    firestore_sembast.firestoreServiceSembastMemory;

/// New in memory service (2 services won't share the same data)
FirestoreService newFirestoreServiceMemory() =>
    firestore_sembast.newFirestoreServiceSembastMemory();
