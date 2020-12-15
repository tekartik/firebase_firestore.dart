import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:test/test.dart';

import 'firestore_test.dart';

void timestampGroup({FirestoreService service, Firestore firestore}) {
  group('timestamp_data', () {
    test('timestamp top level', () async {
      // Assume initialized
      var docRef = firestore.doc(getTestPath('browser/timestamp'));
      var t1 = Timestamp(1, 2000000);
      var map = {'t1': t1};
      await docRef.set(map);
      expect((await docRef.get()).data, map);
    });

    test('timestamp in list', () async {
      // Assume initialized
      var docRef = firestore.doc(getTestPath('browser/timestamp_in_list'));
      var t1 = Timestamp(1, 2000000);
      var map = {
        't1s': [t1]
      };
      await docRef.set(map);
      expect((await docRef.get()).data, map);
    });
    test('timestamp in map list', () async {
      // Assume initialized
      var docRef = firestore.doc(getTestPath('browser/timestamp_in_map_list'));
      var t1 = Timestamp(1, 2000000);
      var map = {
        't1': {'value': t1}
      };
      await docRef.set(map);
      expect((await docRef.get()).data, map);
    });
  }, skip: !service.supportsTimestampsInSnapshots);
}
