import 'package:path/path.dart';
import 'package:tekartik_firebase_firestore/utils/path_utils.dart';
import 'package:test/test.dart';

void main() {
  group('path_utils', () {
    test('parentPath', () {
      expect(url.dirname('some root dir name'), '.');
      expect(getParentPathOrNull('some root dir name'), isNull);
      expect(getParentPathOrNull(''), isNull);
      expect(getParentPathOrNull('/'), isNull);
      expect(getParentPathOrNull('.'), isNull);
    });
  });
}
