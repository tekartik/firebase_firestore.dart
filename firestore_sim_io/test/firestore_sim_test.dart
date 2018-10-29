library tekartik_firebase_server_sim_io.firebase_sim_test;

import 'package:tekartik_firebase_firestore_sim/firestore_sim.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:test/test.dart';
import 'test_common.dart';

main() async {
  // debugSimServerMessage = true;
  skipConcurrentTransactionTests = true;
  var testContext = await initTestContextSim();
  var firebase = testContext.firebase;
  var provider = firestoreServiceProvider;
  run(firebase: firebase, provider: provider);

  tearDownAll(() async {
    await close(testContext);
  });
}
