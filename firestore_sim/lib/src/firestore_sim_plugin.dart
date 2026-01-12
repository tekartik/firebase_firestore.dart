import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server_mixin.dart';

import 'firestore_sim_server_service.dart';

/// Firestore simulator plugin.
class FirestoreSimPlugin
    with FirebaseSimPluginDefaultMixin
    implements FirebaseSimPlugin {
  /// Firestore simulator server service.
  final firestoreSimServerService = FirestoreSimServerService();

  /// Firestore service.
  final FirestoreService firestoreService;

  /// Constructor.
  FirestoreSimPlugin({required this.firestoreService}) {
    firestoreSimServerService.firestoreSimPlugin = this;
  }

  @override
  FirebaseSimServerService get simService => firestoreSimServerService;
}
