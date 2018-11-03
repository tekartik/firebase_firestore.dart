import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_sembast/src/firestore_sembast.dart'
    as _;

FirestoreServiceProvider get firebaseFirestoreServiceProviderSembastMemory =>
    _.firebaseFirestoreServiceProviderSembastMemory;
FirestoreServiceProvider get firestoreServiceProvider =>
    firebaseFirestoreServiceProviderSembastMemory;
FirestoreService get firestoreServiceMemory => _.firestoreServiceSembastMemory;
