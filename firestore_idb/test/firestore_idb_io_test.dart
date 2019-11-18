@TestOn('vm')
library tekartik_firebase_firestore_idb.firestore_idb_io_test;

import 'package:idb_shim/idb.dart';
import 'package:idb_shim/idb_io.dart';
import 'package:path/path.dart';
import 'package:tekartik_firebase_firestore_idb/firestore_idb.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

import 'firestore_idb_test.dart';

void main() async {
  IdbFactory idbFactory = getIdbFactorySembastIo(
      join('.dart_tool', 'tekartik_firebase_firestore_idb', 'test'));
  var firestoreService = getFirestoreService(idbFactory);
  var firebase = FirebaseLocal();
  idbTestInit();
  group('io', () {
    test('factory', () {
      expect(firestoreService.supportsQuerySelect, isTrue);
    });
    run(
      firebase: firebase,
      firestoreService: firestoreService,
    );
  });
}
