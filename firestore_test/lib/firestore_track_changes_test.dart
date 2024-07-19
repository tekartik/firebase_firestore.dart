// ignore_for_file: inference_failure_on_collection_literal
import 'dart:async';

import 'package:dev_test/test.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';

import 'firestore_test.dart';

void runFirestoreTrackChangesTests(
    {required FirestoreService firestoreService,
    required Firestore firestore,
    required FirestoreTestContext? testContext}) {
  var testsRefPath = FirestoreTestContext.getRootCollectionPath(testContext);

  group('track_changes', () {
    CollectionReference getTestsRef() {
      return firestore.collection(testsRefPath);
    }

    test('twoOnSnapshot', () async {
      var testsRef = getTestsRef();
      var docRef = testsRef.doc('two_onSnapshot');
      await docRef.delete();

      var completer1 = Completer<void>();
      var completer2 = Completer<void>();
      var subscription1 = docRef.onSnapshot().listen((event) {
        if (event.exists) {
          completer1.complete();
        }
      });
      var subscription2 = docRef.onSnapshot().listen((event) {
        if (event.exists && event.data['test'] == 2) {
          completer2.complete();
        }
      });
      await docRef.set({'test': 1});

      await completer1.future;
      await subscription1.cancel();
      await docRef.set({'test': 2});
      await completer2.future;

      await subscription2.cancel();
    }, skip: !firestoreService.supportsTrackChanges);
  });
}
