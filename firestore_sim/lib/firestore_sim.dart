import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_sim/src/firestore_sim_client.dart'
as _;

FirestoreServiceProvider get firebaseFirestoreServiceProviderSim =>
    _.firebaseFirestoreServiceProviderSim;
FirestoreServiceProvider get firestoreServiceProvider =>
    firebaseFirestoreServiceProviderSim;
