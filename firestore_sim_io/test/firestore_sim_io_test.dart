@TestOn('vm')
library tekartik_firebase_firestore_sim_io.firestore_sim_io_test;

import 'package:tekartik_firebase_firestore_sembast/firestore_sembast_io.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:test/test.dart';

import 'test_common.dart';

main() async {
  // debugSimServerMessage = true;
  skipConcurrentTransactionTests = true;
  var testContext = await initTestContextSimIo();
  var firebase = testContext.firebase;
  var provider = firestoreServiceProvider;
  run(firebase: firebase, provider: provider);

  tearDownAll(() async {
    await close(testContext);
  });
}
