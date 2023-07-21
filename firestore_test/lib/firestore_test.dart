// ignore_for_file: inference_failure_on_collection_literal

import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/reference_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore/utils/collection.dart';
import 'package:tekartik_firebase_firestore_test/timestamp_test.dart';
import 'package:tekartik_firebase_firestore_test/utils_collection_test.dart';
import 'package:tekartik_firebase_firestore_test/utils_query_test.dart';
import 'package:tekartik_firebase_firestore_test/utils_test.dart';
import 'package:test/test.dart';

bool skipConcurrentTransactionTests = false;

List<DocumentReference?> docsKeys(List<DocumentSnapshot> snashots) =>
    snashots.map((e) => e.ref).toList();

void run(
    {required Firebase firebase,
    required FirestoreService firestoreService,
    AppOptions? options}) {
  final app = firebase.initializeApp(options: options);

  tearDownAll(() {
    return app.delete();
  });

  var firestore = firestoreService.firestore(app);
  runApp(firestoreService: firestoreService, firestore: firestore);
  runUtilsCollectionTests(
      firestoreService: firestoreService, firestore: firestore);
  runUtilsQueryTest(firestoreService: firestoreService, firestore: firestore);
  /*
  if (firestoreService.supportsTimestampsInSnapshots) {
    runNoTimestampsInSnapshots(
        firestoreService: firestoreService,
        firebase: firebase,
        options: options);
  }
   */
  utilsTest(firestoreService: firestoreService, firestore: firestore);
}

@Deprecated('Default')
void runNoTimestampsInSnapshots(
    {required FirestoreService firestoreService,
    required FirebaseAsync firebase,
    AppOptions? options}) {
  late App appNoTimestampsInSnapshots;
  late Firestore firestore;
  group('firestore_noTimestampsInSnapshots', () {
    setUpAll(() async {
      // old date support
      appNoTimestampsInSnapshots = await firebase.initializeAppAsync(
          options: options ?? AppOptions(), name: 'noTimestampsInSnapshots');
      firestore = firestoreService.firestore(appNoTimestampsInSnapshots);
      //devPrint('App name: ${app.name}');

      firestore.settings(FirestoreSettings());
    });

    tearDownAll(() async {
      await appNoTimestampsInSnapshots.delete();
    });
    var testsRefPath = 'tests/tekartik_firebase/tests';

    CollectionReference? getTestsRef() {
      return firestore.collection(testsRefPath);
    }

    group('Data', () {
      test('date', () async {
        var testsRef = getTestsRef()!;
        var docRef = testsRef.doc('date');
        var localDateTime =
            DateTime.fromMillisecondsSinceEpoch(1234567890).toLocal();
        var utcDateTime =
            DateTime.fromMillisecondsSinceEpoch(12345678901).toUtc();
        await docRef
            .set({'some_date': localDateTime, 'some_utc_date': utcDateTime});
        expect((await docRef.get()).data, {
          'some_date': localDateTime,
          'some_utc_date': utcDateTime.toLocal()
        });

        var snapshot = (await testsRef
                .where('some_date', isEqualTo: localDateTime)
                .where('some_utc_date', isEqualTo: utcDateTime)
                .get())
            .docs
            .first;
        expect(snapshot.data, {
          'some_date': localDateTime,
          'some_utc_date': utcDateTime.toLocal()
        });
        expect(snapshot.dataOrNull, snapshot.data);
        await docRef.delete();
      });
    });
  });
}

