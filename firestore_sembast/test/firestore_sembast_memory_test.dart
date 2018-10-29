library tekartik_firebase_sembast.firebase_sembast_memory_test;

import 'package:tekartik_firebase_firestore/firebase.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';

void main() {
  skipConcurrentTransactionTests = true;
  run(
      provider: firebaseFirestoreSembastProviderMemory,
      firebase: FirebaseLocal());
}
