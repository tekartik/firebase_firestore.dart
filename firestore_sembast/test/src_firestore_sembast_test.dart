@TestOn('vm')
library tekartik_firebase_sembast.firebase_io_src_test;

import 'dart:io';

import 'package:path/path.dart';
import 'package:sembast/sembast.dart' as sembast;
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast_io.dart';
import 'package:tekartik_firebase_firestore_sembast/src/firestore_sembast.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  var firebase = FirebaseLocal();
  var service = firestoreServiceIo;
  // var app = firebase.initializeApp(name: 'test');

  group('firestore_sembast', () {
    group('v1', () {
      test('read', () async {
        var dst = join('.dart_tool', 'tekartik_firebase_local', 'default_v1',
            'firestore.db');
        await File(dst).create(recursive: true);
        await File(join('test', 'data', 'default_v1.db')).copy(dst);

        var app = firebase.initializeApp(name: 'default_v1');
        var ioFirestore = service.firestore(app) as FirestoreSembast;
        expect(ioFirestore.dbPath, dst);
        var snapshot = await ioFirestore.doc('all_fields/doc').get();
        expect(
            snapshot.updateTime!.toIso8601String(), '2018-10-23T00:00:00.000Z');
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
      await firestore.doc('doc/path').delete();
      await firestore.doc('doc/path').set({'test': 1});
      var db = (firestore as FirestoreSembast).db!;
      var map = (await sembast.stringMapStoreFactory
          .store('doc')
          .record('doc/path')
          .get(db))!;
      expect(map['test'], 1);
      expect(map[r'$rev'], 1);
      expect(Timestamp.tryParse(map[r'$createTime'] as String), isNotNull);
      expect(Timestamp.tryParse(map[r'$updateTime'] as String), isNotNull);
      expect(map.length, 4, reason: map.toString());
    });

    group('DocumentData', () {
      test('valueToUpdateValue', () {
        expect(
            valueToUpdateValue(FieldValue.delete), sembast.FieldValue.delete);
        expect(valueToUpdateValue({'test': FieldValue.delete}),
            {'test': sembast.FieldValue.delete});
        //var union = FieldValue.arrayUnion([1]);
        //expect(valueToUpdateValue({'test': union}), {'test': union});
      });
    });
  });
}
