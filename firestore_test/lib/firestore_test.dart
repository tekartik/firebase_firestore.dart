// ignore_for_file: inference_failure_on_collection_literal
import 'dart:typed_data';

import 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/reference_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore/utils/json_utils.dart';
import 'package:tekartik_firebase_firestore_test/aggregate_query_test.dart';
import 'package:tekartik_firebase_firestore_test/firestore_multi_client_test.dart';
import 'package:tekartik_firebase_firestore_test/timestamp_test.dart';
import 'package:tekartik_firebase_firestore_test/utils_collection_test.dart';
import 'package:tekartik_firebase_firestore_test/utils_query_test.dart';
import 'package:tekartik_firebase_firestore_test/utils_test.dart';
import 'package:tekartik_firebase_firestore_test/vector_value_test.dart';

import 'copy_utils_test.dart';
import 'firestore_document_test.dart';
import 'firestore_track_changes_support_test.dart';
import 'firestore_track_changes_test.dart';
import 'list_collections_test.dart';
import 'query_test.dart';
import 'utils_auto_id_test.dart';

/// collection
@Deprecated('Use FirestoreTestContext')
var testsRefPath = _testsRefPathDefault;
var _testsRefPathDefault = 'tests/tekartik_firestore/tests';
bool skipConcurrentTransactionTests = false;

List<DocumentReference?> docsKeys(List<DocumentSnapshot> snashots) =>
    snashots.map((e) => e.ref).toList();

// @Deprecated('Use runFirestoreTests')
@Deprecated('Use runFirestoreTests')
void run({
  required Firebase firebase,
  required FirestoreService firestoreService,
  AppOptions? options,
  FirestoreTestContext? testContext,
}) {
  _runFirestoreTests(
    firebase: firebase,
    firestoreService: firestoreService,
    options: options,
    testContext: testContext,
  );
}

void runFirestoreTests({
  required Firebase firebase,
  required FirestoreService firestoreService,
  AppOptions? options,
  FirestoreTestContext? testContext,
}) {
  _runFirestoreTests(
    firebase: firebase,
    firestoreService: firestoreService,
    options: options,
    testContext: testContext,
  );
}

class FirestoreTestContext {
  /// Default
  static final defaultRootCollectionPath = _testsRefPathDefault;
  final String? _rootCollectionPath;

  // ignore: unused_field
  final String? _noAuthRootCollectionPath;

  static String getRootCollectionPath(FirestoreTestContext? testContext) =>
      testContext?.rootCollectionPath ?? defaultRootCollectionPath;

  String get rootCollectionPath =>
      _rootCollectionPath ?? defaultRootCollectionPath;

  FirestoreTestContext({
    String? rootCollectionPath,
    String? noAuthRootCollectionPath,
  }) : _rootCollectionPath = rootCollectionPath,
       _noAuthRootCollectionPath = noAuthRootCollectionPath;

  /// can be set later
  int? allowedDelayInReadMs;

  Future<void> sleepReadDelay() async {
    if (allowedDelayInReadMs != null) {
      await Future<void>.delayed(Duration(milliseconds: allowedDelayInReadMs!));
    }
  }

  Future<void> runTestAndIfNeededAllowDelay(
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (_) {
      if (allowedDelayInReadMs != null) {
        await sleepReadDelay();
        await action();
      } else {
        rethrow;
      }
    }
  }
}

Future<void> runTestAndIfNeededAllowDelay(
  FirestoreTestContext? testContext,
  Future<void> Function() action,
) async {
  if (testContext != null) {
    await testContext.runTestAndIfNeededAllowDelay(action);
  } else {
    await action();
  }
}

void _runFirestoreTests({
  required Firebase firebase,
  required FirestoreService firestoreService,
  AppOptions? options,
  FirestoreTestContext? testContext,
}) {
  final app = firebase.initializeApp(options: options);
  runFirestoreAppTests(
    app: app,
    firestoreService: firestoreService,
    options: options,
    testContext: testContext ?? FirestoreTestContext(),
  );
  tearDownAll(() {
    return app.delete();
  });
}

