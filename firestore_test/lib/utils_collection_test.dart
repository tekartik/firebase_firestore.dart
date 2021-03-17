import 'package:path/path.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/collection.dart';
import 'package:test/test.dart';

void runApp(
    {required FirestoreService firestoreService,
    required Firestore firestore}) {
  group('utils_collection', () {
    var testsRefPath = 'tests/tekartik_firebase_firestore/tests';

    test('deleteCollection', () async {
      var ref = firestore
          .collection(url.join(testsRefPath, 'utils_collection', 'delete'))!;
      var itemDoc = ref.doc('item');
      // create an item
      await itemDoc.set({});

      Future<bool> findInCollection() async {
        var querySnapshot = await ref.get();
        for (var doc in querySnapshot.docs) {
          if (doc.ref!.path == itemDoc.path) {
            return true;
          }
        }
        return false;
      }

      expect(await findInCollection(), isTrue);
      await deleteCollection(firestore, ref);
      expect(await findInCollection(), isFalse);
    });
  });
}
