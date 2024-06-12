library tekartik_firebase_firestore_sembast.firestroage_memory_logger_test;

import 'package:tekartik_firebase_firestore/firestore_logger.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  // needed for memory
  skipConcurrentTransactionTests = true;
  var firebase = FirebaseLocal();

  // Basic check for set
  test('set', () async {
    var firestore = newFirestoreMemory();
    var events = <FirestoreLoggerEvent>[];
    firestore = FirestoreLogger(
        firestore: firestore,
        options: FirestoreLoggerOptions.all(log: (event) {
          events.add(event);
        }));
    var ref = firestore.doc('test/1');
    await ref.set({});
    expect(events.length, 1);

    events.clear();
    await firestore.runTransaction((transaction) {
      transaction.set(ref, {});
    });
    expect(events.length, 1);
  });
  runFirestoreTests(
      firebase: firebase,
      firestoreService: FirestoreServiceLogger(
          firestoreService: newFirestoreServiceMemory(),
          options: FirestoreLoggerOptions.all(log: (_) {})));
}
