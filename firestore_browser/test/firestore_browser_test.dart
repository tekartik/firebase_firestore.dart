@TestOn('browser')
library tekartik_firebase_firestore_browser.firestore_browser_test;

import 'package:tekartik_firebase_browser/firebase_browser.dart';
import 'package:tekartik_firebase_firestore_browser/firestore_browser.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:test/test.dart';

import 'test_setup.dart';

void main() async {
  var options = await setup();
  if (options == null) {
    return;
  }
  var firebase = firebaseBrowser;
  var provider = firestoreServiceProvider;
  run(firebase: firebase, provider: provider, options: options);
}
