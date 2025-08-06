import 'package:collection/collection.dart';
import 'package:dev_test/test.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';

bool dataMatch(Map<String, dynamic> data1, Map<String, dynamic> data2) {
  return const DeepCollectionEquality().equals(data1, data2);
}

void firestoreMulticlientTest({
  required Firestore firestore1,
  required Firestore firestore2,
  required String docTopPath,
}) {
  // ignore: unused_local_variable
  var skip =
      !firestore1.service.supportsTrackChanges ||
      !firestore2.service.supportsTrackChanges;

  test('multi client get set', () async {
    var doc1 = firestore1.doc('$docTopPath/record/record1');
    var doc2 = firestore2.doc(doc1.path);
    var map1 = {'test': 1};
    var map2 = {'test': 2};
    await doc1.set(map1);
    expect((await doc2.get()).data, map1);
    await doc2.set(map2);
    expect((await doc1.get()).data, map2);
  });
  test('multi client track changes', () async {
    var doc1 = firestore1.doc('$docTopPath/record/record1');
    var doc2 = firestore2.doc(doc1.path);
    var map1 = {'test': 1};
    var map2 = {'test': 2};

    var completer1 = Completer<void>();
    var completer2 = Completer<void>();
    var subscription1 = doc1.onSnapshot().listen((snapshot) {
      if (snapshot.exists && dataMatch(snapshot.data, map2)) {
        completer1.complete();
      }
    });
    var subscription2 = doc2.onSnapshot().listen((snapshot) {
      if (snapshot.exists && dataMatch(snapshot.data, map1)) {
        completer2.complete();
      }
    });
    await doc1.set(map1);
    await completer2.future;
    await subscription2.cancel();

    await doc2.set(map2);
    await completer2.future;
    await subscription1.cancel();
  }, skip: skip);
}
