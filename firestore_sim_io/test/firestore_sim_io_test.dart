@TestOn('vm')
library tekartik_firebase_firestore_sim_io.firestore_sim_io_test;

import 'dart:async';

import 'package:tekartik_firebase_firestore_sim/firestore_sim.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:test/test.dart';

import 'test_common.dart';

Future main() async {
  // debugSimServerMessage = true;
  skipConcurrentTransactionTests = true;
  var testContext = await initTestContextSimIo();
  var firebase = testContext.firebase;
  run(firebase: firebase, firestoreService: firestoreService);

  tearDownAll(() async {
    await close(testContext);
  });
}
