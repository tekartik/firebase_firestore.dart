import 'package:tekartik_firebase_firestore/firestore_logger.dart';
import 'package:tekartik_firebase_firestore/utils/firestore_mock.dart';
import 'package:test/test.dart';

void main() {
  group('firestore_logger', () {
    var firestore = FirestoreMock();

    var firestoreLogger = FirestoreLogger(
        firestore: firestore, options: FirestoreLoggerOptions.all());

    test('document', () {
      var doc1 = firestore.doc('test/doc');
      var doc2 = firestoreLogger.doc('test/doc');
      expect(doc1, doc2);
    });
    test('collection', () {
      var coll1 = firestore.collection('test');
      var coll2 = firestoreLogger.collection('test');
      expect(coll1, coll2);
    });
  });
}
