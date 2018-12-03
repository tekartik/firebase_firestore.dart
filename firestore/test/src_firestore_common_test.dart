import 'dart:async';

import 'package:tekartik_firebase_firestore/src/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/firestore_mixin.dart';
import 'package:test/test.dart';
import 'package:path/path.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/firestore_common.dart';

class FirestoreMock extends Object with FirestoreMixin implements Firestore {
  @override
  CollectionReference collection(String path) => null;

  @override
  DocumentReference doc(String path) => DocumentReferenceMock(path);

  @override
  WriteBatch batch() => null;

  @override
  Future runTransaction(Function(Transaction transaction) updateFunction) =>
      null;

  @override
  void settings(FirestoreSettings settings) {}

  @override
  Future<List<DocumentSnapshot>> getAll(List<DocumentReference> refs) => null;
}

class DocumentSnapshotMock implements DocumentSnapshot {
  @override
  final DocumentReferenceMock ref;

  DocumentSnapshotMock(this.ref);

  @override
  Map<String, dynamic> get data => null;

  @override
  bool get exists => null;

  @override
  Timestamp get updateTime => null;

  @override
  Timestamp get createTime => null;
}

class DocumentReferenceMock implements DocumentReference {
  DocumentReferenceMock(this.path);

  @override
  CollectionReference collection(String path) => null;

  @override
  Future delete() => null;

  @override
  Future<DocumentSnapshot> get() => null;

  @override
  String get id => url.basename(path);

  @override
  CollectionReference get parent => null;

  @override
  final String path;

  Future set(Map<String, dynamic> data, [SetOptions options]) => null;

  @override
  Future update(Map<String, dynamic> data) => null;

  @override
  Stream<DocumentSnapshot> onSnapshot() => null;
}

