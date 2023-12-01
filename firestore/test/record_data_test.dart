import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/firestore.dart';
import 'package:tekartik_firebase_firestore/src/record_data.dart';
import 'package:test/test.dart';

void main() {
  group('record_data', () {
    test('recordMapUpdate', () {
      expect(recordMapUpdate(null, null), isNull);
      expect(recordMapUpdate({}, null), isEmpty);
      expect(recordMapUpdate(null, DocumentData()), isEmpty);
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

    test('documentDataToRecordMap merge', () {
      // ignore: deprecated_member_use_from_same_package
      var map = documentDataToRecordMap(
          DocumentDataMap(map: {'test1': 1}), {'test2': 2});
      expect(map, {'test1': 1, 'test2': 2});
    });
    test('documentDataToRecordMap deep merge', () {
      // ignore: deprecated_member_use_from_same_package
      var map = documentDataToRecordMap(
          DocumentDataMap(map: {
            'sub': {'test1': 1}
          }),
          {
            'sub': {'test2': 2}
          });
      expect(map, {
        'sub': {'test1': 1, 'test2': 2}
      });
    });
  });
}
