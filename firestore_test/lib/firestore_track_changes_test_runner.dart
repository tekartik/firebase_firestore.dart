// ignore_for_file: inference_failure_on_collection_literal
import 'dart:async';

import 'package:dev_test/test.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/collection.dart';

import 'firestore_test_runner.dart';

/// Run firestore track changes tests.
void runFirestoreTrackChangesTests({
  required FirestoreService firestoreService,
  required Firestore firestore,
  required FirestoreTestContext? testContext,
}) {
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
    }, skip: !firestoreService.supportsRecordTrackChanges);

    test('twoRefToSameDocOnSnapshot', () async {
      var testsRef = getTestsRef();
      var docRef1 = testsRef.doc('two_ref_same_doc_onSnapshot');
      var docRef2 = testsRef.doc('two_ref_same_doc_onSnapshot');
      await docRef1.delete();

      await docRef1.onSnapshot().where((doc) => !doc.exists).first;
      await docRef2.onSnapshot().where((doc) => !doc.exists).first;
      var completer1 = Completer<void>();
      var completer2 = Completer<void>();
      var subscription1 = docRef1.onSnapshot().listen((event) {
        if (event.exists && event.data['test'] == 2) {
          completer1.complete();
        }
      });
      var subscription2 = docRef2.onSnapshot().listen((event) {
        if (event.exists && event.data['test'] == 1) {
          completer2.complete();
        }
      });
      await docRef1.set({'test': 1});

      await completer2.future;
      await subscription2.cancel();
      await docRef2.set({'test': 2});
      await completer1.future;

      await subscription1.cancel();
    }, skip: !firestoreService.supportsRecordTrackChanges);

    test('twoRefToSameCollectionOnSnapshot', () async {
      var testsRef = getTestsRef();
      var collRef1 = testsRef
          .doc('two_ref_same_coll_onSnapshot')
          .collection('test');
      var collRef2 = testsRef
          .doc('two_ref_same_coll_onSnapshot')
          .collection('test');
      var docRef = collRef1.doc('doc1');
      await deleteCollection(firestore, collRef1);

      await collRef1
          .onSnapshot()
          .where((snapshot) => snapshot.docs.isEmpty)
          .first;
      await collRef2
          .onSnapshot()
          .where((snapshot) => snapshot.docs.isEmpty)
          .first;
      var completer1 = Completer<void>();
      var completer2 = Completer<void>();
      var subscription1 = collRef1.onSnapshot().listen((snapshot) {
        var docSnapshot = snapshot.docs
            .where((doc) => doc.ref.id == docRef.id)
            .firstOrNull;
        if (docSnapshot?.data['test'] == 2) {
          completer1.complete();
        }
      });
      var subscription2 = collRef2.onSnapshot().listen((snapshot) {
        var docSnapshot = snapshot.docs
            .where((doc) => doc.ref.id == docRef.id)
            .firstOrNull;
        if (docSnapshot?.data['test'] == 1) {
          completer2.complete();
        }
      });
      await docRef.set({'test': 1});
      await completer2.future;
      await subscription2.cancel();
      await docRef.set({'test': 2});
      await completer1.future;

      await subscription1.cancel();
    }, skip: !firestoreService.supportsTrackChanges);

    test('query twoRefToSameCollectionOnSnapshot', () async {
      var testsRef = getTestsRef();
      var collRef1 = testsRef
          .doc('two_ref_same_coll_onSnapshot')
          .collection('test');
      var collRef2 = testsRef
          .doc('two_ref_same_coll_onSnapshot')
          .collection('test');
      var docRef = collRef1.doc('doc1');
      var query1 = collRef1.limit(10);
      var query2 = collRef2.limit(5);
      await deleteCollection(firestore, collRef1);

      await query1
          .onSnapshot()
          .where((snapshot) => snapshot.docs.isEmpty)
          .first;
      await query2
          .onSnapshot()
          .where((snapshot) => snapshot.docs.isEmpty)
          .first;
      var completer1 = Completer<void>();
      var completer2 = Completer<void>();
      var subscription1 = query1.onSnapshot().listen((snapshot) {
        var docSnapshot = snapshot.docs
            .where((doc) => doc.ref.id == docRef.id)
            .firstOrNull;
        if (docSnapshot?.data['test'] == 2) {
          completer1.complete();
        }
      });
      var subscription2 = query2.onSnapshot().listen((snapshot) {
        var docSnapshot = snapshot.docs
            .where((doc) => doc.ref.id == docRef.id)
            .firstOrNull;
        if (docSnapshot?.data['test'] == 1) {
          completer2.complete();
        }
      });
      await docRef.set({'test': 1});
      await completer2.future;
      await subscription2.cancel();
      await docRef.set({'test': 2});
      await completer1.future;

      await subscription1.cancel();
    }, skip: !firestoreService.supportsTrackChanges);

    test('query document leaving the query', () async {
      var collRef = getTestsRef()
          .doc('query_document_leaving')
          .collection('test');
      var docRef = collRef.doc('doc1');
      await deleteCollection(firestore, collRef);
      var query = collRef.where('value', isEqualTo: 1);
      var removedCompleter = Completer<void>();
      var added = false;
      var subscription = query.onSnapshot().listen((snapshot) {
        for (var change in snapshot.documentChanges) {
          if (change.document.ref.path != docRef.path) {
            continue;
          }
          if (change.type == DocumentChangeType.added) {
            added = true;
          } else if (change.type == DocumentChangeType.removed && added) {
            if (!removedCompleter.isCompleted) {
              removedCompleter.complete();
            }
          }
        }
      });
      await query.onSnapshot().where((s) => s.docs.isEmpty).first;
      await docRef.set({'value': 1});
      await query.onSnapshot().where((s) => s.docs.length == 1).first;
      // No longer matching the query
      await docRef.update({'value': 2});
      await removedCompleter.future.timeout(const Duration(seconds: 30));
      await subscription.cancel();
    }, skip: !firestoreService.supportsTrackChanges);

    test(
      'transaction write notifies',
      () async {
        var docRef = getTestsRef().doc('transaction_write_notifies');
        await docRef.delete();
        var completer = Completer<void>();
        var subscription = docRef.onSnapshot().listen((snapshot) {
          if (snapshot.exists && snapshot.data['value'] == 1) {
            if (!completer.isCompleted) {
              completer.complete();
            }
          }
        });
        await firestore.runTransaction((txn) async {
          await txn.get(docRef);
          txn.set(docRef, {'value': 1});
        });
        await completer.future.timeout(const Duration(seconds: 30));
        await subscription.cancel();
      },
      skip:
          !firestoreService.supportsRecordTrackChanges ||
          !firestore.supportsTransaction,
    );
  });
}
