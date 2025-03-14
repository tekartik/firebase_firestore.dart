library;

import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

import 'firestore_sembast_track_changes_support_test.dart';

void main() {
  // needed for memory
  skipConcurrentTransactionTests = true;
  var firebase = FirebaseLocal();
  var service = newFirestoreServiceMemory();
  service.sembastSupportsTrackChanges = false;
  var app = firebase.app();
  var firestore = service.firestore(app);
  groupTrackChangesSembastSupport(firestore: firestore);
}
