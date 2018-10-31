import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_sim/src/firestore_sim_client.dart'
    as impl;

FirestoreServiceProvider get firebaseFirestoreServiceProviderSim =>
    impl.firebaseFirestoreServiceProviderSim;
FirestoreServiceProvider get firestoreServiceProvider =>
    firebaseFirestoreServiceProviderSim;
