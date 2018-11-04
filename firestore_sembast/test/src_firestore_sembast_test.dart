@TestOn('vm')
library tekartik_firebase_sembast.firebase_io_src_test;

import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/firestore.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast_io.dart';
import 'package:tekartik_firebase_firestore_sembast/src/firestore_sembast.dart';
import 'package:test/test.dart';

void main() {
  var firebase = FirebaseLocal();
  var service = firestoreServiceIo;
  var app = firebase.initializeApp(name: 'test');
  var firestore = service.firestore(app);

  group('firestore_io', () {
    group('v1', () {
      test('read', () async {
        var dst = join('.dart_tool', 'tekartik_firebase_local', 'default_v1',
            'firestore.db');
        await File(dst).create(recursive: true);
        await File(join('test', 'data', 'default_v1.db')).copy(dst);

        var app = firebase.initializeApp(name: 'default_v1');
        var ioFirestore = service.firestore(app) as FirestoreSembast;
        expect(ioFirestore.dbPath, dst);
        var snapshot = await ioFirestore.doc('all_fields').get();
        expect(
            snapshot.updateTime.toIso8601String(), '2018-10-23T00:00:00.000Z');
      });
    });

    test('db_name', () async {
      var app = firebase.initializeApp(name: 'test');
      var ioFirestore = service.firestore(app) as FirestoreSembast;
      expect(
          ioFirestore.dbPath,
          join(
              '.dart_tool', 'tekartik_firebase_local', 'test', 'firestore.db'));

      app = firebase.initializeApp(name: '');
      ioFirestore = service.firestore(app) as FirestoreSembast;
      expect(
          ioFirestore.dbPath,
          join('.dart_tool', 'tekartik_firebase_local', '_default',
              'firestore.db'));

      app = firebase.initializeApp();
      ioFirestore = service.firestore(app) as FirestoreSembast;
      expect(
          ioFirestore.dbPath,
          join('.dart_tool', 'tekartik_firebase_local', '_default',
              'firestore.db'));

      app = firebase.initializeApp(name: join('.', 'test'));
      ioFirestore = service.firestore(app) as FirestoreSembast;
      expect(ioFirestore.dbPath, join('.', 'test', 'firestore.db'));
    });

    test('db_format', () async {
      var app = firebase.initializeApp(name: 'format');
      var firestore = service.firestore(app);
      await firestore.doc('doc_path').delete();
      await firestore.doc('doc_path').set({'test': 1});
      var db = (firestore as FirestoreSembast).db;
      Map map = await db.getStore('doc').get('doc_path');
      expect(map['test'], 1);
      expect(map[r'$rev'], 1);
      expect(Timestamp.tryParse(map[r'$createTime'] as String), isNotNull);
      expect(Timestamp.tryParse(map[r'$updateTime'] as String), isNotNull);
      expect(map.length, 4, reason: map.toString());
    });

    group('DocumentData', () {
      test('dateTime', () {
        var utcDate =
            DateTime.fromMillisecondsSinceEpoch(12345657890123).toUtc();
        var localDate = DateTime.fromMillisecondsSinceEpoch(123456578901234);
        DocumentData documentData = DocumentData();
        documentData.setDateTime('utcDateTime', utcDate);
        documentData.setDateTime('dateTime', localDate);
        expect(documentDataToRecordMap(documentData), {
          'utcDateTime': {
            r'$t': 'Timestamp',
            r'$v': '2361-03-21T13:24:50.123Z'
          },
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
          'timestamp': {
            r'$t': 'Timestamp',
            r'$v': '2009-02-13T23:31:30.123456Z'
          },
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
  });
}
