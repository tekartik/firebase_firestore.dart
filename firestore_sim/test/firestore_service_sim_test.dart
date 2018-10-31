import 'package:tekartik_firebase_firestore_sim/src/firestore_sim_client.dart';
import 'package:test/test.dart';

void main() {
  group("firestore_service_sim", () {
    test('supportsDocumentSnapshotTime', () {
      var firestoreService = FirestoreServiceSim(null, null);
      expect(firestoreService.supportsTimestampsInSnapshots, isTrue);
    });
  });
}
