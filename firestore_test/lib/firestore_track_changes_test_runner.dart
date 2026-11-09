// ignore_for_file: inference_failure_on_collection_literal
import 'dart:async';

import 'package:dev_test/test.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/collection.dart';
import 'package:tekartik_firebase_firestore/utils/firestore_mixin.dart'
    show FirestoreSubscriptionMixin;

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
      var firstSnapshotCompleter = Completer<void>();
      var addedCompleter = Completer<void>();
      var removedCompleter = Completer<void>();
      var subscription = query.onSnapshot().listen((snapshot) {
        if (!firstSnapshotCompleter.isCompleted) {
          firstSnapshotCompleter.complete();
        }
        for (var change in snapshot.documentChanges) {
          if (change.document.ref.path != docRef.path) {
            continue;
          }
          if (change.type == DocumentChangeType.added) {
            if (!addedCompleter.isCompleted) {
              addedCompleter.complete();
            }
          } else if (change.type == DocumentChangeType.removed &&
              addedCompleter.isCompleted) {
            if (!removedCompleter.isCompleted) {
              removedCompleter.complete();
            }
          }
        }
      });
      // The listener itself must see each state before the next write:
      // another listener can be ahead, and a listener can skip a state (the
      // set and the update seen as one snapshot), as in Firestore.
      const timeout = Duration(seconds: 30);
      await firstSnapshotCompleter.future.timeout(timeout);
      await docRef.set({'value': 1});
      await addedCompleter.future.timeout(timeout);
      // No longer matching the query
      await docRef.update({'value': 2});
      await removedCompleter.future.timeout(timeout);
      await subscription.cancel();
    }, skip: !firestoreService.supportsTrackChanges);

    test('document snapshots in order', () async {
      var docRef = getTestsRef().doc('document_snapshots_in_order');
      await docRef.delete();
      var values = <int>[];
      var lastValueCompleter = Completer<void>();
      var subscription = docRef.onSnapshot().listen((snapshot) {
        // 0 for a missing document.
        var value = snapshot.exists ? snapshot.data['value'] as int : 0;
        values.add(value);
        if (value == 3 && !lastValueCompleter.isCompleted) {
          lastValueCompleter.complete();
        }
      });
      // Written without waiting for the first snapshot.
      for (var value in [1, 2, 3]) {
        await docRef.set({'value': value});
      }
      await lastValueCompleter.future.timeout(const Duration(seconds: 30));
      await subscription.cancel();
      // A state can be skipped, never sent after a newer one.
      for (var i = 1; i < values.length; i++) {
        expect(
          values[i],
          greaterThanOrEqualTo(values[i - 1]),
          reason: 'values $values',
        );
      }
    }, skip: !firestoreService.supportsRecordTrackChanges);

    test('query snapshots in order', () async {
      var collRef = getTestsRef()
          .doc('query_snapshots_in_order')
          .collection('test');
      await deleteCollection(firestore, collRef);
      var query = collRef.where('value', isEqualTo: 1);
      var docA = collRef.doc('a');
      var docB = collRef.doc('b');
      var docC = collRef.doc('c');
      Set<String> snapshotPaths(QuerySnapshot snapshot) =>
          snapshot.docs.map((doc) => doc.ref.path).toSet();
      var snapshots = <QuerySnapshot>[];
      var finalStateCompleter = Completer<void>();
      var subscription = query.onSnapshot().listen((snapshot) {
        snapshots.add(snapshot);
        // Only the last write leads to this state.
        var paths = snapshotPaths(snapshot);
        if (paths.length == 1 &&
            paths.contains(docC.path) &&
            !finalStateCompleter.isCompleted) {
          finalStateCompleter.complete();
        }
      });
      // Written without waiting for the first snapshot, the query matches
      // {a}, {a, b}, {b}, {b, c} then {c}.
      await docA.set({'value': 1});
      await docB.set({'value': 1});
      await docA.update({'value': 2});
      await docC.set({'value': 1});
      await docB.delete();
      await finalStateCompleter.future.timeout(const Duration(seconds: 30));
      await subscription.cancel();

      // Each snapshot is the previous one with its changes applied.
      var previousPaths = <String>{};
      for (var (index, snapshot) in snapshots.indexed) {
        var reason = 'snapshot $index';
        var paths = {...previousPaths};
        for (var change in snapshot.documentChanges) {
          var path = change.document.ref.path;
          switch (change.type) {
            case DocumentChangeType.added:
              expect(previousPaths, isNot(contains(path)), reason: reason);
              paths.add(path);
            case DocumentChangeType.removed:
              expect(previousPaths, contains(path), reason: reason);
              paths.remove(path);
            case DocumentChangeType.modified:
              expect(previousPaths, contains(path), reason: reason);
          }
        }
        expect(snapshotPaths(snapshot), paths, reason: reason);
        previousPaths = paths;
      }
    }, skip: !firestoreService.supportsTrackChanges);

    test('cancel releases the listener', () async {
      // Implementation specific (FirestoreSubscriptionMixin: in memory,
      // sembast, idb, sdb): a cancelled listener no longer holds its path.
      var collRef = getTestsRef().doc('cancel_releases').collection('listened');
      var docRef = collRef.doc('doc');
      await docRef.set({'value': 1});
      for (var listen in [
        () => docRef.onSnapshot().listen((_) {}),
        () => collRef.onSnapshot().listen((_) {}),
        () => collRef.where('value', isEqualTo: 1).onSnapshot().listen((_) {}),
      ]) {
        var subscription = listen();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await subscription.cancel();
      }
      var subscriptions =
          (firestore as FirestoreSubscriptionMixin).subscriptions;
      expect(subscriptions.keys, isNot(contains(docRef.path)));
      expect(subscriptions.keys, isNot(contains(collRef.path)));
    }, skip: firestore is! FirestoreSubscriptionMixin);

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
