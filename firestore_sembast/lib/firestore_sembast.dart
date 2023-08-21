import 'package:sembast/sembast.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_sembast/src/firestore_sembast.dart'
    as firestore_sembast;
import 'package:tekartik_firebase_local/firebase_local.dart';

export 'package:tekartik_firebase_firestore_sembast/src/firestore_sembast.dart'
    show FirestoreServiceSembast;

export 'package:tekartik_firebase_firestore_sembast/src/firestore_sembast_ext.dart'
    show TekartikFirestoreSembastExt;

/// In memory service
FirestoreService get firestoreServiceMemory =>
    firestore_sembast.firestoreServiceSembastMemory;

/// New in memory service (2 services won't share the same data)
FirestoreService newFirestoreServiceMemory() =>
    firestore_sembast.newFirestoreServiceSembastMemory();

/// Quick firestore test helper
Firestore newFirestoreMemory() =>
    newFirestoreServiceMemory().firestore(newFirebaseAppLocal());

/// New sembast service
FirestoreService newFirestoreServiceSembast(
        {required DatabaseFactory databaseFactory}) =>
    firestore_sembast.FirestoreServiceSembast(databaseFactory);
