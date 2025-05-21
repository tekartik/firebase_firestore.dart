import 'package:tekartik_firebase_firestore_sim/src/firestore_sim_client.dart';

DocumentSnapshotSim? snapshotsFindById(
  List<DocumentSnapshotSim> snapshots,
  String? id,
) {
  for (var snapshot in snapshots) {
    if (snapshot.ref.id == id) {
      return snapshot;
    }
  }
  return null;
}
