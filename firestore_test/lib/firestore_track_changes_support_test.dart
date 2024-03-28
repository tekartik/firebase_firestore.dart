// ignore_for_file: inference_failure_on_collection_literal
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/track_changes_support.dart';
import 'package:test/test.dart';

import 'firestore_test.dart';

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
    });

    test('updatesOnSnapshotSupport', () async {
      var testsRef = getTestsRef();
      var docRef = testsRef.doc('simple_updatesOnSnapshotSupport');
      await docRef.delete();
      var pullOptions =
          TrackChangesPullOptions(refreshDelay: Duration(milliseconds: 200));
      var updated = docRef
          .onSnapshotSupport(options: pullOptions)
          .firstWhere((element) => element.dataOrNull?['test'] == 2);
      await Future<void>.delayed(Duration(milliseconds: 300));
      await docRef.set({'test': 1});
      await Future<void>.delayed(Duration(milliseconds: 300));
      await docRef.set({'test': 2});
      await updated;
    });
  });
}
