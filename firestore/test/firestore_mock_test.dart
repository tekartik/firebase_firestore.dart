import 'package:test/test.dart';

import 'common/mixin_test.dart';

//import 'src_firestore_common_test.dart';

void main() {
  var firestore = FirestoreMock();
  group('Mock', () {
    test('documentReference', () {
      expect(firestore.doc('test'), firestore.doc('test'));
    });
  });
}
