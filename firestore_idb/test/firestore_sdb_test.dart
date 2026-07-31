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

      var app = firebase.initializeApp(name: 'firestore_sdb_tests');
      var firestore = firestoreService.firestore(app);
      expect(firestore.app, app);
      expect(firestore.service, firestoreService);
      expect(firestoreService.firestore(app), firestore);
      expect(app.getProduct<Firestore>(), firestore);
      expect(app.firestore(), firestore);
      expect(firestore.supportsTransaction, isTrue);
    });
    runFirestoreTests(firebase: firebase, firestoreService: firestoreService);
  });
}
