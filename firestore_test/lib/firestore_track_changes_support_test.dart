// ignore_for_file: inference_failure_on_collection_literal
import 'dart:async';

import 'package:dev_test/test.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/collection.dart';
import 'package:tekartik_firebase_firestore/utils/track_changes_support.dart';

import 'firestore_test.dart';

// create a future delayed for [ms] milliseconds
Future _sleep([int ms = 0]) {
  return Future<void>.delayed(Duration(milliseconds: ms));
}

void runFirestoreTrackChangesSupportTests(
    {required FirestoreService firestoreService,
    required Firestore firestore,
    required FirestoreTestContext? testContext}) {
  var testsRefPath = FirestoreTestContext.getRootCollectionPath(testContext);

  group('track_changes_support', () {
    CollectionReference getTestsRef() {
      return firestore.collection(testsRefPath);
    }

    test('simpleOnSnapshotSupport', () async {
      var testsRef = getTestsRef();
      var docRef = testsRef.doc('simple_onSnapshotSupport');
      await docRef.set({'test': 1});

      expect((await docRef.onSnapshotSupport().first).data, {'test': 1});

      expect(
          (await docRef
                  .onSnapshotSupport(
                      options: TrackChangesSupportOptions.first())
                  .first)
              .data,
          {'test': 1});
    });

    test('simplePullOnSnapshotSupport', () async {
      var testsRef = getTestsRef();
      var parentDocRef = testsRef.doc('simplePullOnSnapshotSupport');
      var collRef = parentDocRef.collection('one');
      await deleteCollection(firestore, collRef);

      var docRef = collRef.doc('one_record');

      var pullOptions1 =
          TrackChangesSupportOptions(refreshDelay: Duration(milliseconds: 200));

      var future = Future.wait([
        () async {
          expect(
              (await docRef
                      .onSnapshotSupport(options: pullOptions1)
                      .firstWhere((snapshot) => snapshot.exists))
                  .data,
              {'test': 1});
        }(),
        () async {
          await collRef
              .onSnapshotSupport(options: pullOptions1)
              .firstWhere((snapshots) => snapshots.ids.contains(docRef.id));
        }()
      ]);
      await docRef.set({'test': 1});
      await future;
    });

    test('simpleTriggerOnSnapshotSupport', () async {
      var testsRef = getTestsRef();
      var parentDocRef = testsRef.doc('simplePullOnSnapshotSupport');
      var collRef = parentDocRef.collection('one');
      await deleteCollection(firestore, collRef);

      var docRef = collRef.doc('one_record');

      var controller1 = TrackChangesSupportOptionsController();
      var controller2 = TrackChangesSupportOptionsController();

      var future = Future.wait([
        () async {
          expect(
              (await docRef
                      .onSnapshotSupport(options: controller1)
                      .firstWhere((snapshot) => snapshot.exists))
                  .data,
              {'test': 1});
        }(),
        () async {
          await collRef
              .onSnapshotSupport(options: controller2)
              .firstWhere((snapshots) => snapshots.ids.contains(docRef.id));
        }()
      ]);
      await docRef.set({'test': 1});
      controller1.trigger();
      controller2.trigger();
      await future;
      controller1.dispose();
      controller2.dispose();
    });

    test('twoOnSnapshotSupport', () async {
      var testsRef = getTestsRef();
      var docRef = testsRef.doc('two_onSnapshotSupport');
      await docRef.delete();
      var pullOptions1 =
          TrackChangesSupportOptions(refreshDelay: Duration(milliseconds: 200));

      var completer1 = Completer<void>();
      var completer2 = Completer<void>();
      var subscription1 =
          docRef.onSnapshotSupport(options: pullOptions1).listen((event) {
        if (event.exists) {
          completer1.complete();
        }
      });
      var subscription2 =
          docRef.onSnapshotSupport(options: pullOptions1).listen((event) {
        if (event.exists) {
          completer2.complete();
        }
      });
      await docRef.set({'test': 1});
      await completer1.future;
      await completer2.future;
      await subscription1.cancel();
      await subscription2.cancel();
    });

    test('updatesOnSnapshotSupport', () async {
      var testsRef = getTestsRef();
      var docRef = testsRef.doc('simple_updatesOnSnapshotSupport');
      await docRef.delete();
      var pullOptions1 =
          TrackChangesSupportOptions(refreshDelay: Duration(milliseconds: 200));
      var pullOptions2 = TrackChangesSupportOptions.first();

      var eventList1 = <DocumentSnapshot>[];
      var eventList2 = <DocumentSnapshot>[];
      var sub1 =
          docRef.onSnapshotSupport(options: pullOptions1).listen((event) {
        eventList1.add(event);
      });
      var sub2 =
          docRef.onSnapshotSupport(options: pullOptions2).listen((event) {
        eventList2.add(event);
      });

      await _sleep(300);
      await docRef.set({'test': 1});
      await _sleep(300);
      await docRef.set({'test': 2});
      await docRef
          .onSnapshotSupport(options: pullOptions1)
          .firstWhere((element) => element.dataOrNull?['test'] == 2);
      expect(eventList1.length, greaterThanOrEqualTo(3));
      if (firestoreService.supportsTrackChanges) {
        expect(eventList2.length, greaterThanOrEqualTo(3));
      } else {
        expect(eventList2.length, 1);
      }
      unawaited(sub1.cancel());
      unawaited(sub2.cancel());
    });
  });
}
