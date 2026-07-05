library;

import 'package:idb_shim/sdb.dart';
import 'package:tekartik_firebase_firestore_idb/firestore_sdb.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() async {
  skipConcurrentTransactionTests = true;
  final sdbFactory = sdbFactoryMemory;
  var firestoreService = sdbFactory.firestoreService;
  var firebase = FirebaseLocal();

  group('sdb', () {
    test('factory', () {
      expect(firestoreService.supportsQuerySelect, isTrue);
      expect(firestoreService.supportsTimestamps, isTrue);
      expect(firestoreService.supportsTrackChanges, isTrue);
      expect(firestoreService.supportsBlobs, isTrue);
    });
    runFirestoreTests(firebase: firebase, firestoreService: firestoreService);
  });
}