void runFirestoreAppTests({
  required FirebaseApp app,
  required FirestoreService firestoreService,
  AppOptions? options,
  required FirestoreTestContext testContext,
}) {
  var firestore = firestoreService.firestore(app);
  test('app', () {
    expect(firestore.app, app);
    expect(firestore.service, firestoreService);
  });
  runFirestoreCommonTests(
    firestoreService: firestoreService,
    firestore: firestore,
    testContext: testContext,
  );
  runUtilsCollectionTests(
    firestoreService: firestoreService,
    firestore: firestore,
    testContext: testContext,
  );
  runUtilsQueryTest(
    firestoreService: firestoreService,
    firestore: firestore,
    testContext: testContext,
  );
  runFirestoreTrackChangesSupportTests(
    firestoreService: firestoreService,
    firestore: firestore,
    testContext: testContext,
  );
  runFirestoreTrackChangesTests(
    firestoreService: firestoreService,
    firestore: firestore,
    testContext: testContext,
  );
  runFirestoreQueryTests(firestore: firestore, testContext: testContext);
  runListCollectionsTest(firestore: firestore, testContext: testContext);
  runAggregateQueryTest(firestore: firestore, testContext: testContext);
  runFirestoreDocumentTests(firestore: firestore, testContext: testContext);

  utilsTest(
    firestoreService: firestoreService,
    firestore: firestore,
    testContext: testContext,
  );
  utilsAutoIdTest(firestore: firestore, testContext: testContext);
  runCopyUtilsTest(firestore: firestore, testContext: testContext);
  firestoreMulticlientTest(
    firestore1: firestore,
    firestore2: firestore,
    docTopPath: '${testContext.rootCollectionPath}/multi_client',
  );
}

@Deprecated('User runFirestoreCommonTests')
void runApp({
  required FirestoreService firestoreService,
  required Firestore firestore,
}) {
  runFirestoreCommonTests(
    firestoreService: firestoreService,
    firestore: firestore,
    testContext: null,
  );
}

