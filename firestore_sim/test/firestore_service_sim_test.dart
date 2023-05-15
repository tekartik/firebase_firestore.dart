import 'package:tekartik_firebase_firestore_sim/firestore_sim.dart';
import 'package:test/test.dart';

void main() {
  group('firestore_service_sim', () {
    test('supportsDocumentSnapshotTime', () {
      expect(firestoreServiceSim.supportsTimestampsInSnapshots, isTrue);
    });
  });
}
