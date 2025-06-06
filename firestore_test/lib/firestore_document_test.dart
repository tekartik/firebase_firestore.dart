// ignore_for_file: inference_failure_on_collection_literal

import 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
// ignore: implementation_imports

import 'firestore_test.dart';

void runFirestoreDocumentTests({
  required Firestore firestore,
  FirestoreTestContext? testContext,
}) {
  var testsRefPath = FirestoreTestContext.getRootCollectionPath(testContext);
  group('document', () {
    test('all types', () async {
      var map = {
        'int': 1,
        'bool': true,
        'list': [1],
        'map': {'test': 1},
        'blob': Blob.fromList([1, 2, 3]),
        'ref': firestore.doc('test/4'),
        'geoPoint': GeoPoint(5, 6),
        'timestamp': Timestamp(7, 8000),
      };
      var doc = firestore.doc(url.join(testsRefPath, 'doc_all_types'));
      await doc.set(map);
      expect((await doc.get()).data, map);
    });
    test('special chars', () async {
      var map = {'some|key': 1, 'other@key': 2};
      var doc = firestore.doc(
        url.join(testsRefPath, 'special_chars', 'some|coll', 'some|doc'),
      );
      await doc.set(map);
      expect((await doc.get()).data, map);
      doc = firestore.doc(
        url.join(testsRefPath, 'special_chars', 'some@coll', 'some@doc'),
      );
      await doc.set(map);
      expect((await doc.get()).data, map);
    });
  });
}
