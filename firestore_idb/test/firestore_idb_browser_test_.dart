@TestOn('browser')
library tekartik_firebase_firestore_idb.firestore_idb_browser_test;

import 'package:tekartik_firebase_firestore_idb/firestore_idb_browser.dart'
    as idb;
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() async {
  var firestoreService = idb.firestoreService;
  var firebase = FirebaseLocal();

  group('browser', () {
    test('factory', () {
      expect(firestoreService.supportsQuerySelect, isFalse);
    });
    run(
      firebase: firebase,
      firestoreService: firestoreService,
    );
  }, skip: true);
}
