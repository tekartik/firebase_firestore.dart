import 'dart:typed_data';

import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/firestore_mock.dart';
import 'package:tekartik_firebase_firestore/src/firestore.dart'
    show DocumentDataMap;
import 'package:tekartik_firebase_firestore/src/firestore_common.dart'
    show
        dateTimeToJsonValue,
        documentDataFromJsonMap,
        documentDataMapFromJsonMap,
        documentDataMapToJsonMap,
        documentDataToJsonMap,
        fieldValueToJsonValue,
        jsonValueToDateTime,
        jsonValueToTimestamp,
        timestampToJsonValue;
import 'package:tekartik_firebase_firestore/utils/document_data.dart';
import 'package:test/test.dart';

void main() {
  var firestore = FirestoreMock();
  group('jsonValue', () {
    test('dateTime', () {
      expect(
        dateTimeToJsonValue(
          DateTime.fromMillisecondsSinceEpoch(123456578901234),
        ),
        {r'$t': 'DateTime', r'$v': '5882-03-08T14:08:21.234Z'},
      );

      expect(
        jsonValueToDateTime({
          r'$t': 'DateTime',
          r'$v': '5882-03-08T14:08:21.234Z',
        }),
        DateTime.fromMillisecondsSinceEpoch(123456578901234).toUtc(),
      );
    });

    test('timestamp', () {
      expect(timestampToJsonValue(Timestamp(1234567890, 123456000)), {
        r'$t': 'Timestamp',
        r'$v': '2009-02-13T23:31:30.123456Z',
      });

      expect(
        jsonValueToTimestamp({
          r'$t': 'DateTime',
          r'$v': '2009-02-13T23:31:30.123456Z',
        }),
        Timestamp(1234567890, 123456000),
      );
    });

    test('fieldValue', () {
      expect(fieldValueToJsonValue(FieldValue.delete), {
        r'$t': 'FieldValue',
        r'$v': '~delete',
      });
      expect(fieldValueToJsonValue(FieldValue.serverTimestamp), {
        r'$t': 'FieldValue',
        r'$v': '~serverTimestamp',
      });
    });
  });

  group('jsonMap', () {
    test('list', () {
      var data = DocumentData();
      expect(data.getList<void>('list'), isNull);
      data.setList('list', <Object?>[1, 3]);
      final list = data.getList<int>('list');
      expect(list, [1, 3]);
    });

    test('blob', () {
      var data = DocumentData();
      data.setBlob('blob', Blob(Uint8List(0)));
      expect(documentDataToJsonMap(data), {
        'blob': {r'$t': 'Blob', r'$v': ''},
      });

      data.setNull('blob');
      expect(documentDataToJsonMap(data), {'blob': null});

      data.setBlob('blob', Blob(Uint8List.fromList([1, 2, 3])));
      expect(documentDataToJsonMap(data), {
        'blob': {r'$t': 'Blob', r'$v': 'AQID'},
      });
      data = documentDataFromJsonMap(firestore, documentDataToJsonMap(data))!;
      var blob = data.getBlob('blob')!;
      expect(blob.data, [1, 2, 3]);
    });

    test('geoPoint', () {
      var data = DocumentData();
      data.setGeoPoint('geo', const GeoPoint(3.5, 4.0));
      expect(documentDataToJsonMap(data), {
        'geo': {
          r'$t': 'GeoPoint',
          r'$v': {'latitude': 3.5, 'longitude': 4.0},
        },
      });

      data.setNull('geo');
      expect(documentDataToJsonMap(data), {'geo': null});

      data.setGeoPoint('geo', const GeoPoint(3.5, 4.0));

      data = documentDataFromJsonMap(firestore, documentDataToJsonMap(data))!;
      var geoPoint = data.getGeoPoint('geo')!;
      expect(geoPoint.latitude, 3.5);
      expect(geoPoint.longitude, 4.0);
    });

    test('timestamp', () {
      var data = DocumentData();
      data.setTimestamp('timestamp', Timestamp(12345678901, 123456000));
      var map = documentDataToJsonMap(data);
      expect(map, {
        'timestamp': {r'$t': 'Timestamp', r'$v': '2361-03-21T19:15:01.123456Z'},
      });

      // As timestamp
      firestore.firestoreSettings = FirestoreSettings();
      data = documentDataFromJsonMap(firestore, map)!;
      expect(data.getTimestamp('timestamp'), Timestamp(12345678901, 123456000));
      expect(data.asMap()['timestamp'], Timestamp(12345678901, 123456000));

      // As date
      firestore.firestoreSettings = null;
      data = documentDataFromJsonMap(firestore, map)!;
      expect(
        data.getTimestamp('timestamp'),
        Timestamp(12345678901, 123456000),
        /*
          dateTimeHasMicros
              ? Timestamp(12345678901, 123456000)
              : Timestamp(12345678901, 123000000)*/
      );
      /* 2019/12/12 no longer date time
      expect(
          data.asMap()['timestamp'],
          dateTimeHasMicros
              ? DateTime.parse('2361-03-21T19:15:01.123456Z').toLocal()
              : DateTime.parse('2361-03-21T19:15:01.123Z').toLocal());
      */
      data.setNull('timestamp');
      expect(documentDataToJsonMap(data), {'timestamp': null});
      expect(data.getTimestamp('timestamp'), null);
    });
    test('documentReference', () {
      var data = DocumentData();
      data.setDocumentReference('ref', firestore.doc('tests/doc'));
      expect(documentDataToJsonMap(data), {
        'ref': {r'$t': 'DocumentReference', r'$v': 'tests/doc'},
      });
      expect(data.getDocumentReference('ref')!.path, 'tests/doc');
      data.setNull('ref');
      expect(documentDataToJsonMap(data), {'ref': null});
      data = documentDataFromJsonMap(firestore, documentDataToJsonMap(data))!;
      expect(data.getDocumentReference('ref'), isNull);
    });

    test('toJsonMap', () {
      var documentData = DocumentDataMap();
      expect(documentDataToJsonMap(documentData), isEmpty);
      documentData.setInt('int', 1);
      var nested = DocumentData();
      nested.setFieldValue('delete', FieldValue.delete);
      documentData.setList('list', [
        1,
        DateTime.fromMillisecondsSinceEpoch(1234567890123),
        FieldValue.serverTimestamp,
      ]);
      documentData.setFieldValue('delete', FieldValue.delete);
      documentData.setData('nested', nested);
      expect(documentDataToJsonMap(documentData), {
        'int': 1,
        'list': [
          1,
          {r'$t': 'DateTime', r'$v': '2009-02-13T23:31:30.123Z'},
          {r'$t': 'FieldValue', r'$v': '~serverTimestamp'},
        ],
        'delete': {r'$t': 'FieldValue', r'$v': '~delete'},
        'nested': {
          'delete': {r'$t': 'FieldValue', r'$v': '~delete'},
        },
      });
    });

    test('all types to/from json with firestore', () {
      var map = {
        'int': 1,
        'bool': true,
        'list': [1],
        'map': {'test': 1},
        'blob': Blob.fromList([1, 2, 3]),
        'ref': firestore.doc('test/1'),
        'geoPoint': const GeoPoint(1, 2),
        'timestamp': Timestamp(1, 2),
      };
      expect(
        documentDataMapFromJsonMap(firestore, documentDataMapToJsonMap(map)),
        map,
      );
    });

    test('all types to/from json no firestore', () {
      var map = {
        'int': 1,
        'bool': true,
        'list': [1],
        'map': {'test': 1},
        'blob': Blob.fromList([1, 2, 3]),
        //  'ref': firestore.doc('test/1'), ref not supported
        'geoPoint': const GeoPoint(1, 2),
        'timestamp': Timestamp(1, 2),
      };
      expect(
        documentDataFromJsonMapNoFirestore(
          documentDataMapToJsonMap(map),
        )!.asMap(),
        map,
      );
    });

    test('fromJsonMap', () {
      var map = {
        'data': {
          'list': [
            'test',
            null,
            {r'$t': 'Timestamp', r'$v': '5882-03-08T14:08:21.234Z'},
          ],
          'int': 1,
          'delete': {r'$t': 'FieldValue', r'$v': '~delete'},
          'ref': {r'$t': 'DocumentReference', r'$v': 'tests/doc'},
        },
      };
      expect(
        documentDataToJsonMap(documentDataFromJsonMap(firestore, map)),
        map,
      );
    });

    group('DocumentData', () {
      test('sub_empty', () async {
        var documentData = DocumentData();
        DocumentData? subData = DocumentData();
        documentData.setData('sub', subData);
        subData = documentData.getData('sub');
        expect(subData, isNotNull);
      });

      test('sub_one', () async {
        var documentData = DocumentData();
        var subData = DocumentData();
        documentData.setData('sub', subData);
        subData.setString('test', 'test_value');
        subData = documentData.getData('sub')!;
        expect(subData.getString('test'), 'test_value');
      });

      test('sub_sub_one', () async {
        var documentData = DocumentData();
        var subData = DocumentData();
        documentData.setData('sub', subData);
        var subSubData = DocumentData();
        subData.setData('inner', subSubData);
        subSubData.setString('test', 'test_value');
        subData = documentData.getData('sub')!;
        subSubData = subData.getData('inner')!;
        expect(subSubData.getString('test'), 'test_value');
      });
    });
    test('path', () {
      expect(firestorePathGetParent(''), isNull);
      expect(firestorePathGetParent('/'), isNull);
      expect(firestorePathGetParent('.'), isNull);
      expect(firestorePathGetParent('a'), isNull);
      expect(firestorePathGetParent('a/b'), 'a');
      expect(firestorePathGetParent('a/b/c'), 'a/b');

      expect(firestorePathGetGenericPath('a'), 'a');
      expect(firestorePathGetGenericPath('a/1'), 'a/*');
      expect(firestorePathGetGenericPath('a/1/b/2'), 'a/*/b/*');
      expect(firestorePathGetGenericPath(''), '');

      expect(firestorePathGetChild('a', 'b'), 'a/b');
      expect(firestorePathReplaceId('a/b', 'c'), 'a/c');
      expect(firestorePathReplaceId('a/b/c', 'd'), 'a/b/d');
      expect(firestorePathReplaceId('a', 'b'), 'b');
      expect(firestorePathReplaceId('', 'b'), 'b');

      expect(firestorePathGetId('a/b/c'), 'c');
      expect(firestorePathGetId('a/b'), 'b');
      expect(firestorePathGetId('a'), 'a');
      expect(firestorePathGetId(''), '');
    });
  });
}
