@TestOn('node')
library tekartik_firebase_firestore_node.test.firestore_node_test;

import 'package:tekartik_firebase_node/firebase_node.dart';
import 'package:test/test.dart';
import 'package:tekartik_firebase_firestore_node/firestore_node.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';

void main() {
  // Temp skipping transaction test
  skipConcurrentTransactionTests = true;

  var firebase = firebaseNode;
  var provider = firestoreServiceProvider;
  run(firebase: firebase, provider: provider);
}
