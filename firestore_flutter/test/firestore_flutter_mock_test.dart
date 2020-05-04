library tekartik_firestore_flutter.test.firestore_flutter_test;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_firebase_firestore_flutter/src/firestore_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('firestore_flutter_mock', () {
    test('ref', () {
      var firestore = FirestoreFlutter(Firestore.instance);

      var docRef = firestore.doc('test/doc');
      expect(docRef.path, 'test/doc');
      expect(docRef.toString(), 'DocRef(test/doc)');

      var collRef = firestore.collection('test');
      expect(collRef.path, 'test');
      expect(collRef.toString(), 'CollRef(test)');
    });
  });
}
