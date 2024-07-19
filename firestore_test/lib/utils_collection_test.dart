import 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/collection.dart';

import 'firestore_test.dart';

void runUtilsCollectionTests(
    {required FirestoreService firestoreService,
    required Firestore firestore,
    required FirestoreTestContext? testContext}) {
  group('utils_collection', () {
    var testsRefPath = FirestoreTestContext.getRootCollectionPath(testContext);

    test('deleteCollection one', () async {
      var ref = firestore
          .collection(url.join(testsRefPath, 'utils_collection', 'delete_one'));
      await deleteCollection(firestore, ref);
      var itemDoc = ref.doc('item');
      // create an item
      await itemDoc.set({});

      Future<bool> findInCollection() async {
        var querySnapshot = await ref.get();
        for (var doc in querySnapshot.docs) {
          if (doc.ref.path == itemDoc.path) {
            return true;
          }
        }
        return false;
      }

      expect(await findInCollection(), isTrue);
      var count = await deleteCollection(firestore, ref);
      expect(count, 1);
      try {
        expect(await findInCollection(), isFalse);
      } catch (_) {
        if (testContext?.allowedDelayInReadMs != null) {
          await testContext?.sleepReadDelay();
          expect(await findInCollection(), isFalse);
        } else {
          rethrow;
        }
      }
    });

    test('deleteCollection two', () async {
      var ref = firestore
          .collection(url.join(testsRefPath, 'utils_collection', 'delete_two'));
      await deleteCollection(firestore, ref);
      var itemDoc = ref.doc('item1');
      var itemDoc2 = ref.doc('item2');
      // create two items
      await firestore.runTransaction((txn) {
        txn.set(itemDoc, {});
        txn.set(itemDoc2, {});
      });

      Future<bool> findInCollection() async {
        var querySnapshot = await ref.get();
        for (var doc in querySnapshot.docs) {
          if (doc.ref.path == itemDoc.path) {
            return true;
          }
        }
        return false;
      }

      Future<bool> find2InCollection() async {
        var querySnapshot = await ref.get();
        for (var doc in querySnapshot.docs) {
          if (doc.ref.path == itemDoc2.path) {
            return true;
          }
        }
        return false;
      }

      Future<void> check() async {
        expect(await findInCollection(), isTrue);
        expect(await find2InCollection(), isTrue);
      }

      try {
        await check();
      } catch (_) {
        if (testContext?.allowedDelayInReadMs != null) {
          await testContext?.sleepReadDelay();
          await check();
        } else {
          rethrow;
        }
      }

      var count = await deleteCollection(firestore, ref, batchSize: 1);
      expect(count, 2);
      expect(await findInCollection(), isFalse);
      expect(await find2InCollection(), isFalse);
    });

    test('copyCollection one', () async {
      var srcRef = firestore
          .collection(url.join(testsRefPath, 'utils_collection', 'copy_src'));
      var dstRef = firestore
          .collection(url.join(testsRefPath, 'utils_collection', 'copy_dst'));

      await deleteCollection(firestore, srcRef);
      await deleteCollection(firestore, dstRef);
      var srcItemDoc = srcRef.doc('item');
      var dstItemDoc = dstRef.doc('item');
      // create an item
      await srcItemDoc.set({});

      Future<bool> findInCollection() async {
        var querySnapshot = await dstRef.get();
        for (var doc in querySnapshot.docs) {
          if (doc.ref.path == dstItemDoc.path) {
            return true;
          }
        }
        return false;
      }

      expect(await findInCollection(), isFalse);
      var count = await copyCollection(firestore, srcRef, firestore, dstRef);
      expect(count, 1);
      expect(await findInCollection(), isTrue);
    });
  });
}
