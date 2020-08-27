library tekartik_firestore_flutter.test.firestore_flutter_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:tekartik_firebase_firestore_flutter/src/firestore_flutter.dart';

class CollectionReferenceFlutterMock extends CollectionReferenceFlutter {
  @override
  final String path;

  CollectionReferenceFlutterMock(this.path) : super(null);
}

class DocumentReferenceFlutterMock extends DocumentReferenceFlutter {
  @override
  final String path;

  DocumentReferenceFlutterMock(this.path) : super(null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('firestore_flutter_mock', () {
    /*
    test('ref', () {
      var firestore = FirestoreFlutter(FirebaseFirestore.instance);

      var docRef = firestore.doc('test/doc');
      expect(docRef.path, 'test/doc');
      expect(docRef.toString(), 'DocRef(test/doc)');
      expect(docRef, firestore.doc('test/doc'));
      expect(docRef, isNot(firestore.doc('test/doc2')));

      var collRef = firestore.collection('test');
      // NOT supported expect(collRef, firestore.collection('test'));
      // NOT supported expect(collRef, isNot(firestore.collection('test2')));
      expect(collRef.path, 'test');
      expect(collRef.toString(), 'CollRef(test)');
    });
     */
    test('CollectionReference', () {
      var ref1 = CollectionReferenceFlutterMock('path1');
      var ref2 = CollectionReferenceFlutterMock('path1');
      expect(ref1, ref2);
      expect(ref1.hashCode, ref2.hashCode);
      ref2 = CollectionReferenceFlutterMock('path2');
      expect(ref1, isNot(ref2));
    });
    test('DocumentReference', () {
      var ref1 = DocumentReferenceFlutterMock('path1');
      var ref2 = DocumentReferenceFlutterMock('path1');
      expect(ref1, ref2);
      expect(ref1.hashCode, ref2.hashCode);
      ref2 = DocumentReferenceFlutterMock('path2');
      expect(ref1, isNot(ref2));
    });
  });
}
