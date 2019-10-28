@TestOn('vm')
library tekartik_firebase_sembast.firebase_io_test;

import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:test/test.dart';

import 'test_setup.dart';

Future main() async {
  skipConcurrentTransactionTests = true;
  var context = await setup();
  var firebase = firebaseRest;
  run(
      firebase: firebase,
      firestoreService: firestoreServiceRest,
      options: context.options);
}
