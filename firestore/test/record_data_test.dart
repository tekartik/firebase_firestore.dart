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
            ..setFieldValue(
              'd',
              FieldValueArray(FieldValueType.arrayUnion, ['item-1']),
            ),
        ),
        {
          'a': 1,
          'c': 3,
          'd': ['item-1'],
        },
      );
    });
    test('fieldArrayValueMergeValue', () {
      expect(
        fieldArrayValueMergeValue(
          FieldValueArray(FieldValueType.arrayUnion, ['a']),
          null,
        ),
        ['a'],
      );
      expect(
        fieldArrayValueMergeValue(
          FieldValueArray(FieldValueType.arrayRemove, ['a']),
          ['a', 'b'],
        ),
        ['b'],
      );
      expect(
        fieldArrayValueMergeValue(
          FieldValueArray(FieldValueType.arrayUnion, ['a']),
          ['a', 'b'],
        ),
        ['a', 'b'],
      );
    });

    test('fieldValueIncrementMergeValue', () {
      expect(fieldValueIncrementMergeValue(FieldValueIncrement(1), null), 1);
      expect(fieldValueIncrementMergeValue(FieldValueIncrement(1), 2), 3);
      expect(fieldValueIncrementMergeValue(FieldValueIncrement(-3), 2), -1);
      expect(fieldValueIncrementMergeValue(FieldValueIncrement(1.5), 2), 3.5);
      expect(fieldValueIncrementMergeValue(FieldValueIncrement(1), 2.5), 3.5);
      // Non numeric existing value: set to the increment value
      expect(fieldValueIncrementMergeValue(FieldValueIncrement(1), 'text'), 1);
      expect(fieldValueIncrementMergeValue(FieldValueIncrement(1), [2]), 1);
    });
    test('recordMapValueAtFieldPath', () {
      var map = {
        'a': 1,
        'b': {'c': 2, 'd.e': 3},
      };
      expect(recordMapValueAtFieldPath(map, 'a'), 1);
      expect(recordMapValueAtFieldPath(map, 'b.c'), 2);
      // Backtick escaping applies to a whole key only
      expect(recordMapValueAtFieldPath({'d.e': 3}, '`d.e`'), 3);
      expect(recordMapValueAtFieldPath(map, 'b'), {'c': 2, 'd.e': 3});
      expect(recordMapValueAtFieldPath(map, 'a.b'), isNull);
      expect(recordMapValueAtFieldPath(map, 'x'), isNull);
      expect(recordMapValueAtFieldPath(map, 'b.x.y'), isNull);
    });
    test('updateDataResolveIncrements', () {
      expect(
        updateDataResolveIncrements(
          {
            'a': FieldValue.increment(1),
            'b.c': FieldValue.increment(2),
            'd': FieldValue.increment(3),
            'e': {'f': FieldValue.increment(4)},
            'g': 5,
          },
          {
            'a': 1,
            'b': {'c': 2},
          },
        ),
        {
          'a': 2,
          'b.c': 4,
          'd': 3,
          'e': {'f': isA<FieldValueIncrement>()},
          'g': 5,
        },
      );
      expect(
        updateDataResolveIncrements({'a': FieldValue.increment(1)}, null),
        {'a': 1},
      );
    });
    test('recordMapUpdate nested', () {
      expect(
        recordMapUpdate(
          {
            'a': {
              'b': {'c': 1, 'd': 2},
              'e': 3,
            },
            'f': 4,
          },
          DocumentData()
            ..setInt('a.b.c', 11)
            ..setFieldValue('a.b.d', FieldValue.delete)
            ..setInt('a.g.h', 5)
            ..setInt('f.i', 6)
            ..setData('j', DocumentData({'k': 7})),
        ),
        {
          'a': {
            'b': {'c': 11},
            'e': 3,
            'g': {'h': 5},
          },
          'f': {'i': 6},
          'j': {'k': 7},
        },
      );
    });
    test('recordMapUpdate increment', () {
      expect(
        recordMapUpdate(
          {
            'a': 1,
            'b': {'c': 2, 'other': 3},
            'd': 'text',
          },
          DocumentData()
            ..setFieldValue('a', FieldValue.increment(2))
            ..setFieldValue('b.c', FieldValue.increment(1.5))
            ..setFieldValue('d', FieldValue.increment(1))
            ..setFieldValue('e', FieldValue.increment(4)),
        ),
        {
          'a': 3,
          'b': {'c': 3.5, 'other': 3},
          'd': 1,
          'e': 4,
        },
      );
    });
    test('merge increment', () {
      var documentData = DocumentData(<String, Object?>{
        'a': 1,
        'b': <String, Object?>{'c': 2, 'other': 3},
        'd': 'text',
      });
      documentData.merge(
        DocumentData({
          'a': FieldValue.increment(2),
          'b': {'c': FieldValue.increment(1.5)},
          'd': FieldValue.increment(1),
          'e': FieldValue.increment(4),
        }),
      );
      expect(documentData.asMap(), {
        'a': 3,
        'b': {'c': 3.5, 'other': 3},
        'd': 1,
        'e': 4,
      });
    });
    test('valueToJsonRecordValue increment', () {
      // No existing value, the increment value is used
      expect(valueToJsonRecordValue(FieldValue.increment(2)), 2);
      expect(
        valueToJsonRecordValue({
          'a': FieldValue.increment(1.5),
          'b': [FieldValue.increment(3)],
        }),
        {
          'a': 1.5,
          'b': [3],
        },
      );
    });
    test('FieldValue.increment', () {
      var fieldValue = FieldValue.increment(2);
      expect(fieldValue, isA<FieldValueIncrement>());
      expect(fieldValue.type, FieldValueType.increment);
      expect(fieldValue.data, 2);
      expect(fieldValue.toString(), 'FieldValueIncrement(2)');
    });

    test('documentDataToRecordMap merge', () {
      // ignore: deprecated_member_use_from_same_package
      var map = documentDataToRecordMap(DocumentDataMap(map: {'test1': 1}), {
        'test2': 2,
      });
      expect(map, {'test1': 1, 'test2': 2});
    });
    test('documentDataToRecordMap deep merge', () {
      // ignore: deprecated_member_use_from_same_package
      var map = documentDataToRecordMap(
        DocumentDataMap(
          map: {
            'sub': {'test1': 1},
          },
        ),
        {
          'sub': {'test2': 2},
        },
      );
      expect(map, {
        'sub': {'test1': 1, 'test2': 2},
      });
    });
  });
}
