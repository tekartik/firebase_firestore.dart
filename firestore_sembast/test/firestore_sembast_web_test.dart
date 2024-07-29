@TestOn('browser')
library;

import 'package:tekartik_firebase_firestore_sembast/firestore_sembast_web.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  skipConcurrentTransactionTests = true;
  var firebase = FirebaseLocal();
  runFirestoreTests(firebase: firebase, firestoreService: firestoreServiceWeb);
}
