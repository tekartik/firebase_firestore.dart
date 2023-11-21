import 'package:test/test.dart';

import 'common/mixin_test.dart';

//import 'src_firestore_common_test.dart';

void main() {
  var firestore = FirestoreMock();
  var firestoreService = FirestoreServiceMock();
  group('Mock', () {
    test('service', () {
      expect(firestoreService.supportsListCollections, isFalse);
    });
    test('documentReference', () {
      expect(firestore.doc('test/doc'), firestore.doc('test/doc'));
      expect(firestore.collection('test').parent, isNull);
    });
    test('parent', () {
      expect(firestore.doc('test/doc').parent,
          CollectionReferenceMock(firestore, 'test'));
    });
  });
}
