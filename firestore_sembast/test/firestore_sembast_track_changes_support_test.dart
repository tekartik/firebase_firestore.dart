library;

import 'dart:async';

// ignore: unused_import
import 'package:tekartik_common_utils/dev_utils.dart';
// ignore: unused_import
import 'package:tekartik_common_utils/lazy_runner/lazy_runner.dart';
import 'package:tekartik_firebase_firestore/utils/track_changes_support.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:tekartik_firebase_firestore_test/firestore_track_changes_support_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void groupTrackChangesSembastSupport({required Firestore firestore}) {
  CollectionReference getTestsRef() {
    // ignore: deprecated_member_use
    return firestore.collection(testsRefPath);
  }

  runFirestoreTrackChangesSupportTests(
    firestoreService: firestore.service,
    firestore: firestore,
    testContext: null,
  );
  group('diff', () {
    /// Should fail if no support
    Future<void> testOneOnSnapshotSupport() async {
      var testsRef = getTestsRef();
      var docRef = testsRef.doc('diff_one_onSnapshotSupport');
      await docRef.delete();
      var pullOptions = TrackChangesSupportOptions(
        refreshDelay: const Duration(milliseconds: 10000),
      );

      var completer = Completer<void>();

      var subscription = docRef.onSnapshotSupport(options: pullOptions).listen((
        event,
      ) {
        if (event.exists) {
          completer.complete();
        }
      });
      try {
        await docRef.set({'test': 1});
        await completer.future.timeout(const Duration(milliseconds: 500));
      } finally {
        await subscription.cancel();
      }
    }

    test('no_supports', () async {
      try {
        await testOneOnSnapshotSupport();
        fail('should fail');
      } on TimeoutException catch (_) {}
    }, skip: firestore.service.supportsTrackChanges);
    test('with_supports', () async {
      await testOneOnSnapshotSupport();
    }, skip: !firestore.service.supportsTrackChanges);

    /// Should fail if no support
    test('Trigger', () async {
      //debugLazyRunner = devWarning(true);
      var testsRef = getTestsRef();
      var docRef = testsRef.doc('one_onSnapshotSupport_trigger');
      await docRef.delete();
      var controller = TrackChangesSupportOptionsController();

      var completer = Completer<void>();

      var subscription = docRef.onSnapshotSupport(options: controller).listen((
        event,
      ) {
        if (event.exists) {
          completer.complete();
        }
      });
      try {
        await docRef.set({'test': 1});
        await completer.future.timeout(const Duration(milliseconds: 500));
        if (!firestore.service.supportsTrackChanges) {
          fail('should fail');
        }
      } on TimeoutException catch (_) {
        expect(firestore.service.supportsTrackChanges, isFalse);
      } finally {
        await subscription.cancel();
      }
      controller.trigger();
    });
  });
}

void main() {
  // needed for memory
  skipConcurrentTransactionTests = true;
  var firebase = FirebaseLocal();
  var service = newFirestoreServiceMemory();
  service.sembastSupportsTrackChanges = true;
  var app = firebase.app();
  var firestore = service.firestore(app);
  groupTrackChangesSembastSupport(firestore: firestore);
}
