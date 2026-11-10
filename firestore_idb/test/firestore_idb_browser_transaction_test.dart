@TestOn('browser')
library;

import 'dart:async';

import 'package:idb_shim/sdb.dart';
import 'package:tekartik_firebase_firestore_idb/firestore_idb_browser.dart';
import 'package:tekartik_firebase_firestore_idb/firestore_sdb.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

/// An IndexedDB transaction commits as soon as its caller awaits something
/// else than its own requests: a runTransaction update function awaiting an
/// http call (here a delay) cannot write anymore. It must fail, not hang.
void main() {
  void transactionGroup(String name, FirestoreService service, {String? skip}) {
    group(name, () {
      late FirebaseApp app;
      late Firestore firestore;
      setUp(() {
        app = FirebaseLocal(
          localPath: 'firestore_idb_browser_transaction_$name',
        ).initializeApp(name: name);
        firestore = service.firestore(app);
      });
      tearDown(() => app.delete());

      test('update function awaiting a delay fails, does not hang', () async {
        var ref = firestore.doc('test/delay');
        await ref.set({'value': 1});
        var future = firestore.runTransaction((txn) async {
          var snapshot = await txn.get(ref);
          await Future<void>.delayed(const Duration(milliseconds: 50));
          txn.set(ref, {'value': (snapshot.data['value'] as int) + 1});
        });
        await expectLater(
          future.timeout(const Duration(seconds: 10)),
          throwsA(isNot(isA<TimeoutException>())),
        );
        expect((await ref.get()).data, {'value': 1});
      });

      test('update function throwing after a delay', () async {
        var ref = firestore.doc('test/delay_throw');
        await ref.set({'value': 1});
        var future = firestore.runTransaction((txn) async {
          await txn.get(ref);
          await Future<void>.delayed(const Duration(milliseconds: 50));
          throw StateError('cancelled');
        });
        await expectLater(
          future.timeout(const Duration(seconds: 10)),
          throwsA(isA<StateError>()),
        );
      });
    }, skip: skip);
  }

  transactionGroup('idb', firestoreServiceIdbBrowser);
  transactionGroup(
    'sdb',
    sdbFactoryWeb.firestoreService,
    skip:
        'idb_shim 2.11.3: the sdb transaction waits for a complete event '
        'already fired (TransactionNative.completed listens lazily)',
  );
}
