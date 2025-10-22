@TestOn('vm')
library;

import 'dart:async';

import 'package:tekartik_firebase_firestore_sim/firestore_sim.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:test/test.dart';

import 'test_common.dart';

Future main() async {
  // debugSimServerMessage = true;
  skipConcurrentTransactionTests = true;
  var testContext = await initTestContextSimIo(port: 0);
  var firebase = testContext.firebase;
  runFirestoreTests(firebase: firebase, firestoreService: firestoreServiceSim);

  tearDownAll(() async {
    await close(testContext);
  });
}
