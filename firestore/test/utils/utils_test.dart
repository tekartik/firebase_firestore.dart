import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/auto_id_generator.dart';
import 'package:tekartik_firebase_firestore/utils/firestore_mixin.dart';
import 'package:tekartik_firebase_firestore/utils/json_utils.dart';
import 'package:tekartik_firebase_firestore/utils/timestamp_utils.dart';
import 'package:test/test.dart';

import '../src_firestore_common_test.dart';

class DocumentSnapshotMock extends DocumentSnapshotBase {
  DocumentSnapshotMock(
      {required DocumentReference ref,
      RecordMetaData? meta,
      DocumentDataMap? documentData,
      bool? exists})
      : super(ref, meta, documentData, exists: exists);
}

void main() {
  group('utils', () {
    test('mapCreateTime', () {
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

    test('mapQueryInfo', () {
      DocumentSnapshotBase _snapshot(String id, int value) {
        return DocumentSnapshotMock(
            ref: DocumentReferenceMock(id),
            documentData:
                DocumentDataMap(map: <String, Object?>{'value': value}));
      }

      var queryInfo = QueryInfo()
        ..orderBys = [
          OrderByInfo(fieldPath: 'value', ascending: false),
          OrderByInfo(fieldPath: firestoreNameFieldPath, ascending: true)
        ]
        ..startAt(values: [2, 'b']);
      expect(snapshotMapQueryInfo(_snapshot('a', 1), queryInfo), isTrue);
      expect(snapshotMapQueryInfo(_snapshot('c', 1), queryInfo), isTrue);
      expect(snapshotMapQueryInfo(_snapshot('b', 2), queryInfo), isTrue);
      expect(snapshotMapQueryInfo(_snapshot('a', 2), queryInfo), isFalse);
      expect(snapshotMapQueryInfo(_snapshot('c', 2), queryInfo), isTrue);
      expect(snapshotMapQueryInfo(_snapshot('c', 3), queryInfo), isFalse);
    });

    test('auto_id_generator', () {
      expect(AutoIdGenerator.autoId(), hasLength(20));
    });
  });
}
