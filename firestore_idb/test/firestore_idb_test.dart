library tekartik_firebase_firestore_idb.firestore_idb_test;

import 'package:idb_shim/idb_client_memory.dart';
import 'package:tekartik_firebase_firestore_idb/firestore_idb.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void idbTestInit() {
  skipConcurrentTransactionTests = true;
}

void main() async {
  final idbFactory = idbFactoryMemory;
  var firestoreService = getFirestoreService(idbFactory);
  var firebase = FirebaseLocal();
  idbTestInit();

  group('idb', () {
    test('factory', () {
      expect(firestoreService.supportsQuerySelect, isTrue);
      expect(firestoreService.supportsTimestamps, isTrue);
      expect(firestoreService.supportsTrackChanges, isFalse);
    });
    runFirestoreTests(
      firebase: firebase,
      firestoreService: firestoreService,
    );
  });
}
