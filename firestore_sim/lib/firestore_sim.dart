/// Client side of a firestore hosted by a firebase sim server:
/// `firestoreServiceSim.firestore(app)` on a `FirebaseAppSim`
/// (`getFirebaseSim`) forwards every call to the server.
library;

import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_sim/src/firestore_sim_client.dart'
    as impl;

/// Firestore simulator service.
FirestoreService get firestoreServiceSim => impl.firestoreServiceSim;
