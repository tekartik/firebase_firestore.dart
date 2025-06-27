import 'package:tekartik_firebase_firestore/src/common/firestore_mock.dart';
import 'package:tekartik_firebase_firestore/src/common/import_firestore_mixin.dart';
import 'package:tekartik_firebase_firestore/src/firestore_common.dart';
import 'package:test/test.dart';

//import 'src_firestore_common_test.dart';

void main() {
  var firestore = FirestoreMock();
  var firestoreService = FirestoreServiceMock();
  group('Mock', () {
    test('service', () {
      expect(firestoreService.supportsListCollections, isFalse);
      expect(firestoreService.supportsAggregateQueries, isFalse);
    });
    test('documentReference', () {
      expect(firestore.doc('test/doc'), firestore.doc('test/doc'));
      expect(firestore.collection('test').parent, isNull);
    });
    test('parent', () {
      expect(
        firestore.doc('test/doc').parent,
        CollectionReferenceMock(firestore, 'test'),
      );
    });
    test('query', () {
      var queryInfo = QueryInfo()
        ..limit = 1
        ..startLimit = LimitInfo(values: [1], inclusive: true);
      var query =
          (applyQueryInfoNoDocumentId(firestore, 'test', queryInfo))
              as QueryMock;
      expect(query.queryInfo.limit, 1);
      expect(query.queryInfo.startLimit!.values, [1]);
    });
  });
}
