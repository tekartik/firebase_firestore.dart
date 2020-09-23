import 'package:tekartik_firebase_firestore_node/firestore_universal.dart';
import 'package:test/test.dart';

void main() {
  group('firestore_universal', () {
    test('firestoreService', () {
      expect(firestoreService, isNotNull);
    });
  });
}