void runApp(
    {required FirestoreService firestoreService,
    required Firestore firestore}) {
  setUpAll(() async {
    if (firestoreService.supportsTimestampsInSnapshots) {
      // force support
      // firestore.settings(FirestoreSettings(timestampsInSnapshots: true));
    }
  });
  group('firestore', () {
    var testsRefPath = 'tests/tekartik_firestore/tests';

    timestampGroup(service: firestoreService, firestore: firestore);
    CollectionReference? getTestsRef() {
      return firestore.collection(testsRefPath);
    }

    group('DocumentReference', () {
      test('create', () async {
        var ref = firestore.doc(url.join(testsRefPath, 'document_reference'));
        try {
          await ref.delete();
        } catch (_) {}

        await ref.set({});

        await ref.delete();
      });

      test('collection_add', () async {
        var testsRef = getTestsRef()!;

        var docRef = await testsRef.add({});
        // Check firestore
        if (testsRef is FirestorePathReference) {
          expect((docRef as FirestorePathReference).firestore,
              (testsRef as FirestorePathReference).firestore);
        }
        await docRef.delete();
      });

      /*
      // this does not work on node
      test('collection_child_no_path', () async {
        var testsRef = getTestsRef();

        var docRef = testsRef.doc();
        expect(docRef.id, isNotNull);
        expect(docRef.id, isNotEmpty);
      }, skip: platform.name == platformNameNode);
      */

      test('get_dummy', () async {
        var testsRef = getTestsRef()!;
        var docRef = testsRef.doc('dummy_id_that_should_never_exists');
        var snapshot = await docRef.get();
        expect(snapshot.ref, isNotNull);
        // Check firestore
        if (testsRef is FirestorePathReference) {
          expect((docRef as FirestorePathReference).firestore,
              (snapshot.ref as FirestorePathReference).firestore);
        }
        expect(snapshot.exists, isFalse);
        expect(snapshot.dataOrNull, isNull);
        try {
          snapshot.data;
          fail('should fail');
        } catch (e) {
          expect(e, isNot(const TypeMatcher<TestFailure>()));
        }
      });

      test('get_all', () async {
        var testsRef = getTestsRef()!;
        var doc1Ref = testsRef.doc('get_all_1');
        await doc1Ref.set({'value': 1});
        var docDummyRef = testsRef.doc('dummy_id_that_should_never_exists');
        var snapshots = await firestore.getAll([doc1Ref, docDummyRef]);
        expect(snapshots.length, 2);
        expect(snapshots[0].exists, isTrue);
        expect(snapshots[0].data, {'value': 1});
        expect(snapshots[1].exists, isFalse);

        // Check firestore
        if (testsRef is FirestorePathReference) {
          expect((testsRef as FirestorePathReference).firestore,
              (snapshots[0].ref as FirestorePathReference).firestore);
        }
        // expect(snapshots[1].data, isNull); currently node returns {}
      });

      test('delete', () async {
        var testsRef = getTestsRef()!;
        var docRef = await testsRef.add({});
        await docRef.delete();

        var snapshot = await docRef.get();
        expect(snapshot.exists, isFalse);
      });

      test('delete_dummy', () async {
        var testsRef = getTestsRef()!;
        var docRef = testsRef.doc('dummy_id_that_should_never_exists');
        await docRef.delete();
      });

      test('update_dummy', () async {
        var failed = false;
        var testsRef = getTestsRef()!;
        var docRef = testsRef.doc('dummy_id_that_should_never_exists');
        try {
          await docRef.update({'test': 1});
        } catch (e) {
          failed = true;
          // print(e);
          // print(e.runtimeType);
        }
        expect(failed, isTrue);
      });

      test('doc is as mail', () async {
        var collRef =
            firestore.collection(url.join(testsRefPath, 'email', 'emails'));
        var docRef = collRef.doc('some+1@email.com');
        await docRef.set({'test': 1});
        /*
        TODO fix for REST
        var refs = (await collRef.get()).docs.map((e) => e.ref);
        for (var ref in refs) {
          // var value = (await ref.get()).data;
          //devPrint('get $ref: $value');
        }
         */
        expect((await docRef.get()).data, {'test': 1});
        // await docRef.delete();
      });
    });

    group('DocumentSnapshot', () {
      test('empty', () async {
        var testsRef = getTestsRef()!;
        var docRef = testsRef.doc('empty');
        await docRef.set({});
        var snapshot = await docRef.get();
        expect(snapshot.data, {});
        expect(snapshot.exists, isTrue);
      });

      test('bad path', () async {
        var testsRef = getTestsRef()!;
        try {
          testsRef.doc('bad/path');
          fail('should fail');
          // Document references must have an even number of segments,
        } catch (e) {
          expect(e, isNot(const TypeMatcher<TestFailure>()));
        }
      });

      test('documentTime', () async {
        var testsRef = getTestsRef()!;
        var docRef = testsRef.doc('time');
        await docRef.delete();
        var now = Timestamp.now();
        await docRef.set({'test': 1});
        var snapshot = await docRef.get();
        //devPrint('createTime ${snapshot.createTime}');
        //devPrint('updateTime ${snapshot.updateTime}');
        expect(snapshot.data, {'test': 1});

        if (firestoreService.supportsDocumentSnapshotTime) {
          expect(snapshot.updateTime!.compareTo(now), greaterThanOrEqualTo(0));
          expect(snapshot.createTime, snapshot.updateTime);
        } else {
          expect(snapshot.createTime, isNull);
          expect(snapshot.updateTime, isNull);
        }
        await sleep(10);
        await docRef.set({'test': 2});
        snapshot = await docRef.get();

        void check() {
          expect(snapshot.data, {'test': 2});
          if (firestoreService.supportsDocumentSnapshotTime) {
            expect(snapshot.updateTime!.compareTo(snapshot.createTime),
                greaterThan(0),
                reason:
                    'createTime ${snapshot.createTime} updateTime ${snapshot.updateTime}');
          } else {
            expect(snapshot.createTime, isNull);
            expect(snapshot.updateTime, isNull);
          }
        }

        check();
        // On node we have nanos!
        // createTime 2018-10-23T06:31:53.351558000Z
        // updateTime 2018-10-23T06:31:53.755402000Z
        // devPrint('createTime ${snapshot.createTime}');
        // devPrint('updateTime ${snapshot.updateTime}');

        if (firestoreService.supportsTrackChanges) {
          // Try using stream
          snapshot = await docRef.onSnapshot().first;
          check();

          // Try using col stream
          snapshot = (await testsRef.onSnapshot().first)
              .docs
              .where((DocumentSnapshot snapshot) =>
                  snapshot.ref.path == docRef.path)
              .first;
          check();
        }
      });
    });

    group('DocumentData', () {
      test('property', () async {
        var testsRef = getTestsRef()!;
        var docRef = testsRef.doc('property');
        var documentData = DocumentData();
        expect(documentData.has('some_property'), isFalse);
        expect(documentData.keys, isEmpty);
        documentData.setProperty('some_property', 'test_1');
        expect(documentData.keys, ['some_property']);
        expect(documentData.has('some_property'), isTrue);
        await docRef.set(documentData.asMap());
        documentData = DocumentData((await docRef.get()).data);
        expect(documentData.has('some_property'), isTrue);
        expect(documentData.keys, ['some_property']);
        expect(documentData.has('other_property'), isFalse);
        await docRef.delete();
      });

      // All fields that we do not delete
      test('allFields', () async {
        var testsRef = getTestsRef()!;
        var localDateTime = DateTime.fromMillisecondsSinceEpoch(1234567890);
        var utcDateTime =
            DateTime.fromMillisecondsSinceEpoch(1234567890, isUtc: true);
        var timestamp = Timestamp(123456789, 123456000);
        var docRef = testsRef.doc('all_fields');
        var documentData = DocumentData();
        documentData.setString('string', 'string_value');

        documentData.setInt('int', 12345678901);
        documentData.setNum('num', 3.1416);
        documentData.setBool('bool', true);
        documentData.setDateTime('localDateTime', localDateTime);
        documentData.setDateTime('utcDateTime', utcDateTime);
        documentData.setTimestamp('timestamp', timestamp);
        documentData.setList('intList', <int>[4, 3]);
        documentData.setDocumentReference('docRef', firestore.doc('tests/doc'));
        documentData.setBlob('blob', Blob(Uint8List.fromList([1, 2, 3])));
        documentData.setGeoPoint('geoPoint', GeoPoint(1.2, 4));

        documentData.setFieldValue(
            'serverTimestamp', FieldValue.serverTimestamp);
        documentData.setNull('null');

        var subData = DocumentData();
        subData.setDateTime('localDateTime', localDateTime);
        documentData.setData('subData', subData);

        DocumentData? subSubData = DocumentData();
        subData.setData('inner', subSubData);

        await docRef.set(documentData.asMap());
        documentData = DocumentData((await docRef.get()).data);
        expect(documentData.getString('string'), 'string_value');

        expect(documentData.getInt('int'), 12345678901);
        expect(documentData.getNum('num'), 3.1416);
        expect(documentData.getBool('bool'), true);

        expect(documentData.getDateTime('localDateTime'), localDateTime);
        expect(documentData.getDateTime('utcDateTime'), utcDateTime.toLocal());
        // Might only get milliseconds in the browser
        expect(documentData.getTimestamp('timestamp'),
            timestampAdaptPrecision(firestoreService, timestamp));
        expect(documentData.getDocumentReference('docRef')!.path, 'tests/doc');
        expect(documentData.getBlob('blob')!.data, [1, 2, 3]);
        expect(documentData.getGeoPoint('geoPoint'), GeoPoint(1.2, 4));
        expect(
            documentData
                    .getDateTime('serverTimestamp')!
                    .millisecondsSinceEpoch >
                0,
            isTrue);
        expect(documentData.has('null'), isTrue);
        final list = documentData.getList<int>('intList');
        expect(list, [4, 3]);

        subData = documentData.getData('subData')!;
        expect(subData.getDateTime('localDateTime'), localDateTime);

        subSubData = subData.getData('inner');
        expect(subSubData, isNotNull);
      });
    });

    group('Data', () {
      test('string', () async {
        var testsRef = getTestsRef()!;
        var docRef = testsRef.doc('string');
        await docRef.set({'some_key': 'some_value'});
        expect((await docRef.get()).data, {'some_key': 'some_value'});
        await docRef.delete();
      });

      test('list<data>', () async {
        var testsRef = getTestsRef()!;
        var docRef = testsRef.doc('list');
        await docRef.set({
          'some_key': [
            {'sub_key': 'some_value'}
          ]
        });
        var snapshot = await docRef.get();
        var documentData = DocumentData(snapshot.data);
        expect(snapshot.data, {
          'some_key': [
            {'sub_key': 'some_value'}
          ]
        });
        var list = documentData.getList<Map<String, Object?>>('some_key')!;
        final sub = DocumentData(list[0]);
        expect(sub.getString('sub_key'), 'some_value');
        await docRef.delete();
      });

      test('date', () async {
        var testsRef = getTestsRef()!;
        var docRef = testsRef.doc('date');
        var localDateTime =
            DateTime.fromMillisecondsSinceEpoch(1234567890).toLocal();
        var utcDateTime =
            DateTime.fromMillisecondsSinceEpoch(12345678901).toUtc();
        await docRef
            .set({'some_date': localDateTime, 'some_utc_date': utcDateTime});

        void check(Map? data) {
          if (firestoreService.supportsTimestampsInSnapshots) {
            //devPrint(data['some_date'].runtimeType);
            expect(data, {
              'some_date': Timestamp.fromDateTime(localDateTime),
              'some_utc_date': Timestamp.fromDateTime(utcDateTime.toLocal())
            });
          } else {
            expect(data, {
              'some_date': localDateTime,
              'some_utc_date': utcDateTime.toLocal()
            });
          }
        }

        check((await docRef.get()).data);

        var snapshot = (await testsRef
                .where('some_date', isEqualTo: localDateTime)
                .where('some_utc_date', isEqualTo: utcDateTime)
                .get())
            .docs
            .first;

        check(snapshot.data);
        await docRef.delete();
      });

      test('timestamp_nanos', () async {
        var testsRef = getTestsRef()!;
        var docRef = testsRef.doc('timestamp');
        var timestamp = Timestamp(1234567890, 1234);
        await docRef.set({'some_timestamp': timestamp});

        var data = (await docRef.get()).data;

        if (firestoreService.supportsTimestampsInSnapshots) {
          expect(
              data,
              {
                'some_timestamp': timestamp,
              },
              reason:
                  'nanos: ${timestamp.nanoseconds} vs ${(data['some_timestamp'] as Timestamp).nanoseconds}');
        } else {
          expect(data, {
            'some_timestamp': timestamp.toDateTime(),
          });
        }
        await docRef.delete();
      }, skip: true);

      test('timestamp', () async {
        var testsRef = getTestsRef()!.doc('lookup').collection('timestamp');
        var docRef = testsRef.doc('timestamp');
        var timestamp = Timestamp(1234567890, 123000);
        await docRef.set({'some_timestamp': timestamp});
        void check(Map<String, Object?>? data) {
          if (firestoreService.supportsTimestampsInSnapshots) {
            expect(
                data,
                {
                  'some_timestamp': timestamp,
                },
                reason:
                    'nanos: ${timestamp.nanoseconds} vs ${(data!['some_timestamp'] as Timestamp).nanoseconds}');
          } else {
            expect(data, {
              'some_timestamp': timestamp.toDateTime(),
            });
          }
        }

        check((await docRef.get()).data);
        var snapshot =
            (await testsRef.where('some_timestamp', isEqualTo: timestamp).get())
                .docs
                .first;
        check(snapshot.data);

        // Try compare
        snapshot = (await testsRef
                .where('some_timestamp', isGreaterThanOrEqualTo: timestamp)
                .get())
            .docs
            .first;
        check(snapshot.data);

        await docRef.delete();
      }, skip: !firestoreService.supportsTimestamps);

      test('null', () async {
        var testsRef = getTestsRef()!.doc('lookup').collection('null');
        var docRef = testsRef.doc('a');
        var doc2Ref = testsRef.doc('b');
        await docRef.set({'value': 1});
        await doc2Ref.set({'value': null});
        void check(Map<String, Object?>? data) {
          expect(data, {
            'value': null,
          });
        }

        check((await doc2Ref.get()).data);
        var snapshot =
            (await testsRef.where('value', isNull: true).get()).docs.first;
        check(snapshot.data);

        await docRef.delete();
      });

      test('null', () async {
        var testsRef = getTestsRef()!.doc('lookup').collection('bool');
        var docRef = testsRef.doc('a');
        var doc2Ref = testsRef.doc('b');
        await docRef.set({'value': null});
        await doc2Ref.set({'value': true});
        void check(Map<String, Object?>? data) {
          expect(data, {
            'value': true,
          });
        }

        check((await doc2Ref.get()).data);
        var snapshot =
            (await testsRef.where('value', isEqualTo: true).get()).docs.first;
        check(snapshot.data);

        await docRef.delete();
      });

      // All fields that we do not delete
      test(
        'allFields',
        () async {
          var testsRef = getTestsRef()!;
          var localDateTime = DateTime.fromMillisecondsSinceEpoch(1234567890);
          var utcDateTime =
              DateTime.fromMillisecondsSinceEpoch(1234567890, isUtc: true);
          var timestamp = Timestamp(1234567890, 123000);
          var docRef = testsRef.doc('all_fields');
          var data = <String, Object?>{
            'string': 'string_value',
            'int': 12345678901,
            'num': 3.1416,
            'bool': true,
            'localDateTime': localDateTime,
            'utcDateTime': utcDateTime,
            'timestamp': timestamp,
            'intList': <int>[4, 3],
            'docRef': firestore.doc('tests/doc'),
            'blob': Blob(Uint8List.fromList([1, 2, 3])),
            'geoPoint': GeoPoint(1.2, 4),
            'serverTimestamp': FieldValue.serverTimestamp,
            'subData': {
              'localDateTime': localDateTime,
              'inner': {'int': 1234}
            }
          };

          await docRef.set(data);
          data = (await docRef.get()).data;

          if (firestoreService.supportsTimestampsInSnapshots) {
            expect(data['serverTimestamp'], const TypeMatcher<Timestamp>());
          } else {
            expect((data['serverTimestamp'] as DateTime).isUtc, isFalse);
          }
          expect((data['docRef'] as DocumentReference).path, 'tests/doc');
          data.remove('serverTimestamp');
          data.remove('docRef');
          expect(data, {
            'string': 'string_value',
            'int': 12345678901,
            'num': 3.1416,
            'bool': true,
            'localDateTime': firestoreService.supportsTimestampsInSnapshots
                ? Timestamp.fromDateTime(localDateTime)
                : localDateTime,
            'utcDateTime': firestoreService.supportsTimestampsInSnapshots
                ? Timestamp.fromDateTime(utcDateTime)
                : utcDateTime.toLocal(),
            'timestamp': firestoreService.supportsTimestampsInSnapshots
                ? timestampAdaptPrecision(firestoreService, timestamp)
                : timestamp.toDateTime(),
            'intList': <int>[4, 3],
            'blob': Blob(Uint8List.fromList([1, 2, 3])),
            'geoPoint': GeoPoint(1.2, 4),
            'subData': {
              'localDateTime': firestoreService.supportsTimestampsInSnapshots
                  ? Timestamp.fromDateTime(localDateTime)
                  : localDateTime,
              'inner': {'int': 1234}
            }
          });
        },
      );

      test('deleteField', () async {
        var testsRef = getTestsRef()!;
        var docRef = testsRef.doc('delete_field');
        var data = <String, Object?>{
          'some_key': 'some_value',
          'other_key': 'other_value'
        };
        await docRef.set(data);
        data = (await docRef.get()).data;
        expect(data, {'some_key': 'some_value', 'other_key': 'other_value'});

        data = {'some_key': FieldValue.delete};
        await docRef.update(data);
        data = (await docRef.get()).data;
        expect(data, {'other_key': 'other_value'});
      });
      test('array', () async {
        if (firestoreService.supportsFieldValueArray) {
          var testsRef = getTestsRef()!;
          var docRef = testsRef.doc('array_union');

          // Test creating an array
          var data = <String, Object?>{
            'some_array': FieldValue.arrayUnion([1]),
            // create to be updated later as an array
            'not_array': 2,
          };
          await docRef.set(data);
          data = (await docRef.get()).data;
          expect(data, {
            'some_array': [1],
            'not_array': 2
          });

          // Test update arrayUnion and overriding a non array field
          data = <String, Object?>{
            'some_array': FieldValue.arrayUnion([1, 3]),
            'not_array': FieldValue.arrayUnion([4, 5]),
          };
          await docRef.update(data);
          data = (await docRef.get()).data;
          expect(data, {
            'some_array': [1, 3],
            'not_array': [4, 5],
          });

          // Test arrayRemove
          data = <String, Object?>{
            'some_array': FieldValue.arrayRemove([1]),
            'not_array': FieldValue.arrayRemove([4, 6]),
            'not_existing': FieldValue.arrayRemove([7]),
          };
          await docRef.update(data);
          data = (await docRef.get()).data;
          expect(data, {
            'some_array': [3],
            'not_array': [5],
            'not_existing': []
          });

          // Test update using set with merge
          data = <String, Object?>{
            'some_array': FieldValue.arrayUnion([8]),
            'not_array': FieldValue.arrayRemove([5]),
            'merged_not_existing': FieldValue.arrayRemove([9])
          };
          await docRef.set(data, SetOptions(merge: true));
          data = (await docRef.get()).data;
          expect(data, {
            'some_array': [3, 8],
            'not_array': [],
            'not_existing': [],
            'merged_not_existing': [],
          });

          // Test update using set no merge
          data = <String, Object?>{
            'some_array': FieldValue.arrayUnion([3, 6]),
            'no_merge_not_existing': FieldValue.arrayRemove([10]),
          };
          await docRef.set(data);
          data = (await docRef.get()).data;
          expect(data, {
            'some_array': [3, 6],
            'no_merge_not_existing': []
          });
        } else {
          print('supportsFieldValueArray false');
        }
      });

      //test('subData')
    });

    group('DocumentReference', () {
      test('equals', () {
        var ref1 = firestore.doc('test/doc1');
        var ref2 = firestore.doc('test/doc1');
        expect(ref1, ref2);
        expect(ref1.hashCode, ref2.hashCode);
        ref2 = firestore.doc('test/doc2');
        expect(ref1, isNot(ref2));
        expect(
            ref1.hashCode,
            isNot(ref2
                .hashCode)); // This could be wrong though but at least ensure it could be true also!
      });
      test('attributes', () {
        var testsRef = getTestsRef()!;
        var docRef = testsRef.doc('document_test_attributes');
        expect(docRef.id, 'document_test_attributes');
        expect(docRef.path, '${testsRef.path}/document_test_attributes');
        expect(docRef.parent, const TypeMatcher<CollectionReference>());
        expect(docRef.parent!.id, 'tests');
      });

      test('set subfield', () async {
        var testsRef = getTestsRef()!;
        var docRef = testsRef.doc('document_set_sub_field');
        await docRef.set({'sub.field': 1});
        expect((await docRef.get()).data, {'sub.field': 1});
      }); //skip: 'Not working with sembast yet');

      test('update sub.field', () async {
        var testsRef = getTestsRef()!;
        var docRef = testsRef.doc('update');
        await docRef.set({'created': 1, 'modified': 2});
        await docRef.update({'modified': 22, 'added': 3, 'sub.field': 4});
        expect((await docRef.get()).data, {
          'created': 1,
          'modified': 22,
          'added': 3,
          'sub': {'field': 4}
        });
      });

      test('update nested subfield', () async {
        var testsRef = getTestsRef()!;
        var docRef = testsRef.doc('update_nested_sub_field');
        await docRef.set({
          'a': {
            'b': {'c': 1}
          }
        });
        await docRef.update({
          'a.added': 2,
          'a.b.added': 3,
          'a.b.c.replaced': 4,
          'x': {'sub.replace': 5}
        });
        expect((await docRef.get()).data, {
          'a': {
            'added': 2,
            'b': {
              'added': 3,
              'c': {'replaced': 4}
            }
          },
          'x': {'sub.replace': 5}
        });
      });

      test('merge sub.field on null', () async {
        var testsRef = getTestsRef()!;
        var docRef = testsRef.doc('merge_sub_field_on_null');
        await docRef.delete();
        await docRef.set({'sub.field': 1}, SetOptions()..merge = true);
        expect((await docRef.get()).data, {'sub.field': 1});
      });

      // This only fails on node
      test('update invalid sub map', () async {
        var testsRef = getTestsRef()!;
        var docRef = testsRef.doc('update');
        await docRef.set({'created': 1, 'modified': 2});
        // Here we have a sub map, not support by update!
        await docRef.update({
          'modified': 22,
          'added': 3,
          'sub': {'field': 4}
        });
        expect((await docRef.get()).data, {
          'created': 1,
          'modified': 22,
          'added': 3,
          'sub': {'field': 4}
        });
      });

      test('simpleOnSnapshot', () async {
        var testsRef = getTestsRef()!;
        var docRef = testsRef.doc('simple_onSnapshot');
        await docRef.set({'test': 1});
        if (firestoreService.supportsTrackChanges) {
          expect((await docRef.onSnapshot().first).data, {'test': 1});
        }
      });

      test('onSnapshot', () async {
        var testsRef = getTestsRef()!;
        var docRef = testsRef.doc('onSnapshot');

        // delete it
        await docRef.delete();

        if (firestoreService.supportsTrackChanges) {
          var stepCount = 4;
          var completers =
              List.generate(stepCount, (_) => Completer<DocumentSnapshot>());
          var count = 0;
          var subscription =
              docRef.onSnapshot().listen((DocumentSnapshot documentSnapshot) {
            if (count < stepCount) {
              completers[count++].complete(documentSnapshot);
            }
          });
          var index = 0;
          // wait for receiving first data
          var snapshot = await completers[index++].future;
          expect(snapshot.exists, isFalse);

          // create it
          await docRef.set({});
          // wait for receiving change data
          snapshot = await completers[index++].future;
          expect(snapshot.exists, isTrue);
          expect(snapshot.data, {});

          // modify it
          await docRef.set({'value': 1});
          // wait for receiving change data
          snapshot = await completers[index++].future;
          expect(snapshot.exists, isTrue);
          expect(snapshot.data, {'value': 1});

          // delete it
          await docRef.delete();
          // wait for receiving change data
          snapshot = await completers[index++].future;
          expect(snapshot.exists, isFalse);

          await subscription.cancel();
        }
      });

      test('SetOptions', () async {
        var testsRef = getTestsRef()!;
        var docRef = testsRef.doc('setOptions');

        await docRef.set({'value1': 1, 'value2': 2});
        // Set with merge, value1 should remain
        await docRef.set({'value2': 3}, SetOptions(merge: true));
        var readData = (await docRef.get()).data;
        expect(readData, {'value1': 1, 'value2': 3});

        // Set without merge, value1 should be gone
        await docRef.set({'value2': 4});
        readData = (await docRef.get()).data;
        expect(readData, {'value2': 4});
      });
    });

    group('CollectionReference', () {
      test('equals', () {
        var ref1 = firestore.collection('test1');
        var ref2 = firestore.collection('test1');
        expect(ref1, ref2);
        expect(ref1.hashCode, ref2.hashCode);
        ref2 = firestore.collection('test2');
        expect(ref1, isNot(ref2));
        expect(
            ref1.hashCode,
            isNot(ref2
                .hashCode)); // This could be wrong though but at least ensure it could be true also!
      });
      test('bad path', () async {
        var testsRef = getTestsRef()!;
        try {
          testsRef.doc('path').collection('bad/path');
          fail('should fail');
          // Document references must have an even number of segments,
        } catch (e) {
          expect(e, isNot(const TypeMatcher<TestFailure>()));
        }
      });

      test('attributes', () {
        var testsRef = getTestsRef()!;
        var collRef = testsRef.doc('collection_test').collection('attributes');
        expect(collRef.id, 'attributes');
        expect(collRef.path, '${testsRef.path}/collection_test/attributes');
        expect(collRef.parent, const TypeMatcher<DocumentReference>());
        expect(collRef.parent!.id, 'collection_test');

        // it seems the parent is not null as expected here...
        // however the path is empty...
        // Not supported on browser
        // expect(firestore.collection('tests').parent.path, '');
        // Not supported on browser
        // expect(firestore.collection('/tests').parent.path, '');
      });

      test('empty', () async {
        var testsRef = getTestsRef()!;
        var collRef = testsRef.doc('collection_test').collection('empty');
        final querySnapshot = await collRef.get();
        var list = querySnapshot.docs;
        expect(list, isEmpty);
        expect(await collRef.count(), 0);
      });

      test('snapshotMetadata', () async {
        var testsRef = getTestsRef()!;
        var collRef = testsRef.doc('collection_test').collection('metadata');
        final querySnapshot = await collRef.get();
        var list = querySnapshot.docs;
        expect(list, isEmpty);
        expect(await collRef.count(), 0);
      });

      test('single', () async {
        var testsRef = getTestsRef()!;
        var collRef = testsRef.doc('collection_test').collection('single');
        var docRef = collRef.doc('one');
        await docRef.set({});
        final querySnapshot = await collRef.get();
        var list = querySnapshot.docs;
        expect(list.length, 1);
        expect(list.first.ref.id, 'one');
        expect(await collRef.count(), 1);
      });

      test('select', () async {
        var testsRef = getTestsRef()!;
        var collRef = testsRef.doc('collection_test').collection('select');
        var docRef = collRef.doc('one');
        await docRef.set({'field1': 1, 'field2': 2});
        expect(await collRef.count(), 1);
        var querySnapshot = await collRef.select(['field1']).get();
        var data = querySnapshot.docs.first.data;
        if (firestoreService.supportsQuerySelect) {
          expect(data, {'field1': 1});
        } else {
          expect(data, {'field1': 1, 'field2': 2});
        }
        querySnapshot = await collRef.select(['field2']).get();
        data = querySnapshot.docs.first.data;
        if (firestoreService.supportsQuerySelect) {
          expect(data, {'field2': 2});
        } else {
          expect(data, {'field1': 1, 'field2': 2});
        }

        querySnapshot = await collRef.select(['field1', 'field2']).get();
        data = querySnapshot.docs.first.data;
        expect(data, {'field1': 1, 'field2': 2});
      });

      test('order_by_name', () async {
        var testsRef = getTestsRef()!;
        var collRef = testsRef.doc('collection_test').collection('order');
        await deleteCollection(firestore, collRef);
        var twoRef = collRef.doc('two');
        await twoRef.set({});
        var oneRef = collRef.doc('one');
        await oneRef.set({});
        var querySnapshot = await collRef.get();
        // Order by name by default
        expect(querySnapshot.docs[0].ref.path, oneRef.path);
        expect(querySnapshot.docs[1].ref.path, twoRef.path);

        expect(await collRef.count(), 2);

        querySnapshot = await collRef.orderBy(firestoreNameFieldPath).get();
        // Order by name by default
        expect(querySnapshot.docs[0].ref.path, oneRef.path);
        expect(querySnapshot.docs[1].ref.path, twoRef.path);
      });

      test('order_by_key', () async {
        var testsRef = getTestsRef()!;
        var collRef =
            testsRef.doc('collection_test').collection('order_by_key');
        await deleteCollection(firestore, collRef);
        var oneRef = collRef.doc('one');
        await oneRef.set({});
        var twoRef = collRef.doc('two');
        await twoRef.set({});
        var threeRef = collRef.doc('three');
        await threeRef.set({});

        var querySnapshot = await collRef.orderById().get();
        // Order by name by default
        expect(querySnapshot.ids, [oneRef, threeRef, twoRef].ids);
        querySnapshot = await collRef.orderById(descending: true).get();
        // Order by name by default
        expect(querySnapshot.ids, [twoRef, threeRef, oneRef].ids);
      }, skip: 'Not supported on all platforms');

      /// Requires an index
      test('where_and_order_by_name', () async {
        var testsRef = getTestsRef()!;
        var collRef =
            testsRef.doc('collection_test').collection('where_and_order');
        await deleteCollection(firestore, collRef);
        var oneRef = collRef.doc('one');
        var twoRef = collRef.doc('two');
        var threeRef = collRef.doc('three');
        await firestore.runTransaction((transaction) {
          transaction.set(oneRef, {'name': 1, 'target': 1});
          transaction.set(twoRef, {'name': 2, 'target': 1});
          transaction.set(threeRef, {'name': 3, 'target': 2});
        });

        var query = collRef
            .where('target', isEqualTo: 1)
            .orderBy('name', descending: true);
        var querySnapshot = await collRef.get();
        // Order by name by default
        expect(docsKeys(querySnapshot.docs), [twoRef, oneRef]);

        expect(await query.count(), 2);
      }, skip: true);

      bool isNodePlatform() {
        return firestoreService.toString().contains('FirestoreServiceNode');
      }

      test('order_desc_field_and_key', () async {
        try {
          var testsRef = getTestsRef()!;
          var collRef = testsRef
              .doc('collection_test')
              .collection('order_desc_field_and_key');
          await deleteCollection(firestore, collRef);
          var oneRef = collRef.doc('one');
          await oneRef.set({'value': 2});
          var twoRef = collRef.doc('two');
          await twoRef.set({'value': 1});
          var threeRef = collRef.doc('three');
          await threeRef.set({'value': 1});

          QuerySnapshot querySnapshot;

          querySnapshot = await collRef
              .orderBy('value', descending: true)
              .orderBy(firestoreNameFieldPath)
              .get();
          // Order by name by default
          expect(querySnapshot.docs[0].ref.path, oneRef.path);
          expect(querySnapshot.docs[1].ref.path, threeRef.path);
          expect(querySnapshot.docs[2].ref.path, twoRef.path);

          querySnapshot = await collRef
              .orderBy('value', descending: true)
              .orderBy(firestoreNameFieldPath)
              .startAt(values: [1, 'three']).get();
          // Order by name by default

          expect(querySnapshot.docs[0].ref.path, threeRef.path);
          expect(querySnapshot.docs[1].ref.path, twoRef.path);
        } catch (e) {
          // Allow failure on node
          if (isNodePlatform()) {
            print('failure $e on node');
          } else {
            rethrow;
          }
        }
      });

      test('between', () async {
        var testsRef = getTestsRef()!;
        var collRef = testsRef.doc('collection_test').collection('between');
        await deleteCollection(firestore, collRef);
        var oneRef = collRef.doc('2_1');
        await oneRef.set({'value': 1});
        var twoRef = collRef.doc('3_2');
        await twoRef.set({'value': 2});
        var threeRef = collRef.doc('1_3');
        await threeRef.set({'value': 3});

        var querySnapshot = await collRef.orderBy('value').get();
        expect(querySnapshot.ids, [oneRef, twoRef, threeRef].ids);
        querySnapshot = await collRef
            .orderBy('value')
            .startAt(values: [2]).endBefore(values: [3]).get();
        expect(querySnapshot.ids, [twoRef].ids);
        querySnapshot = await collRef.orderBy('value', descending: true).get();
        expect(querySnapshot.ids, [threeRef, twoRef, oneRef].ids);
      });

      test('complex', () async {
        var testsRef = getTestsRef()!;
        var collRef = testsRef.doc('collection_test').collection('many');
        var docRefOne = collRef.doc('one');
        List<DocumentSnapshot> list;
        await docRefOne.set({
          'array': [3, 4],
          'value': 1,
          'date': DateTime.fromMillisecondsSinceEpoch(2),
          'timestamp': Timestamp(2, 0),
          'sub': {'value': 'b'}
        });
        var docRefTwo = collRef.doc('two');
        await docRefTwo.set({
          'value': 2,
          'date': DateTime.fromMillisecondsSinceEpoch(1),
          'sub': {'value': 'a'}
        });
        // limit
        var querySnapshot = await collRef.limit(1).get();
        list = querySnapshot.docs;
        expect(list.length, 1);

        /*
        // offset
        querySnapshot = await collRef.orderBy('value').offset(1).get();
        list = querySnapshot.docs;
        expect(list.length, 1);
        */

        // order by
        querySnapshot = await collRef.orderBy('value').get();
        list = querySnapshot.docs;
        expect(list.length, 2);
        expect(list.first.ref.id, 'one');

        // order by date
        querySnapshot = await collRef.orderBy('date').get();
        list = querySnapshot.docs;
        expect(list.length, 2);
        expect(list.first.ref.id, 'two');

        // order by timestamp
        querySnapshot = await collRef.orderBy('timestamp').get();
        list = querySnapshot.docs;
        expect(list.length, 1);
        expect(list.first.ref.id, 'one');

        // order by sub field
        querySnapshot = await collRef.orderBy('sub.value').get();
        list = querySnapshot.docs;
        expect(list.length, 2);
        expect(list.first.ref.id, 'two');

        // desc
        querySnapshot = await collRef.orderBy('value', descending: true).get();
        list = querySnapshot.docs;
        expect(list.length, 2);
        expect(list.first.ref.id, 'two');

        // start at
        querySnapshot =
            await collRef.orderBy('value').startAt(values: [2]).get();
        list = querySnapshot.docs;
        expect(list.length, 1, reason: 'check startAt implementation');
        expect(list.first.ref.id, 'two');

        // start after
        querySnapshot =
            await collRef.orderBy('value').startAfter(values: [1]).get();
        list = querySnapshot.docs;
        expect(list.length, 1, reason: 'check startAfter implementation');
        expect(list.first.ref.id, 'two');

        // end at
        querySnapshot = await collRef.orderBy('value').endAt(values: [1]).get();
        list = querySnapshot.docs;
        expect(list.length, 1, reason: 'check endAt implementation');
        expect(list.first.ref.id, 'one');

        // end before
        querySnapshot =
            await collRef.orderBy('value').endBefore(values: [2]).get();
        list = querySnapshot.docs;
        expect(list.length, 1);
        expect(list.first.ref.id, 'one');

        if (firestoreService.supportsQuerySnapshotCursor) {
          // start after using snapshot
          querySnapshot = await collRef
              .orderBy('value')
              .startAfter(snapshot: list.first)
              .get();
          list = querySnapshot.docs;
          expect(list.length, 1);
          expect(list.first.ref.id, 'two');
        }

        // where >
        querySnapshot = await collRef.where('value', isGreaterThan: 1).get();
        list = querySnapshot.docs;
        expect(list.length, 1);
        expect(list.first.ref.id, 'two');

        // where >=
        querySnapshot =
            await collRef.where('value', isGreaterThanOrEqualTo: 2).get();
        list = querySnapshot.docs;
        expect(list.length, 1);
        expect(list.first.ref.id, 'two');

        // where >= timestamp
        querySnapshot = await collRef
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp(2, 0))
            .get();
        list = querySnapshot.docs;

        expect(list.length, 1);
        expect(list.first.ref.id, 'one');

        // where == timestamp
        querySnapshot = await collRef
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp(2, 0))
            .get();
        list = querySnapshot.docs;

        expect(list.length, 1);
        expect(list.first.ref.id, 'one');

        // where > timestamp
        querySnapshot = await collRef
            .where('timestamp', isGreaterThan: Timestamp(2, 0))
            .get();
        list = querySnapshot.docs;
        expect(list.length, 0);

        // where > timestamp
        querySnapshot = await collRef
            .where('timestamp', isGreaterThan: Timestamp(1, 1))
            .get();
        list = querySnapshot.docs;
        expect(list.length, 1);
        expect(list.first.ref.id, 'one');

        // where <
        querySnapshot = await collRef.where('value', isLessThan: 2).get();
        list = querySnapshot.docs;
        expect(list.length, 1);
        expect(list.first.ref.id, 'one');

        // where <=
        querySnapshot =
            await collRef.where('value', isLessThanOrEqualTo: 1).get();
        list = querySnapshot.docs;
        expect(list.length, 1);
        expect(list.first.ref.id, 'one');

        // array contains
        querySnapshot = await collRef.where('array', arrayContains: 4).get();
        list = querySnapshot.docs;
        expect(list.length, 1);
        expect(list.first.ref.id, 'one');

        querySnapshot = await collRef.where('array', arrayContains: 5).get();
        list = querySnapshot.docs;
        expect(list.length, 0);

        // failed on rest
        try {
          querySnapshot =
              await collRef.where('array', arrayContainsAny: [4]).get();
          list = querySnapshot.docs;
          expect(list.length, 1);
          expect(list.first.ref.id, 'one');
        } catch (e) {
          print('Allow rest failure: $e');
        }

        // complex object
        querySnapshot =
            await collRef.where('sub', isEqualTo: {'value': 'a'}).get();
        list = querySnapshot.docs;
        expect(list.length, 1);
        expect(list.first.ref.id, 'two');

        // ordered by sub (complex object)
        querySnapshot = await collRef.orderBy('sub').get();
        list = querySnapshot.docs;
        expect(list.length, 2);
        expect(list.first.ref.id, 'two');
      });

      test('array_complex', () async {
        var testsRef = getTestsRef()!;
        var collRef = testsRef.doc('collection_test').collection('array');
        var docRefOne = collRef.doc('one');
        List<DocumentSnapshot> list;
        await docRefOne.set({
          'array': [3, 4],
          'timestamp_array': [Timestamp(1, 1)]
        });
        var docRefTwo = collRef.doc('two');
        await docRefTwo.set({
          'array': [3],
          'timestamp_array': [Timestamp(1, 1), Timestamp(2, 2)]
        });
        var docRefThree = collRef.doc('three');
        await docRefThree.set({
          'array': [5],
        });

        // array contains
        var querySnapshot =
            await collRef.where('array', arrayContains: 4).get();
        list = querySnapshot.docs;
        expect(list.length, 1);
        expect(list.first.ref.id, 'one');

        querySnapshot = await collRef.where('array', arrayContains: 6).get();
        list = querySnapshot.docs;
        expect(list.length, 0);

        try {
          // array contains any
          try {
            await collRef.where('array', arrayContainsAny: []).get();
            fail('should fail');
          } catch (e) {
            // devPrint(e);
            // FirebaseError: [code=invalid-argument]: Invalid Query. A non-empty array is required for 'array-contains-any' filters.
          }

          querySnapshot =
              await collRef.where('array', arrayContainsAny: [4]).get();
          list = querySnapshot.docs;
          expect(list.length, 1);
          expect(list.first.ref.id, 'one');

          querySnapshot =
              await collRef.where('array', arrayContainsAny: [4, 5]).get();
          list = querySnapshot.docs;
          expect(list.length, 2);
          expect(list.first.ref.id, 'one');

          querySnapshot = await collRef.where('timestamp_array',
              arrayContainsAny: [Timestamp(1, 1)]).get();
          list = querySnapshot.docs;
          expect(list.length, 2);
          expect(list.first.ref.id, 'one');
        } catch (e) {
          print('Allow REST failure for: $e');
        }
      });

      test('order', () async {
        var testsRef = getTestsRef()!;
        var collRef =
            testsRef.doc('collection_test').collection('complex_timestamp');
        var docRefOne = collRef.doc('one');
        var docRefTwo = collRef.doc('two');

        List<DocumentSnapshot> list;
        var timestamp2 = Timestamp.fromMillisecondsSinceEpoch(2);
        var date2 = DateTime.fromMillisecondsSinceEpoch(2);

        var map2 = <String, Object?>{
          'date': date2,
          'int': 2,
          'text': '2',
          'double': 1.5
        };
        if (firestoreService.supportsTimestamps) {
          map2['timestamp'] = timestamp2;
        }

        var timestamp1 = Timestamp.fromMillisecondsSinceEpoch(1);
        var date1 = DateTime.fromMillisecondsSinceEpoch(1);

        var map1 = <String, Object?>{
          'date': date1,
          'int': 1,
          'text': '1',
          'double': 0.5
        };
        if (firestoreService.supportsTimestamps) {
          map1['timestamp'] = timestamp1;
        }

        await docRefTwo.set(map2);
        await docRefOne.set(map1);

        Future testField<T>(String field, T value1, T value2) async {
          var reason = '$field $value1 $value2';
          // order by
          var querySnapshot = await collRef.orderBy(field).get();
          list = querySnapshot.docs;
          expect(list.length, 2);
          expect(list.first.ref.id, 'one', reason: reason);

          // start at
          querySnapshot =
              await collRef.orderBy(field).startAt(values: [value2]).get();
          list = querySnapshot.docs;
          expect(list.length, 1, reason: reason);
          expect(list.first.ref.id, 'two');

          // start after
          querySnapshot =
              await collRef.orderBy(field).startAfter(values: [value1]).get();
          list = querySnapshot.docs;
          expect(list.length, 1);
          expect(list.first.ref.id, 'two');

          // end at
          querySnapshot =
              await collRef.orderBy(field).endAt(values: [value1]).get();
          list = querySnapshot.docs;
          expect(list.length, 1);
          expect(list.first.ref.id, 'one');

          // end before
          querySnapshot =
              await collRef.orderBy(field).endBefore(values: [value2]).get();
          list = querySnapshot.docs;
          expect(list.length, 1);
          expect(list.first.ref.id, 'one');

          if (firestoreService.supportsQuerySnapshotCursor) {
            // start after using snapshot
            querySnapshot = await collRef
                .orderBy(field)
                .startAfter(snapshot: list.first)
                .get();
            list = querySnapshot.docs;
            expect(list.length, 1);
            expect(list.first.ref.id, 'two');
          }

          // where >
          querySnapshot =
              await collRef.where(field, isGreaterThan: value1).get();
          list = querySnapshot.docs;
          expect(list.length, 1);
          expect(list.first.ref.id, 'two');

          // where >=
          querySnapshot =
              await collRef.where(field, isGreaterThanOrEqualTo: value2).get();
          list = querySnapshot.docs;
          expect(list.length, 1);
          expect(list.first.ref.id, 'two');

          // where <
          querySnapshot = await collRef.where(field, isLessThan: value2).get();
          list = querySnapshot.docs;
          expect(list.length, 1);
          expect(list.first.ref.id, 'one');

          // where <=
          querySnapshot =
              await collRef.where(field, isLessThanOrEqualTo: value1).get();
          list = querySnapshot.docs;
          expect(list.length, 1);
          expect(list.first.ref.id, 'one');
        }

        await testField('int', 1, 2);

        await testField('double', .5, 1.5);
        await testField('text', '1', '2');
        await testField('date', date1, date2);
        if (firestoreService.supportsTimestamps) {
          await testField('timestamp', timestamp1, timestamp2);
        }
      });

      test('nested_object_order', () async {
        var testsRef = getTestsRef()!;
        var collRef = testsRef.doc('nested_order_test').collection('many');
        var docRefOne = collRef.doc('one');
        await docRefOne.set({
          'sub': {'value': 'b'}
        });
        var docRefTwo = collRef.doc('two');
        await docRefTwo.set({
          'sub': {'value': 'a'}
        });
        var docRefThree = collRef.doc('three');
        await docRefThree.set({'no_sub': false});
        var docRefFour = collRef.doc('four');
        await docRefFour.set({
          'sub': {'other': 'a', 'value': 'c'}
        });

        List<String> querySnapshotDocIds(QuerySnapshot querySnapshot) {
          return querySnapshot.docs.map((snapshot) => snapshot.ref.id).toList();
        }

        // complex object
        var querySnapshot =
            await collRef.where('sub', isEqualTo: {'value': 'a'}).get();
        expect(querySnapshotDocIds(querySnapshot), ['two']);

        // ordered by sub (complex object)
        querySnapshot = await collRef.orderBy('sub').get();
        expect(querySnapshotDocIds(querySnapshot), ['four', 'two', 'one']);
      });

      test('list_object_order', () async {
        var testsRef = getTestsRef()!;
        var collRef = testsRef.doc('list_order_test').collection('many');
        var docRefOne = collRef.doc('one');
        await docRefOne.set({
          'sub': ['b']
        });
        var docRefTwo = collRef.doc('two');
        await docRefTwo.set({
          'sub': ['a']
        });
        var docRefThree = collRef.doc('three');
        await docRefThree.set({'no_sub': false});
        var docRefFour = collRef.doc('four');
        await docRefFour.set({
          'sub': ['a', 'b']
        });

        // complex object
        var querySnapshot = await collRef.where('sub', isEqualTo: ['a']).get();
        expect(querySnapshotDocIds(querySnapshot), ['two']);

        // ordered by sub (complex object)
        querySnapshot = await collRef.orderBy('sub').get();
        expect(querySnapshotDocIds(querySnapshot), ['two', 'four', 'one']);
      });

      test('whereIn', () async {
        var testsRef = getTestsRef()!;
        var collRef = testsRef.doc('where_in_test').collection('simple');
        var docRefOne = collRef.doc('one');
        await docRefOne.set({'value': 1});
        var docRefTwo = collRef.doc('two');
        await docRefTwo.set({'value': 2});
        var querySnapshot = await collRef.where('value', whereIn: [1]).get();
        expect(querySnapshotDocIds(querySnapshot), ['one']);
        querySnapshot = await collRef.where('value', whereIn: [1, 2, 3]).get();
        expect(querySnapshotDocIds(querySnapshot), ['one', 'two']);
      });

      test('onQuerySnapshot', () async {
        var testsRef = getTestsRef()!;
        var collRef = testsRef.doc('query_test').collection('onSnapshot');

        var docRef = collRef.doc('item');
        // delete it
        await docRef.delete();
        if (firestoreService.supportsTrackChanges) {
          var completer1 = Completer<void>();
          var completer2 = Completer<void>();
          var completer3 = Completer<void>();
          var completer4 = Completer<void>();
          var count = 0;
          var subscription =
              collRef.onSnapshot().listen((QuerySnapshot querySnapshot) {
            if (++count == 1) {
              // first step ignore the result
              completer1.complete();
            } else if (count == 2) {
              // second step expect an added item
              expect(querySnapshot.documentChanges.length, 1);
              expect(querySnapshot.documentChanges.first.type,
                  DocumentChangeType.added);

              completer2.complete();
            } else if (count == 3) {
              // second step expect a modified item
              expect(querySnapshot.documentChanges.length, 1);
              expect(querySnapshot.documentChanges.first.type,
                  DocumentChangeType.modified);

              completer3.complete();
            } else if (count == 4) {
              // second step expect a deletion
              expect(querySnapshot.documentChanges.length, 1);
              expect(querySnapshot.documentChanges.first.type,
                  DocumentChangeType.removed);

              completer4.complete();
            }
          });
          // wait for receiving first data
          await completer1.future;

          // create it
          await docRef.set({});

          // wait for receiving change data
          await completer2.future;

          // modify it
          await docRef.set({'value': 1});

          // wait for receiving change data
          await completer3.future;

          // delete it
          await docRef.delete();

          // wait for receiving change data
          await completer4.future;

          await subscription.cancel();
        }
      });
    });

    group('WriteBatch', () {
      test('create_delete', () async {
        var testsRef = getTestsRef()!;
        var collRef = testsRef.doc('batch_test').collection('delete');

        var deleteRef = collRef.doc('delete');
        var createRef = collRef.doc('create');

        // create it
        await deleteRef.set({});
        await createRef.delete();

        expect((await deleteRef.get()).exists, isTrue);
        expect((await createRef.get()).exists, isFalse);

        var batch = firestore.batch();
        batch.delete(deleteRef);
        batch.set(createRef, {});
        await batch.commit();

        expect((await deleteRef.get()).exists, isFalse);
        expect((await createRef.get()).exists, isTrue);
      });

      group('all', () {
        test('batch', () async {
          var collRef = getTestsRef()!.doc('batch_test').collection('all');
          // this one will be created
          var doc1Ref = collRef.doc('item1');
          // this one will be updated
          var doc2Ref = collRef.doc('item2');
          // this one will be set
          var doc3Ref = collRef.doc('item3');
          // this one will be deleted
          var doc4Ref = collRef.doc('item4');
          // this one will be set with merge options
          var doc5Ref = collRef.doc('item5');
          // this one will be set with merge options but deleted before
          var doc6Ref = collRef.doc('item6');

          await doc1Ref.delete();
          await doc2Ref.set({'value': 2});
          await doc4Ref.set({'value': 4});
          await doc5Ref.set({'value': 5});
          await doc6Ref.delete();

          var batch = firestore.batch();
          batch.set(doc1Ref, {'value': 1});
          batch.update(doc2Ref, {'other.value': 2});
          batch.set(doc3Ref, {'value': 3});
          batch.delete(doc4Ref);
          batch.set(doc5Ref, {'other': 5}, SetOptions(merge: true));
          batch.set(doc6Ref, {'other': 6}, SetOptions(merge: true));
          await batch.commit();

          expect((await doc1Ref.get()).data, {'value': 1});
          expect((await doc2Ref.get()).data, {
            'value': 2,
            'other': {'value': 2}
          });
          expect((await doc3Ref.get()).data, {'value': 3});
          expect((await doc4Ref.get()).exists, isFalse);
          expect((await doc5Ref.get()).data, {'value': 5, 'other': 5});
          expect((await doc6Ref.get()).data, {'other': 6});
        });
      });

      group('Transaction', () {
        test('concurrent_get_update', () async {
          var testsRef = getTestsRef()!;
          var collRef =
              testsRef.doc('transaction_test').collection('get_update');
          var ref = collRef.doc('item');
          await ref.set({'value': 1});

          var modifiedCount = 0;
          await firestore.runTransaction((txn) async {
            var snapshot = (await txn.get(ref));

            var data = snapshot.data;
            // devPrint('get ${data}');
            if (modifiedCount++ == 0) {
              await ref.set({'value': 10});
            }

            data['value'] = (data['value'] as int) + 1;
            txn.update(ref, data);
          });

          // we should run the transaction twice...
          expect(modifiedCount, 2);

          expect((await ref.get()).data, {'value': 11});
        }, skip: skipConcurrentTransactionTests);

        test('get_update', () async {
          var testsRef = getTestsRef()!;
          var collRef =
              testsRef.doc('transaction_test').collection('get_update');
          var ref = collRef.doc('item');
          await ref.set({'value': 1});

          await firestore.runTransaction((txn) async {
            var snapshot = (await txn.get(ref));

            var data = snapshot.data;
            if (testsRef is FirestorePathReference) {
              expect((snapshot.ref as FirestorePathReference).firestore,
                  (testsRef as FirestorePathReference).firestore);
            }

            var map = <String, Object?>{};
            map['value'] = (data['value'] as int) + 1;
            txn.update(ref, map);
          });

          expect((await ref.get()).data, {'value': 2});
        });

        test('get_set', () async {
          var testsRef = getTestsRef()!;
          var collRef = testsRef.doc('transaction_test').collection('get_set');
          var ref = collRef.doc('item');
          await ref.set({'value': 1});

          await firestore.runTransaction((txn) async {
            var data = (await txn.get(ref)).data;

            data['value'] = (data['value'] as int) + 1;

            txn.set(ref, data);
          });

          expect((await ref.get()).data, {'value': 2});
        });

        // make sure that after the transaction we're still fine
        test('post_transaction_set', () async {
          var testsRef = getTestsRef()!;
          var collRef =
              testsRef.doc('transaction_test').collection('get_update');
          var ref = collRef.doc('item');
          await ref.set({'value': 1});
        });
      });
      // TODO implement
    });
    test('bug_limit', () async {
      var query = firestore
          .collection('tests')
          .doc('firebase_shim_test')
          .collection('tests')
          .orderBy('timestamp')
          .limit(10)
          .select([]);
      expect((await query.get()).docs, isNotEmpty);
    }, skip: true);
  });
}

/// Test root path to override
String? testRootPath;

/// To get a safe path if specified in setup
String getTestPath(String path) {
  if (testRootPath == null) {
    return path;
  } else {
    return url.join(testRootPath!, path);
  }
}

/// Adapt expected precision, removing micros if timestamps precision is not
/// supported
Timestamp timestampAdaptPrecision(
    FirestoreService service, Timestamp timestamp) {
  if (service.supportsTimestamps) {
    return timestamp;
  } else {
    return Timestamp(
        timestamp.seconds, (timestamp.nanoseconds ~/ 1000000) * 1000000);
  }
}

List<String> querySnapshotDocIds(QuerySnapshot querySnapshot) {
  return querySnapshot.docs.map((snapshot) => snapshot.ref.id).toList();
}
