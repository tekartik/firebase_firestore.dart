import 'package:meta/meta.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/document.dart';
import 'package:test/test.dart';

var testsRefPath = 'tests/tekartik_firestore/tests';

void utilsTest(
    {@required FirestoreService firestoreService,
    @required Firestore firestore}) {
  CollectionReference getTestsRef() {
    return firestore.collection(testsRefPath);
  }

  group('utils', () {
    test('onDocumentSnapshots', () async {
      var ref1 = getTestsRef().doc('onDocumentSnapshots1');
      var ref2 = getTestsRef().doc('onDocumentSnapshots2');
      await ref1.delete();
      await ref2.delete();
      DocumentSnapshots snapshots;
      Completer completer;

      completer = Completer();
      var subscription = onDocumentSnapshots([ref1, ref2]).listen((event) {
        completer.complete();
        snapshots = event;
      });
      await completer.future;
      expect(snapshots.docs.length, 2);
      expect(snapshots.docs[0].exists, false);
      expect(snapshots.docs[0].data, isNull);
      expect(snapshots.docs[1].exists, false);
      expect(snapshots.docs[1].data, isNull);

      completer = Completer();
      unawaited(ref1.set({'test': 1}));
      await completer.future;
      expect(snapshots.docs.length, 2);
      expect(snapshots.docs[0].data, {'test': 1});
      expect(snapshots.getDocument(ref1).data, {'test': 1});

      await subscription.cancel();
    }, skip: !firestoreService.supportsTrackChanges);
  });
}
