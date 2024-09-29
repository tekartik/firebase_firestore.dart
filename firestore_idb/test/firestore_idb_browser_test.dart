@TestOn('browser')
library;

import 'package:tekartik_firebase_firestore_idb/firestore_idb_browser.dart'
    as idb;
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

import 'firestore_idb_test.dart';

void main() async {
  var firestoreService = idb.firestoreServiceIdbBrowser;
  var firebase = FirebaseLocal();
  idbTestInit();
  group('browser', () {
    test('factory', () {
      expect(firestoreService.supportsQuerySelect, isTrue);
    });
    runFirestoreTests(
      firebase: firebase,
      firestoreService: firestoreService,
    );
  });
}