void runFirestoreCommonTests({
  required FirestoreService firestoreService,
  required Firestore firestore,
  required FirestoreTestContext? testContext,
}) {
  var testsRefPath = FirestoreTestContext.getRootCollectionPath(testContext);
  setUpAll(() async {
    if (firestoreService.supportsTimestampsInSnapshots) {
      // force support
      // firestore.settings(FirestoreSettings(timestampsInSnapshots: true));
    }
  });
  group('firestore', () {
    vectorValueGroup(firestore: firestore, testContext: testContext);
    timestampGroup(
      service: firestoreService,
      firestore: firestore,
      testContext: testContext,
    );
    CollectionReference getTestsRef() {
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
        var testsRef = getTestsRef();

        var docRef = await testsRef.add({});
        // Check firestore
        if (testsRef is FirestorePathReference) {
          expect(
            (docRef as FirestorePathReference).firestore,
            (testsRef as FirestorePathReference).firestore,
          );
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
        var testsRef = getTestsRef();
        var docRef = testsRef.doc('dummy_id_that_should_never_exists');
        var snapshot = await docRef.get();
        expect(snapshot.ref, isNotNull);
        // Check firestore
        if (testsRef is FirestorePathReference) {
          expect(
            (docRef as FirestorePathReference).firestore,
            (snapshot.ref as FirestorePathReference).firestore,
          );
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
        var testsRef = getTestsRef();
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
          expect(
            (testsRef as FirestorePathReference).firestore,
            (snapshots[0].ref as FirestorePathReference).firestore,
          );
        }
        // expect(snapshots[1].data, isNull); currently node returns {}
      });

      test('delete', () async {
        var testsRef = getTestsRef();
        var docRef = await testsRef.add({});
        await docRef.delete();

        var snapshot = await docRef.get();
        expect(snapshot.exists, isFalse);
      });

      test('delete_dummy', () async {
        var testsRef = getTestsRef();
        var docRef = testsRef.doc('dummy_id_that_should_never_exists');
        await docRef.delete();
      });

      test('update_dummy', () async {
        var failed = false;
        var testsRef = getTestsRef();
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
        var collRef = firestore.collection(
          url.join(testsRefPath, 'email', 'emails'),
        );
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
        var testsRef = getTestsRef();
        var docRef = testsRef.doc('empty');
        await docRef.set({});
        var snapshot = await docRef.get();
        expect(snapshot.data, {});
        expect(snapshot.exists, isTrue);
      });

      test('bad path', () async {
        var testsRef = getTestsRef();
        try {
          testsRef.doc('bad/path');
          fail('should fail');
          // Document references must have an even number of segments,
        } catch (e) {
          expect(e, isNot(const TypeMatcher<TestFailure>()));
        }
      }, skip: 'Not ok on flutter, ok not to fix');

      test('documentTime', () async {
        var testsRef = getTestsRef();
        var docRef = testsRef.doc('time');
        await docRef.delete();
        var now = Timestamp.now();
        await docRef.set({'test': 1});
        var snapshot = await docRef.get();
        //devPrint('createTime ${snapshot.createTime}');
        //devPrint('updateTime ${snapshot.updateTime}');
        expect(snapshot.data, {'test': 1});

        if (firestoreService.supportsDocumentSnapshotTime) {
          /// Allow some difference
          expect(
            snapshot.updateTime!.seconds - now.seconds,
            greaterThanOrEqualTo(0),
          );
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
            expect(
              snapshot.updateTime!.compareTo(snapshot.createTime),
              greaterThanOrEqualTo(0),
              reason:
                  'createTime ${snapshot.createTime} updateTime ${snapshot.updateTime}',
            );
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
          snapshot = (await testsRef.onSnapshot().first).docs
              .where(
                (DocumentSnapshot snapshot) => snapshot.ref.path == docRef.path,
              )
              .first;
          check();
        }
      });
    });

    group('DocumentData', () {
      test('property', () async {
        var testsRef = getTestsRef();
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
        var testsRef = getTestsRef();
        var localDateTime = DateTime.fromMillisecondsSinceEpoch(1234567890);
        var utcDateTime = DateTime.fromMillisecondsSinceEpoch(
          1234567890,
          isUtc: true,
        );
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
        documentData.setGeoPoint('geoPoint', const GeoPoint(1.2, 4));

        documentData.setFieldValue(
          'serverTimestamp',
          FieldValue.serverTimestamp,
        );
        documentData.setNull('null');

        var subData = DocumentData();
        subData.setDateTime('localDateTime', localDateTime);
        documentData.setData('subData', subData);

        DocumentData? subSubData = DocumentData();
        subData.setData('inner', subSubData);

        await docRef.set(documentData.asMap());
        var snapshot = await docRef.get();
        documentData = DocumentData(snapshot.data);
        expect(documentData.getString('string'), 'string_value');

        expect(documentData.getInt('int'), 12345678901);
        expect(documentData.getNum('num'), 3.1416);
        expect(documentData.getBool('bool'), true);

        expect(documentData.getDateTime('localDateTime'), localDateTime);
        expect(documentData.getDateTime('utcDateTime'), utcDateTime.toLocal());
        // Might only get milliseconds in the browser
        expect(
          documentData.getTimestamp('timestamp'),
          timestampAdaptPrecision(firestoreService, timestamp),
        );
        expect(documentData.getDocumentReference('docRef')!.path, 'tests/doc');
        expect(documentData.getBlob('blob')!.data, [1, 2, 3]);
        expect(documentData.getGeoPoint('geoPoint'), const GeoPoint(1.2, 4));
        expect(
          documentData.getDateTime('serverTimestamp')!.millisecondsSinceEpoch >
              0,
          isTrue,
        );
        expect(documentData.has('null'), isTrue);
        final list = documentData.getList<int>('intList');
        expect(list, [4, 3]);

        subData = documentData.getData('subData')!;
        expect(subData.getDateTime('localDateTime'), localDateTime);

        subSubData = subData.getData('inner');
        expect(subSubData, isNotNull);

        var docInfo = FirestoreDocumentInfo.fromDocumentSnapshot(snapshot);
        var map = docInfo.toJsonMap();
        docInfo = FirestoreDocumentInfo.fromJsonMap(map);
        expect(docInfo.toJsonMap(), map);
      });
    });

    group('Data', () {
      test('string', () async {
        var testsRef = getTestsRef();
        var docRef = testsRef.doc('string');
        await docRef.set({'some_key': 'some_value'});
        expect((await docRef.get()).data, {'some_key': 'some_value'});
        await docRef.delete();
      });

      test('list<data>', () async {
        var testsRef = getTestsRef();
        var docRef = testsRef.doc('list');
        await docRef.set({
          'some_key': [
            {'sub_key': 'some_value'},
          ],
        });
        var snapshot = await docRef.get();
        var documentData = DocumentData(snapshot.data);
        expect(snapshot.data, {
          'some_key': [
            {'sub_key': 'some_value'},
          ],
        });
        var list = documentData.getList<Map<String, Object?>>('some_key')!;
        final sub = DocumentData(list[0]);
        expect(sub.getString('sub_key'), 'some_value');
        await docRef.delete();
      });

      test('date', () async {
        var testsRef = getTestsRef();
        var docRef = testsRef.doc('date');
        var localDateTime = DateTime.fromMillisecondsSinceEpoch(
          1234567890,
        ).toLocal();
        var utcDateTime = DateTime.fromMillisecondsSinceEpoch(
          12345678901,
        ).toUtc();
        await docRef.set({
          'some_date': localDateTime,
          'some_utc_date': utcDateTime,
        });

        void check(Map? data) {
          if (firestoreService.supportsTimestampsInSnapshots) {
            //devPrint(data['some_date'].runtimeType);
            expect(data, {
              'some_date': Timestamp.fromDateTime(localDateTime),
              'some_utc_date': Timestamp.fromDateTime(utcDateTime.toLocal()),
            });
          } else {
            expect(data, {
              'some_date': localDateTime,
              'some_utc_date': utcDateTime.toLocal(),
            });
          }
        }

        check((await docRef.get()).data);

        var snapshot =
            (await testsRef
                    .where('some_date', isEqualTo: localDateTime)
                    .where('some_utc_date', isEqualTo: utcDateTime)
                    .get())
                .docs
                .first;

        check(snapshot.data);
        await docRef.delete();
      });

      test('timestamp_nanos', () async {
        var testsRef = getTestsRef();
        var docRef = testsRef.doc('timestamp');
        var timestamp = Timestamp(1234567890, 1234);
        await docRef.set({'some_timestamp': timestamp});

        var data = (await docRef.get()).data;

        if (firestoreService.supportsTimestampsInSnapshots) {
          expect(
            data,
            {'some_timestamp': timestamp},
            reason:
                'nanos: ${timestamp.nanoseconds} vs ${(data['some_timestamp'] as Timestamp).nanoseconds}',
          );
        } else {
          expect(data, {'some_timestamp': timestamp.toDateTime()});
        }
        await docRef.delete();
      }, skip: true);

      test('timestamp', () async {
        var testsRef = getTestsRef().doc('lookup').collection('timestamp');
        var docRef = testsRef.doc('timestamp');
        var timestamp = Timestamp(1234567890, 123000);
        await docRef.set({'some_timestamp': timestamp});
        void check(Map<String, Object?>? data) {
          if (firestoreService.supportsTimestampsInSnapshots) {
            expect(
              data,
              {'some_timestamp': timestamp},
              reason:
                  'nanos: ${timestamp.nanoseconds} vs ${(data!['some_timestamp'] as Timestamp).nanoseconds}',
            );
          } else {
            expect(data, {'some_timestamp': timestamp.toDateTime()});
          }
        }

        check((await docRef.get()).data);
        var snapshot =
            (await testsRef.where('some_timestamp', isEqualTo: timestamp).get())
                .docs
                .first;
        check(snapshot.data);

        // Try compare
        snapshot =
            (await testsRef
                    .where('some_timestamp', isGreaterThanOrEqualTo: timestamp)
                    .get())
                .docs
                .first;
        check(snapshot.data);

        await docRef.delete();
      }, skip: !firestoreService.supportsTimestamps);

      // All fields that we do not delete
      test('server timestamp', () async {
        var testsRef = getTestsRef();
        var docRef = testsRef.doc('server_timestamp');
        var data = <String, Object?>{
          'serverTimestamp': FieldValue.serverTimestamp,
        };

        await docRef.set(data);
        data = (await docRef.get()).data;

        if (firestoreService.supportsTimestampsInSnapshots) {
          expect(data['serverTimestamp'], const TypeMatcher<Timestamp>());
        } else {
          expect((data['serverTimestamp'] as DateTime).isUtc, isFalse);
        }
      });
      test('null', () async {
        var testsRef = getTestsRef().doc('lookup').collection('null');
        var docRef = testsRef.doc('a');
        var doc2Ref = testsRef.doc('b');
        await docRef.set({'value': 1});
        await doc2Ref.set({'value': null});
        void check(Map<String, Object?>? data) {
          expect(data, {'value': null});
        }

        check((await doc2Ref.get()).data);
        var snapshot =
            (await testsRef.where('value', isNull: true).get()).docs.first;
        check(snapshot.data);

        await docRef.delete();
      });

      test('null', () async {
        var testsRef = getTestsRef().doc('lookup').collection('bool');
        var docRef = testsRef.doc('a');
        var doc2Ref = testsRef.doc('b');
        await docRef.set({'value': null});
        await doc2Ref.set({'value': true});
        void check(Map<String, Object?>? data) {
          expect(data, {'value': true});
        }

        check((await doc2Ref.get()).data);
        var snapshot =
            (await testsRef.where('value', isEqualTo: true).get()).docs.first;
        check(snapshot.data);

        await docRef.delete();
      });

      // All fields that we do not delete
      test('allFields', () async {
        var testsRef = getTestsRef();
        var localDateTime = DateTime.fromMillisecondsSinceEpoch(1234567890);
        var utcDateTime = DateTime.fromMillisecondsSinceEpoch(
          1234567890,
          isUtc: true,
        );
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
          'geoPoint': const GeoPoint(1.2, 4),
          'serverTimestamp': FieldValue.serverTimestamp,
          'subData': {
            'localDateTime': localDateTime,
            'inner': {'int': 1234},
          },
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
          'geoPoint': const GeoPoint(1.2, 4),
          'subData': {
            'localDateTime': firestoreService.supportsTimestampsInSnapshots
                ? Timestamp.fromDateTime(localDateTime)
                : localDateTime,
            'inner': {'int': 1234},
          },
        });
      });

      test('deleteField', () async {
        var testsRef = getTestsRef();
        var docRef = testsRef.doc('delete_field');
        var data = <String, Object?>{
          'some_key': 'some_value',
          'other_key': 'other_value',
        };
        await docRef.set(data);
        data = (await docRef.get()).data;
        expect(data, {'some_key': 'some_value', 'other_key': 'other_value'});

        data = {'some_key': FieldValue.delete};
        await docRef.update(data);
        data = (await docRef.get()).data;
        expect(data, {'other_key': 'other_value'});
      });
      test('setDeleteSubMapField', () async {
        var testsRef = getTestsRef();
        var docRef = testsRef.doc('set_delete_field');
        var data = <String, Object?>{
          'some_key': 'some_value',
          'sub': <String, Object?>{
            'sub_key': 'sub_value',
            'other': 'other_value',
          },
        };
        await docRef.set(data);
        data = (await docRef.get()).data;
        expect(data, {
          'some_key': 'some_value',
          'sub': {'sub_key': 'sub_value', 'other': 'other_value'},
        });

        data = {
          'sub': {'sub_key': FieldValue.delete},
        };
        await docRef.set(data, SetOptions(merge: true));
        data = (await docRef.get()).data;
        expect(data, {
          'some_key': 'some_value',
          'sub': {'other': 'other_value'},
        });
      });
      test('simple merge', () async {
        var testsRef = getTestsRef();
        var docRef = testsRef.doc('simple_merge');
        await docRef.set({'field1': 1});
        await docRef.set({'field2': 2}, SetOptions(merge: true));

        var snapshot = await docRef.get();
        expect(snapshot.data, {'field1': 1, 'field2': 2});
      });
      test('merge', () async {
        var testsRef = getTestsRef();
        var docRef = testsRef.doc('set_merge');
        await docRef.set({
          'field1': 'value1',
          'field2': {
            'sub2': {'sub3': 'value3'},
          },
        });
        await docRef.set({
          'field2': {
            'sub2': {'4321': 'value4', '5sub': 'value5', 'sub6': 'value6'},
            // Use a key that looks like a number on purpose here
          },
        }, SetOptions(merge: true));

        var snapshot = await docRef.get();
        expect(snapshot.data, {
          'field1': 'value1',
          'field2': {
            'sub2': {
              'sub3': 'value3',
              '4321': 'value4',
              '5sub': 'value5',
              'sub6': 'value6',
            },
          },
        });
      });
      test('array', () async {
        if (firestoreService.supportsFieldValueArray) {
          var testsRef = getTestsRef();
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
            'not_array': 2,
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
            'not_existing': [],
          });

          // Test update using set with merge
          data = <String, Object?>{
            'some_array': FieldValue.arrayUnion([8]),
            'not_array': FieldValue.arrayRemove([5]),
            'merged_not_existing': FieldValue.arrayRemove([9]),
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
            'no_merge_not_existing': [],
          });
        } else {
          // ignore: avoid_print
          print('supportsFieldValueArray false');
        }
      });
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
          isNot(ref2.hashCode),
        ); // This could be wrong though but at least ensure it could be true also!
      });
      test('attributes', () {
        var testsRef = getTestsRef();
        var docRef = testsRef.doc('document_test_attributes');
        expect(docRef.id, 'document_test_attributes');
        expect(docRef.path, '${testsRef.path}/document_test_attributes');
        expect(docRef.parent, const TypeMatcher<CollectionReference>());
        expect(docRef.parent.id, testsRef.id);
      });

      test('root', () {
        var rootColl = firestore.collection('some_root_collection');
        expect(rootColl.parent, isNull);
      });
      test('set subfield', () async {
        var testsRef = getTestsRef();
        var docRef = testsRef.doc('document_set_sub_field');
        await docRef.set({'sub.field': 1});
        expect((await docRef.get()).data, {'sub.field': 1});
      }); //skip: 'Not working with sembast yet');

      test('update sub.field', () async {
        var testsRef = getTestsRef();
        var docRef = testsRef.doc('update');
        await docRef.set({'created': 1, 'modified': 2});
        await docRef.update({'modified': 22, 'added': 3, 'sub.field': 4});
        expect((await docRef.get()).data, {
          'created': 1,
          'modified': 22,
          'added': 3,
          'sub': {'field': 4},
        });
      });

      test('update nested subfield', () async {
        var testsRef = getTestsRef();
        var docRef = testsRef.doc('update_nested_sub_field');
        await docRef.set({
          'a': {
            'b': {'c': 1},
          },
        });
        await docRef.update({
          'a.added': 2,
          'a.b.added': 3,
          'a.b.c.replaced': 4,
          'x': {'sub.replace': 5},
        });
        expect((await docRef.get()).data, {
          'a': {
            'added': 2,
            'b': {
              'added': 3,
              'c': {'replaced': 4},
            },
          },
          'x': {'sub.replace': 5},
        });
      });

      test('merge sub.field on null', () async {
        var testsRef = getTestsRef();
        var docRef = testsRef.doc('merge_sub_field_on_null');
        await docRef.delete();
        await docRef.set({'sub.field': 1}, SetOptions()..merge = true);
        expect((await docRef.get()).data, {'sub.field': 1});
      });

      // This only fails on node
      test('update invalid sub map', () async {
        var testsRef = getTestsRef();
        var docRef = testsRef.doc('update');
        await docRef.set({'created': 1, 'modified': 2});
        // Here we have a sub map, not support by update!
        await docRef.update({
          'modified': 22,
          'added': 3,
          'sub': {'field': 4},
        });
        expect((await docRef.get()).data, {
          'created': 1,
          'modified': 22,
          'added': 3,
          'sub': {'field': 4},
        });
      });

      test('simpleOnSnapshot', () async {
        var testsRef = getTestsRef();
        var docRef = testsRef.doc('simple_onSnapshot');
        await docRef.set({'test': 1});
        if (firestoreService.supportsTrackChanges) {
          expect((await docRef.onSnapshot().first).data, {'test': 1});
        }
      });

      test('onSnapshot', () async {
        var testsRef = getTestsRef();
        var docRef = testsRef.doc('onSnapshot');

        // delete it
        await docRef.delete();

        if (firestoreService.supportsTrackChanges) {
          var stepCount = 4;
          var completers = List.generate(
            stepCount,
            (_) => Completer<DocumentSnapshot>(),
          );
          var count = 0;
          var subscription = docRef.onSnapshot().listen((
            DocumentSnapshot documentSnapshot,
          ) {
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
        var testsRef = getTestsRef();
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
          isNot(ref2.hashCode),
        ); // This could be wrong though but at least ensure it could be true also!
      });
      test('bad path', () async {
        var testsRef = getTestsRef();
        try {
          testsRef.doc('path').collection('bad/path');
          fail('should fail');
          // Document references must have an even number of segments,
        } catch (e) {
          expect(e, isNot(const TypeMatcher<TestFailure>()));
        }
      });

      test('attributes', () {
        var testsRef = getTestsRef();
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
        var testsRef = getTestsRef();
        var collRef = testsRef.doc('collection_test').collection('empty');
        final querySnapshot = await collRef.get();
        var list = querySnapshot.docs;
        expect(list, isEmpty);
        expect(await collRef.count(), 0);
      });

      test('snapshotMetadata', () async {
        var testsRef = getTestsRef();
        var collRef = testsRef.doc('collection_test').collection('metadata');
        final querySnapshot = await collRef.get();
        var list = querySnapshot.docs;
        expect(list, isEmpty);
        expect(await collRef.count(), 0);
      });

      test('single', () async {
        var testsRef = getTestsRef();
        var collRef = testsRef.doc('collection_test').collection('single');
        var docRef = collRef.doc('one');
        await docRef.set({});
        final querySnapshot = await collRef.get();
        var list = querySnapshot.docs;
        expect(list.length, 1);
        expect(list.first.ref.id, 'one');
        expect(await collRef.count(), 1);
      });
    });
    group('WriteBatch', () {
      test('create_delete', () async {
        var testsRef = getTestsRef();
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

        Future<void> check() async {
          expect((await deleteRef.get()).exists, isFalse);
          expect((await createRef.get()).exists, isTrue);
        }

        await runTestAndIfNeededAllowDelay(testContext, () async {
          await check();
        });
      });

      group('all', () {
        test('batch', () async {
          var collRef = getTestsRef().doc('batch_test').collection('all');
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
            'other': {'value': 2},
          });
          expect((await doc3Ref.get()).data, {'value': 3});
          expect((await doc4Ref.get()).exists, isFalse);
          expect((await doc5Ref.get()).data, {'value': 5, 'other': 5});
          expect((await doc6Ref.get()).data, {'other': 6});
        });
      });

      group('Transaction', () {
        test('concurrent_get_update', () async {
          var testsRef = getTestsRef();
          var collRef = testsRef
              .doc('transaction_test')
              .collection('get_update');
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
          var testsRef = getTestsRef();
          var collRef = testsRef
              .doc('transaction_test')
              .collection('get_update');
          var ref = collRef.doc('item');
          await ref.set({'value': 1});

          await firestore.runTransaction((txn) async {
            var snapshot = (await txn.get(ref));

            var data = snapshot.data;
            if (testsRef is FirestorePathReference) {
              expect(
                (snapshot.ref as FirestorePathReference).firestore,
                (testsRef as FirestorePathReference).firestore,
              );
            }

            var map = <String, Object?>{};
            map['value'] = (data['value'] as int) + 1;
            txn.update(ref, map);
          });

          Future<void> check() async {
            expect((await ref.get()).data, {'value': 2});
          }

          try {
            await check();
          } catch (_) {
            if (testContext?.allowedDelayInReadMs != null) {
              await testContext?.sleepReadDelay();
              await check();
            } else {
              rethrow;
            }
          }
        });

        test('get_set', () async {
          var testsRef = getTestsRef();
          var collRef = testsRef.doc('transaction_test').collection('get_set');
          var ref = collRef.doc('item');
          await ref.set({'value': 1});

          await firestore.runTransaction((txn) async {
            var data = (await txn.get(ref)).data;
            expect(data, {'value': 1});
            data['value'] = (data['value'] as int) + 1;

            txn.set(ref, data);
          });

          Future<void> check() async {
            expect((await ref.get()).data, {'value': 2});
          }

          try {
            await check();
          } catch (_) {
            if (testContext?.allowedDelayInReadMs != null) {
              await testContext?.sleepReadDelay();
              await check();
            } else {
              rethrow;
            }
          }
        });

        // make sure that after the transaction we're still fine
        test('post_transaction_set', () async {
          var testsRef = getTestsRef();
          var collRef = testsRef
              .doc('transaction_test')
              .collection('get_update');
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

@Deprecated('use TestContext')
/// Test root path to override
String? testRootPath;

@Deprecated('use TestContext')
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
  FirestoreService service,
  Timestamp timestamp,
) {
  if (service.supportsTimestamps) {
    return timestamp;
  } else {
    return Timestamp(
      timestamp.seconds,
      (timestamp.nanoseconds ~/ 1000000) * 1000000,
    );
  }
}

List<String> querySnapshotDocIds(QuerySnapshot querySnapshot) {
  return querySnapshot.docs.map((snapshot) => snapshot.ref.id).toList();
}
