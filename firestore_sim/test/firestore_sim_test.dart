library;

import 'package:tekartik_firebase_firestore_sim/firestore_sim.dart';
import 'package:tekartik_firebase_firestore_sim/src/firestore_sim_client.dart' // ignore: implementation_imports
    show CollectionReferenceSim;
import 'package:tekartik_firebase_firestore_test/firestore_test_runner.dart';
// ignore: unused_import
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:test/test.dart';

import 'test_common.dart';

Future main() async {
  // debugFirebaseSimServer = devTrue;
  // debugFirebaseSimClient = devTrue;
  // debugSimServerMessage = true;
  skipConcurrentTransactionTests = true;
  var testContext = await initFirestoreTestContextSim();
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

  test('collection doc without path', () {
    var collRef =
        firestoreServiceSim.firestore(app).collection('col')
            as CollectionReferenceSim;
    var docRef1 = collRef.doc();
    var docRef2 = collRef.doc();
    // An id is generated like the other implementations.
    expect(docRef1.id, isNotEmpty);
    expect(docRef1.parent.path, 'col');
    expect(docRef1.path, isNot(docRef2.path));
  });

  tearDownAll(() async {
    await close(testContext);
  });
}
