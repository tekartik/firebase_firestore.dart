import 'package:test/test.dart';

import 'common/mixin_test.dart';

//import 'src_firestore_common_test.dart';

void main() {
  var firestore = FirestoreMock();
  var firestoreService = FirestoreServiceMock();
  group('Mock', () {
    test('service', () {
      expect(firestoreService.supportsListCollectionIds, isFalse);
    });
    test('documentReference', () {
      expect(firestore.doc('test'), firestore.doc('test'));
    });
  });
}
