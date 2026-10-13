library;

import 'package:tekartik_firebase_firestore/firestore_logger.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test_runner.dart';
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
      options: FirestoreLoggerOptions.all(
        log: (event) {
          events.add(event);
        },
      ),
    );
    var ref = firestore.doc('test/1');
    await ref.set({});
    expect(events.length, 1);

    events.clear();
    await firestore.runTransaction((transaction) {
      transaction.set(ref, {});
    });
    expect(events.length, 1);
  });
  test('supports flags', () {
    var service = newFirestoreServiceMemory();
    var logger = FirestoreServiceLogger(
      firestoreService: service,
      options: FirestoreLoggerOptions.all(log: (_) {}),
    );
    expect(logger.supportsListCollections, service.supportsListCollections);
    expect(logger.supportsListCollections, isTrue);
    expect(logger.supportsVectorValue, service.supportsVectorValue);
    expect(logger.supportsVectorValue, isTrue);
    expect(
      logger.supportsRecordTrackChanges,
      service.supportsRecordTrackChanges,
    );
  });
  runFirestoreTests(
    firebase: firebase,
    firestoreService: FirestoreServiceLogger(
      firestoreService: newFirestoreServiceMemory(),
      options: FirestoreLoggerOptions.all(log: (_) {}),
    ),
  );
}
