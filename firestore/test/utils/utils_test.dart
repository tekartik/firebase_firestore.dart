import 'package:tekartik_firebase_firestore/utils/firestore_mixin.dart';
import 'package:tekartik_firebase_firestore/utils/timestamp_utils.dart';
import 'package:test/test.dart';

void main() {
  group('utils', () {
    test('mapCreateTime', () {
      expect(mapCreateTime(null), isNull);
      expect(mapCreateTime({}).toIso8601String(), '2018-10-23T00:00:00.000Z');
    });

    test('comparableList', () {
      expect(ComparableList([1]).compareTo(ComparableList([1])), 0);
      expect(ComparableList([1]).compareTo(ComparableList([2])), lessThan(0));
      expect(
          ComparableList([2]).compareTo(ComparableList([1])), greaterThan(0));
      expect(
          ComparableList([1]).compareTo(ComparableList([1, 0])), lessThan(0));
      expect(ComparableList([1, 0]).compareTo(ComparableList([1])),
          greaterThan(0));
    });
    test('comparableMap', () {
      expect(ComparableMap({}).compareTo(ComparableMap({})), 0);
      expect(
          ComparableMap({'test': 0}).compareTo(ComparableMap({'test': 0})), 0);
      expect(ComparableMap({'test': 0}).compareTo(ComparableMap({'test': 1})),
          lessThan(0));
      expect(ComparableMap({'test': 1}).compareTo(ComparableMap({'test': 0})),
          greaterThan(0));
      expect(
          ComparableMap({'test': 0})
              .compareTo(ComparableMap({'test': 0, 'x': 1})),
          lessThan(0));
      expect(
          ComparableMap({'test': 0, 'x': 1})
              .compareTo(ComparableMap({'test': 0})),
          greaterThan(0));
      expect(ComparableMap({'other': 2}).compareTo(ComparableMap({'test': 1})),
          lessThan(0));
      // inner list
      expect(
          ComparableMap({
            'test': [1]
          }).compareTo(ComparableMap({
            'test': [2]
          })),
          lessThan(0));
      // inner map
      expect(
          ComparableMap({
            'test': [
              {'test': 0}
            ]
          }).compareTo(ComparableMap({
            'test': [
              {'test': 1}
            ]
          })),
          lessThan(0));
    });
  });
}
