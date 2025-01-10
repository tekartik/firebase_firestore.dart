import 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';

import 'firestore_test.dart';

void vectorValueGroup(
    {required Firestore firestore,
    required FirestoreTestContext? testContext}) {
  String vectorValueGetTestPath(String path) => url.join(
      FirestoreTestContext.getRootCollectionPath(testContext),
      'vectorValue',
      path);

  group('vectorValue_data', () {
    test('bad vector', () async {
      var docPath = vectorValueGetTestPath('vectorValue/vectorValue');
      var docRef = firestore.doc(docPath);
      try {
        await docRef.set({
          'foo': const VectorValue([]),
        });
        fail('Should have thrown an exception');
      } catch (e) {
        print(e);
        /*
        expect(e, isA<FirebaseException>());
        expect(
          (e as FirebaseException).code.contains('invalid-argument'),
          isTrue,
        );*/
      }
      final maxPlusOneDimensions = List<double>.filled(2049, 1);
      try {
        await docRef.set({
          'foo': maxPlusOneDimensions,
        });
        fail('Should have thrown an exception');
      } catch (e) {
        print(e);
        /*
        expect(e, isA<FirebaseException>());
        expect(
          (e as FirebaseException).code.contains('invalid-argument'),
          isTrue,
        );*/
      }
      try {
        await docRef.set({
          'foo': [
            VectorValue([1])
          ],
        });
        fail('Should have thrown an exception');
      } catch (e) {
        print(e);
        /*
        expect(e, isA<FirebaseException>());
        expect(
          (e as FirebaseException).code.contains('invalid-argument'),
          isTrue,
        );*/
      }
    });
    test('All vector value', () async {
      var docPath = vectorValueGetTestPath('vectorValue/vectorValue');
      var docRef = firestore.doc(docPath);
      for (var vector in [
        [1],
        [1, 2],
        [1, -1.0],
        List.filled(2048, 1),
        [3.14, 2.718],
        [-42.0, -100.0]
      ]) {
        await docRef.set({
          'foo': vector,
        });
        expect((await docRef.get()).data, {
          'foo': vector,
        });
      }
    });
    test('vectorValue top level set update', () async {
      // Assume initialized
      var docPath = vectorValueGetTestPath('vectorValue/vectorValue');
      var docRef = firestore.doc(docPath);

      var v1 = VectorValue([1, 2000000]);
      var map = {'v1': v1};
      await docRef.set(map);
      expect((await docRef.get()).data, map);
      v1 = VectorValue([-1.0]);
      map = {'v1': v1};
      await docRef.set(map);
      expect((await docRef.get()).data, map);
    });

    test('vectorValue in list', () async {
      // Assume initialized
      var docRef = firestore
          .doc(vectorValueGetTestPath('vectorValue/vectorValue_in_list'));
      var t1 = VectorValue([1, 2000000]);
      var map = {
        't1s': [t1]
      };
      await docRef.set(map);
      expect((await docRef.get()).data, map);
    }, skip: 'not supported on firestore');
    test('vectorValue in map list', () async {
      // Assume initialized
      var docRef = firestore
          .doc(vectorValueGetTestPath('vectorValue/vectorValue_in_map_list'));
      var t1 = VectorValue([1, 2000000]);
      var map = {
        't1': {'value': t1}
      };
      await docRef.set(map);
      expect((await docRef.get()).data, map);
    });
  }, skip: !firestore.service.supportsVectorValue);
}
