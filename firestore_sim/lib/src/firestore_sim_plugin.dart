import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';

import 'firestore_sim_server.dart';

class FirestoreSimPlugin implements FirebaseSimPlugin {
  final firestoreSimService = FirestoreSimService();
  final FirestoreService firestoreService;

  FirestoreSimPlugin(this.firestoreService) {
    firestoreSimService.firestoreSimPlugin = this;
  }

  @override
  FirebaseSimServiceBase get simService => firestoreSimService;
}
