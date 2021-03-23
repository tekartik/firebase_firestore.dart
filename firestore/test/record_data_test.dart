import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/firestore.dart';
import 'package:tekartik_firebase_firestore/src/record_data.dart';
import 'package:test/test.dart';

void main() {
  group('record_data', () {
    test('recordMapUpdate', () {
      expect(recordMapUpdate(null, null), isNull);
      expect(recordMapUpdate({}, null), isNull);
      expect(recordMapUpdate(null, DocumentData()), {});
      expect(
          recordMapUpdate(
              {'a': 1, 'b': 2},
              DocumentData()
                ..setInt('c', 3)
                ..setFieldValue('b', FieldValue.delete)
                ..setFieldValue('d',
                    FieldValueArray(FieldValueType.arrayUnion, ['item-1']))),
          {
            'a': 1,
            'c': 3,
            'd': ['item-1']
          });
    });
    test('fieldArrayValueMergeValue', () {
      expect(
          fieldArrayValueMergeValue(
              FieldValueArray(FieldValueType.arrayUnion, ['a']), null),
          ['a']);
      expect(
          fieldArrayValueMergeValue(
              FieldValueArray(FieldValueType.arrayRemove, ['a']), ['a', 'b']),
          ['b']);
      expect(
          fieldArrayValueMergeValue(
              FieldValueArray(FieldValueType.arrayUnion, ['a']), ['a', 'b']),
          ['a', 'b']);
    });
  });
}
