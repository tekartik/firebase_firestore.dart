// ignore_for_file: inference_failure_on_collection_literal
import 'dart:async';

import 'package:dev_test/test.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
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
                  .onSnapshotSupport(options: TrackChangesPullOptions.first())
                  .first)
              .data,
          {'test': 1});
    });

    test('twoOnSnapshotSupport', () async {
      var testsRef = getTestsRef();
      var docRef = testsRef.doc('two_onSnapshotSupport');
      await docRef.delete();

      var completer1 = Completer<void>();
      var completer2 = Completer<void>();
      var subscription1 = docRef.onSnapshotSupport().listen((event) {
        print('event1 $event');
        if (event.exists) {
          completer1.complete();
        }
      });
      var subscription2 = docRef.onSnapshotSupport().listen((event) {
        print('event2 $event');
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
          TrackChangesPullOptions(refreshDelay: Duration(milliseconds: 200));
      var pullOptions2 = TrackChangesPullOptions.first();

      var eventList1 = <DocumentSnapshot>[];
      var eventList2 = <DocumentSnapshot>[];
      var sub1 =
          docRef.onSnapshotSupport(options: pullOptions1).listen((event) {
        print('event $event');
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
