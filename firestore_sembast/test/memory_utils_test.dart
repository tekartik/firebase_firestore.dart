import 'package:tekartik_firebase_firestore/utils/collection.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:test/test.dart';

void main() {
  test('copyCollection', () async {
    var firestore1 = newFirestoreMemory();
    var firestore2 = newFirestoreMemory();
    var coll1 = firestore1.collection('test1');
    var coll2 = firestore2.collection('test2');
    var doc1 = coll1.doc('doc1');
    await doc1.set({'test': 1});
    await coll1.copyTo(coll2);
    var coll2Doc1 = coll2.doc('doc1');
    expect((await coll2Doc1.get()).data, {'test': 1});
    var doc2 = coll1.doc('doc2');

    await doc1.delete();
    await doc2.set({'test': 2});
    await coll1.copyTo(coll2);
    expect(await coll2.count(), 2);
    await coll1.copyTo(coll2, clearExisting: true);
    expect(await coll2.count(), 1);
  });
}
