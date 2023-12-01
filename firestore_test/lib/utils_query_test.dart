import 'package:path/path.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/query.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:test/test.dart';

void runUtilsQueryTest(
    {required FirestoreService firestoreService,
    required Firestore firestore,
    required FirestoreTestContext? testContext}) {
  group('utils_query', () {
    var testsRefPath =
        url.join(FirestoreTestContext.getRootCollectionPath(testContext));

    test('deleteQuery one', () async {
      var ref = firestore
          .collection(url.join(testsRefPath, 'utils_collection', 'delete'));
      var query = ref;
      await deleteQuery(firestore, query);
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
      var count = await deleteQuery(firestore, ref);
      expect(count, 1);
      expect(await findInCollection(), isFalse);
    });

    test('deleteQuery two', () async {
      var ref = firestore
          .collection(url.join(testsRefPath, 'utils_collection', 'delete_two'));
      await deleteQuery(firestore, ref);
      var itemDoc = ref.doc('item1');
      var itemDoc2 = ref.doc('item2');
      // create two items
      await itemDoc.set({});
      await itemDoc2.set({});

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

      expect(await findInCollection(), isTrue);
      expect(await find2InCollection(), isTrue);
      var count = await deleteQuery(firestore, ref, batchSize: 1);
      expect(count, 2);
      expect(await findInCollection(), isFalse);
      expect(await find2InCollection(), isFalse);
    });
  });
}
