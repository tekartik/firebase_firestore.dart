library;

import 'package:tekartik_firebase_firestore_sim/firestore_sim.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
// ignore: unused_import
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:test/test.dart';

import 'test_common.dart';

Future main() async {
  // debugFirebaseSimServer = devTrue;
  // debugFirebaseSimClient = devTrue;
  // debugSimServerMessage = true;
  skipConcurrentTransactionTests = true;
  var testContext = await initTestContextSim();
  var firebase = testContext.firebase;
  var app = firebase.initializeApp();
  runFirestoreAppTests(
    app: app,
    firestoreService: firestoreServiceSim,
    testContext: FirestoreTestContext(),
  );

  test('projectId', () {
    expect(app.options.projectId, 'sim');
  });

  tearDownAll(() async {
    await close(testContext);
  });
}
