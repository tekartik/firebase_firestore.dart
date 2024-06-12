@TestOn('vm')
library tekartik_firebase_sembast.firebase_io_test;

import 'package:tekartik_firebase_firestore_sembast/firestore_sembast_io.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  skipConcurrentTransactionTests = true;
  var firebase = FirebaseLocal();
  runFirestoreTests(firebase: firebase, firestoreService: firestoreServiceIo);
}
