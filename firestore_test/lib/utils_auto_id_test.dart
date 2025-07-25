import 'dart:math';

import 'package:dev_test/test.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/auto_id_generator.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';

void utilsAutoIdTest({
  required Firestore firestore,
  required FirestoreTestContext? testContext,
}) {
  var testsRefPath = FirestoreTestContext.getRootCollectionPath(testContext);
  CollectionReference getTestsRef() {
    return firestore.collection(testsRefPath);
  }

  group('utils_auto_id', () {
    test('txnGenerateUniqueId', () async {
      String? id;
      await firestore.runTransaction((txn) async {
        id = await getTestsRef().txnGenerateUniqueId(txn);
      });
      expect(id, isNotNull);
    });

    test('custom txnGenerateUniqueId', () async {
      var alphabet = ['a', 'b', 'c', 'd', 'e'];
      var genId = await firestore.runTransaction((txn) async {
        return await getTestsRef().txnGenerateUniqueId(
          txn,
          customGenerator: () => alphabet[Random().nextInt(alphabet.length)],
        );
      });
      expect(alphabet, contains(genId));
    });
  });
}
