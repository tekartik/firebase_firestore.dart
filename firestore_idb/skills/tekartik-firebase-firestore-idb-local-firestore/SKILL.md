---
name: tekartik-firebase-firestore-idb-local-firestore
description: >-
  Use when a Dart or Flutter app or test needs a local Firestore without a
  server through tekartik_firebase_firestore_idb: a FirestoreService built
  from an idb_shim IdbFactory (in-memory, IndexedDB in the browser, sembast
  io) or an SdbFactory (firestore_sdb.dart, tekartik_app_flutter_idb
  getSdbFactory), bound to FirebaseLocal apps from tekartik_firebase_local.
---

# tekartik_firebase_firestore_idb local Firestore

Local implementation of the `tekartik_firebase_firestore` abstraction that
stores documents in an `idb_shim` database: in memory for unit tests,
IndexedDB in the browser, sqflite/sembast through the sdb API in Flutter
apps. Same `Firestore`/`Query`/`DocumentReference` API as the native, REST
and node backends, so app code does not change.

## Guidelines

* Three entry points:
  * `package:tekartik_firebase_firestore_idb/firestore_idb.dart`: extension
    `TekartikFirebaseFirestoreIdbFactoryExt` on `IdbFactory`, use
    `idbFactory.firestoreService`.
  * `package:tekartik_firebase_firestore_idb/firestore_idb_browser.dart`:
    `firestoreServiceIdbBrowser`, IndexedDB through `idbFactoryNative`.
  * `package:tekartik_firebase_firestore_idb/firestore_sdb.dart`: extension
    `TekartikFirebaseFirestoreSdbFactoryExt` on `SdbFactory`, use
    `sdbFactory.firestoreService`, plus `firestoreServiceSdbWeb` (browser).
* Only `firestore_sdb.dart` re-exports
  `package:tekartik_firebase_firestore/firestore.dart`; with the idb entry
  points import it yourself for `Firestore`, `DocumentSnapshot`, ...
* Prefer the sdb variant for new code: it is the one Flutter apps use through
  `getSdbFactory()` from `package:tekartik_app_flutter_idb/sdb.dart` and the
  only one with `supportsTrackChanges` true (query `onSnapshot` reports
  document changes). Keep the idb variant when you already hold a raw
  `IdbFactory`.
* Apps must be `FirebaseAppLocal` (alias `AppLocal`) from
  `package:tekartik_firebase_local/firebase_local.dart`:
  `FirebaseLocal(localPath: ...).initializeApp(name: ...)` or
  `newFirebaseAppMemory()` in tests. `firestoreService.firestore(app)` asserts
  the app type; a native or REST app is not accepted.
* Storage derives from `app.localPath` (`<firebase localPath>/<projectId>`,
  defaults `.dart_tool/tekartik_firebase_local` and `local`): the idb variant
  opens a database with that name holding one `documents` object store keyed
  by document path; the sdb variant opens `<localPath>/firestore/firestore.sdb`.
  Apps sharing `localPath` and `projectId` share data; `newFirebaseAppMemory()`
  returns a unique path per call, so tests stay isolated even with the shared
  `sdbFactoryMemory` or `idbFactoryMemory`.
* `firestore(app)` caches one `Firestore` per app and registers it as a
  product: `app.firestore()` (extension `TekartikFirestoreFirebaseAppExt`)
  and `Firestore.instance` (default app) return that instance afterwards.
* Capabilities (check the `FirestoreService` flags, do not hardcode):
  `supportsQuerySelect`, `supportsQuerySnapshotCursor`,
  `supportsFieldValueArray`, `supportsTimestamps`,
  `supportsTimestampsInSnapshots`, `supportsDocumentSnapshotTime`,
  `supportsVectorValue`, `supportsBlobs` and `Firestore.supportsTransaction`
  are true. `supportsListCollections` and `supportsAggregateQueries` are
  false: `listCollections()` throws `UnimplementedError`.
* Security rules are never enforced: every read and write succeeds. Test
  permission denied paths against the Firestore emulator (REST or node
  backend), not here.
* `runTransaction` and `WriteBatch.commit` run inside a single idb/sdb
  read-write transaction. Concurrent transactions are not retried like on
  the server (the test suite sets `skipConcurrentTransactionTests = true`);
  do not rely on contention semantics.
