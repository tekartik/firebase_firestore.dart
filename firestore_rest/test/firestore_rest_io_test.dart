@TestOn('vm')
library tekartik_firebase_rest.firestore_rest_io_test;

import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:test/test.dart';

import 'test_setup.dart';

Future main() async {
  skipConcurrentTransactionTests = true;
  var context = await setup();
  group('rest_io', () {
    if (context != null) {
      var firebase = firebaseRest;
      run(
          firebase: firebase,
          firestoreService: firestoreServiceRest,
          options: context.options);
    }
  }, skip: context == null);
}
