import 'package:collection/collection.dart';
import 'package:dev_test/test.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';

bool dataMatch(Map<String, dynamic> data1, Map<String, dynamic> data2) {
  return DeepCollectionEquality().equals(data1, data2);
}

void firestoreMulticlientTest(
    {required Firestore firestore1,
    required Firestore firestore2,
    required String docTopPath}) {
  // ignore: unused_local_variable
  var skip = !firestore1.service.supportsTrackChanges ||
      !firestore2.service.supportsTrackChanges;

  test('multi client', () async {
    var doc1 = firestore1.doc('$docTopPath/record/record1');
    var doc2 = firestore2.doc(doc1.path);
    var map1 = {'test': 1};
    await doc1.set(map1);
    await doc2
        .onSnapshot()
        .firstWhere((snapshot) => dataMatch(snapshot.data, map1));
    var map2 = {'test': 2};
    var future1 = doc1
        .onSnapshot()
        .firstWhere((snapshot) => dataMatch(snapshot.data, map2));
    await doc2.set(map2);
    await future1;
  }, skip: true); // skip ? 'track changes unsupported' : null);
}
