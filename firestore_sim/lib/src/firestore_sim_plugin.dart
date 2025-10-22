import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server_mixin.dart';

import 'firestore_sim_server_service.dart';

class FirestoreSimPlugin
    with FirebaseSimPluginDefaultMixin
    implements FirebaseSimPlugin {
  final firestoreSimServerService = FirestoreSimServerService();
  final FirestoreService firestoreService;

  FirestoreSimPlugin({required this.firestoreService}) {
    firestoreSimServerService.firestoreSimPlugin = this;
  }

  @override
  FirebaseSimServerService get simService => firestoreSimServerService;
}