* Do not use the deprecated `getFirestoreService(idbFactory)` nor the
  deprecated `firestoreService` getter of `firestore_idb_browser.dart`.
* Factories: `idbFactoryMemory` and `newIdbFactoryMemory()` from
  `package:idb_shim/idb_client_memory.dart`; `sdbFactoryMemory`,
  `newSdbFactoryMemory()` and `sdbFactoryFromIdb(idbFactory)` from
  `package:idb_shim/sdb.dart`; `getIdbFactorySembastIo(path)` from
  `package:idb_shim/idb_io.dart` for persistent files on the VM.
* When touching the implementation, run the shared compliance suite:
  `runFirestoreTests(firebase:, firestoreService:)` from
  `package:tekartik_firebase_firestore_test/firestore_test.dart`.
* Sibling `tekartik_firebase_firestore_sembast`
  (`package:tekartik_firebase_firestore_sembast/firestore_sembast.dart`:
  `firestoreServiceMemory`, `newFirestoreServiceMemory()`,
  `newFirestoreMemory()`, `newFirestoreServiceSembast(databaseFactory:)`) is
  the same idea on sembast and the quickest choice for pure Dart unit tests.
  Pick idb when the app already stores its data with idb_shim/sdb.
* Dependency (not on pub.dev): git url
  `https://github.com/tekartik/firebase_firestore.dart`, path `firestore_idb`.

## Examples

### In-memory Firestore for a unit test (sdb)

```dart
import 'package:idb_shim/sdb.dart';
import 'package:tekartik_firebase_firestore_idb/firestore_sdb.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  late FirebaseAppLocal app;
  late Firestore firestore;

  setUp(() {
    app = newFirebaseAppMemory();
    firestore = sdbFactoryMemory.firestoreService.firestore(app);
  });
  tearDown(() => app.delete());

  test('set, query, listen', () async {
    var users = firestore.collection('users');
    await users.doc('alice').set({'name': 'Alice', 'age': 30});
    await users.add({'name': 'Bob', 'age': 25});

    var snapshot = await users.where('age', isGreaterThan: 26).get();
    expect(snapshot.docs.map((doc) => doc.data['name']), ['Alice']);

    var first = await users.doc('alice').onSnapshot().first;
    expect(first.exists, isTrue);
    expect(first.updateTime, isNotNull);
  });
}
```

### Flutter app: local Firestore on every platform

```dart
import 'package:tekartik_app_flutter_idb/sdb.dart';
import 'package:tekartik_firebase_firestore_idb/firestore_sdb.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

late Firestore firestore;

void initLocalFirestore() {
  // sqflite on mobile/desktop, IndexedDB on the web.
  var sdbFactory = getSdbFactory(packageName: 'com.example.notes');
  var firebase = FirebaseLocal(localPath: 'notes');
  var app = firebase.initializeApp(options: AppOptions(projectId: 'notes'));
  firestore = sdbFactory.firestoreService.firestore(app);
  // Later, anywhere: app.firestore() or Firestore.instance.
}
```

### Browser app with IndexedDB (idb variant) and a transaction

```dart
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_idb/firestore_idb_browser.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

Future<void> incrementCounter() async {
  var app = FirebaseLocal(localPath: 'counter_app').initializeApp();
  var firestore = firestoreServiceIdbBrowser.firestore(app);
  var ref = firestore.doc('stats/visits');
  await firestore.runTransaction((txn) async {
    var snapshot = await txn.get(ref);
    var count = snapshot.exists ? (snapshot.data['count'] as int) : 0;
    txn.set(ref, {'count': count + 1, 'at': FieldValue.serverTimestamp});
  });
}
```

### Compliance suite against a persistent VM factory

```dart
import 'package:idb_shim/idb_io.dart';
import 'package:path/path.dart';
import 'package:tekartik_firebase_firestore_idb/firestore_idb.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  var idbFactory = getIdbFactorySembastIo(join('.dart_tool', 'my_app', 'test'));
  skipConcurrentTransactionTests = true;
  group('io', () {
    runFirestoreTests(
      firebase: FirebaseLocal(),
      firestoreService: idbFactory.firestoreService,
    );
  });
}
```
