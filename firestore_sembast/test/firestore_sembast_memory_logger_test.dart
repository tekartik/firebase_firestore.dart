library tekartik_firebase_firestore_sembast.firestroage_memory_logger_test;

import 'package:tekartik_firebase_firestore/firestore_logger.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

void main() {
  // needed for memory
  skipConcurrentTransactionTests = true;
  var firebase = FirebaseLocal();
  run(
      firebase: firebase,
      firestoreService: FirestoreServiceLogger(
          firestoreService: newFirestoreServiceMemory(),
          options: FirestoreLoggerOptions.all(log: (_) {})));
}