main() {
  group('path', () {
    test('sanitizeReferencePath', () {
      expect(sanitizeReferencePath(null), isNull);
      expect(sanitizeReferencePath('/test'), 'test');
      expect(sanitizeReferencePath('test/'), 'test');
      expect(sanitizeReferencePath('/test/'), 'test');
    });
    test('isDocumentReferencePath', () {
      expect(isDocumentReferencePath(null), isTrue);
      expect(isDocumentReferencePath('/test'), false);
      expect(isDocumentReferencePath('tests/doc'), isTrue);
      expect(isDocumentReferencePath('tests/doc/'), isTrue);
      expect(isDocumentReferencePath('tests/doc/coll/doc'), isTrue);
    });
  });
  group('queryInfo', () {
    test('queryInfoToJsonMap', () {
      var firestore = FirestoreMock();
      var queryInfo = QueryInfo();
      expect(queryInfoToJsonMap(queryInfo), {});

      queryInfo.limit = 1;
      queryInfo.offset = 2;
      queryInfo.orderBys = [
        OrderByInfo()
          ..fieldPath = "field"
          ..ascending = true
      ];
      queryInfo.startAt(
          values: [DateTime.fromMillisecondsSinceEpoch(1234567890123)]);
      queryInfo.endAt(
          snapshot:
              DocumentSnapshotMock(DocumentReferenceMock("path/to/dock")));
      queryInfo.addWhere(WhereInfo("whereField",
          isLessThanOrEqualTo:
              DateTime.fromMillisecondsSinceEpoch(12345678901234)));

      var expected = {
        'limit': 1,
        'offset': 2,
        'wheres': [
          {
            'fieldPath': 'whereField',
            'operator': '<=',
            'value': {r'$t': 'DateTime', r'$v': '2361-03-21T19:15:01.234Z'}
          }
        ],
        'orderBys': [
          {'fieldPath': 'field', 'direction': 'asc'}
        ],
        'startLimit': {
          'inclusive': true,
          'values': [
            {r'$t': 'DateTime', r'$v': '2009-02-13T23:31:30.123Z'}
          ]
        },
        'endLimit': {'inclusive': true, 'documentId': 'dock'}
      };
      expect(queryInfoToJsonMap(queryInfo), expected);

      // round trip
      expect(queryInfoToJsonMap(queryInfoFromJsonMap(firestore, expected)),
          expected);
    });
  });

  group('DocumentData', () {
    Firestore firestore = null;
    test('dateTime', () {
      var utcDate = DateTime.fromMillisecondsSinceEpoch(12345657890123).toUtc();
      var localDate = DateTime.fromMillisecondsSinceEpoch(123456578901234);
      DocumentData documentData = DocumentData();
      documentData.setDateTime('utcDateTime', utcDate);
      documentData.setDateTime('dateTime', localDate);
      expect(documentDataToRecordMap(documentData), {
        'utcDateTime': {r'$t': 'Timestamp', r'$v': '2361-03-21T13:24:50.123Z'},
        'dateTime': {r'$t': 'Timestamp', r'$v': '5882-03-08T14:08:21.234Z'}
      });

      documentData = documentDataFromRecordMap(
          firestore, documentDataToRecordMap(documentData));
      // this is local time
      expect(documentData.getDateTime('utcDateTime'), utcDate.toLocal());
      expect(documentData.getDateTime('dateTime'), localDate);
    });

    test('timestamp', () {
      var timestamp = Timestamp(1234567890, 123456000);
      DocumentData documentData = DocumentData();
      documentData.setTimestamp('timestamp', timestamp);
      expect(documentDataToRecordMap(documentData), {
        'timestamp': {r'$t': 'Timestamp', r'$v': '2009-02-13T23:31:30.123456Z'},
      });

      documentData = documentDataFromRecordMap(
          firestore, documentDataToRecordMap(documentData));
      expect(documentData.getTimestamp('timestamp'), timestamp);
    });

    test('sub data', () {
      DocumentDataMap documentData = DocumentDataMap();
      DocumentData subData = DocumentData();
      subData.setInt('test', 1234);
      documentData.setData('sub', subData);
      // store as a map
      expect(documentData.map['sub'], const TypeMatcher<Map>());
      expect(documentDataToRecordMap(documentData), {
        'sub': {'test': 1234}
      });

      documentData = documentDataFromRecordMap(firestore, {
        'sub': {'test': 1234}
      });
      subData = documentData.getData('sub');
      expect(subData.getInt('test'), 1234);
    });

    test('sub data', () {
      DocumentDataMap documentData = DocumentDataMap();
      DocumentData subData = DocumentData();
      DocumentData subSubData = DocumentData();
      subSubData.setInt('test', 1234);
      documentData.setData('sub', subData);
      subData.setData('subsub', subSubData);
      expect(documentData.map['sub'], const TypeMatcher<Map>());
      expect(documentDataToRecordMap(documentData), {
        'sub': {
          'subsub': {'test': 1234}
        }
      });
      expect(documentData.asMap(), {
        'sub': {
          'subsub': {'test': 1234}
        }
      });

      documentData = documentDataFromRecordMap(firestore, {
        'sub': {
          'subsub': {'test': 1234}
        }
      });
      subData = documentData.getData('sub');
      subSubData = subData.getData('subsub');
      expect(subSubData.getInt('test'), 1234);
    });

    test('sub field', () {
      DocumentDataMap documentData = DocumentDataMap();
      DocumentData subData = DocumentData();
      subData.setInt('test', 1234);
      documentData.setData('sub', subData);
      // store as a map
      expect(documentData.map['sub'], const TypeMatcher<Map>());
      expect(documentDataToRecordMap(documentData), {
        'sub': {'test': 1234}
      });

      documentData = documentDataFromRecordMap(firestore, {
        'sub': {'test': 1234}
      });
      subData = documentData.getData('sub');
      expect(subData.getInt('test'), 1234);
    });

    test('list', () {
      DocumentData documentData = DocumentData();
      documentData.setList('test', [1, 2]);
      expect(documentDataToRecordMap(documentData), {
        'test': [1, 2]
      });

      documentData = documentDataFromRecordMap(firestore, {
        'test': [1, 2]
      });
      expect(documentData.getList('test'), [1, 2]);
    });

    test('documentMapFromRecordMap', () {
      var documentData = DocumentDataMap();
      expect(documentData.map, {});
      documentDataFromRecordMap(firestore, {}, documentData);
      expect(documentData.map, {});
      documentDataFromRecordMap(firestore, null, documentData);
      expect(documentData.map, {});

      // basic types
      documentDataFromRecordMap(
          firestore,
          {'int': 1234, 'bool': true, 'string': 'text', 'double': 1.5},
          documentData);
      expect(documentData.map,
          {'int': 1234, 'bool': true, 'string': 'text', 'double': 1.5});

      // date time
      documentDataFromRecordMap(
          firestore,
          {'dateTime': 1234, 'bool': true, 'string': 'text', 'double': 1.5},
          documentData);
    });

    test('complex', () {
      var date = DateTime.fromMillisecondsSinceEpoch(12345657890123);
      DocumentData documentData = DocumentData();
      DocumentData subData = DocumentData();
      DocumentData listItemDocumentData = DocumentData();
      listItemDocumentData.setDateTime('date', date);
      listItemDocumentData.setInt('test', 12345);
      documentData.setData('sub', subData);
      subData.setList('list', [1234, date, listItemDocumentData]);
      subData.setData('map', listItemDocumentData);

      var expected = {
        'sub': {
          'list': [
            1234,
            {r'$t': 'Timestamp', r'$v': '2361-03-21T13:24:50.123Z'},
            {
              'date': {r'$t': 'Timestamp', r'$v': '2361-03-21T13:24:50.123Z'},
              'test': 12345
            }
          ],
          'map': {
            'date': {r'$t': 'Timestamp', r'$v': '2361-03-21T13:24:50.123Z'},
            'test': 12345
          }
        }
      };
      expect(documentDataToRecordMap(documentData), expected);
      documentData = documentDataFromRecordMap(firestore, expected);
      expect(documentDataToRecordMap(documentData), expected);
    });
  });
}
