library;

import 'dart:async';

import 'package:tekartik_firebase_firestore_sim/firestore_sim.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:test/test.dart';

import 'test_common.dart';

Future main() async {
  // debugSimServerMessage = true;
  skipConcurrentTransactionTests = true;
  var testContext = await initTestContextSim();
  var firebase = testContext.firebase;
  var app = firebase.initializeApp();
  runFirestoreAppTests(
      app: app,
      firestoreService: firestoreServiceSim,
      testContext: FirestoreTestContext());

  test('projectId', () {
    expect(app.options.projectId, 'sim');
  });

  tearDownAll(() async {
    await close(testContext);
  });
}
