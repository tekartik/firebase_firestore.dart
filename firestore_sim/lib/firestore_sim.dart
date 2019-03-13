import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_sim/src/firestore_sim_client.dart'
    as impl;

FirestoreService get firestoreService => firestoreServiceSim;
FirestoreService get firestoreServiceSim => impl.firestoreServiceSim;
