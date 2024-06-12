library tekartik_firebase_sembast.firebase_sembast_memory_test;

import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  // needed for memory
  skipConcurrentTransactionTests = true;
  var firebase = FirebaseLocal();
  runFirestoreTests(
      firebase: firebase, firestoreService: newFirestoreServiceMemory());

  test('newInMemory', () async {
    var firestoreService1 = newFirestoreServiceMemory();
    var firestoreService2 = newFirestoreServiceMemory();
    var app = firebase.app();
    var firestore1 = firestoreService1.firestore(app);
    var firestore2 = firestoreService2.firestore(app);
    var docPath = 'tests/doc';
    var doc1Ref = firestore1.doc(docPath);
    var doc2Ref = firestore2.doc(docPath);
    await doc1Ref.set({'test': 1});
    await doc2Ref.set({'test': 2});
    expect((await doc1Ref.get()).data, {'test': 1});
    expect((await doc2Ref.get()).data, {'test': 2});
  });

  test('newFirestoreMemory', () async {
    var firestore1 = newFirestoreMemory();
    var firestore2 = newFirestoreMemory();
    var docPath = 'tests/doc';
    var doc1Ref = firestore1.doc(docPath);
    var doc2Ref = firestore2.doc(docPath);
    await doc1Ref.set({'test': 1});
    await doc2Ref.set({'test': 2});
    expect((await doc1Ref.get()).data, {'test': 1});
    expect((await doc2Ref.get()).data, {'test': 2});
  });
}
