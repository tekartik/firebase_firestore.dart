---
name: tekartik-firebase-firestore-sembast-local-firestore
description: >-
  Use when a Dart or Flutter app or test needs a local, serverless Firestore
  backed by sembast through tekartik_firebase_firestore_sembast:
  firestoreServiceMemory, newFirestoreServiceMemory(), newFirestoreMemory(),
  newFirestoreServiceSembast(databaseFactory:), FirestoreServiceSembast,
  firestoreServiceIo (firestore_sembast_io.dart), firestoreServiceWeb
  (firestore_sembast_web.dart), the sembastDatabase / sembastSupportsTrackChanges
  extensions, exportLines from utils/export_utils.dart, and FirebaseLocal /
  newFirebaseAppMemory apps.
---

# Local Firestore on sembast (tekartik_firebase_firestore_sembast)

Implements the `tekartik_firebase_firestore` abstraction on top of a sembast
database: in memory for unit tests, a single `firestore.db` file on the VM and
Flutter desktop/mobile, IndexedDB in the browser. Same `Firestore` / `Query` /
`DocumentReference` API as the native, REST and node backends, so application
code is unchanged. This is the quickest local Firestore for pure Dart tests.

## Guidelines

* Dependency (not on pub.dev, git only):
  ```yaml
  dependencies:
    tekartik_firebase_firestore_sembast:
      git:
        url: https://github.com/tekartik/firebase_firestore.dart
        path: firestore_sembast
      version: '>=0.8.0'
  ```
  `tekartik_firebase_firestore` and `tekartik_firebase_local` come with it;
  declare them explicitly (same style, `path: firestore` and, from
  `https://github.com/tekartik/firebase.dart`, `path: firebase_local`) when
  shared code imports them directly.
* Three entry points, each re-exporting
  `package:tekartik_firebase_firestore/firestore.dart` so `Firestore`,
  `DocumentSnapshot`, `FieldValue`, ... need no second import:
  * `package:tekartik_firebase_firestore_sembast/firestore_sembast.dart`:
    `firestoreServiceMemory`, `newFirestoreServiceMemory()`,
    `newFirestoreMemory()`, `newFirestoreServiceSembast(databaseFactory:)`,
    the `FirestoreServiceSembast` class and the `TekartikFirestoreSembastExt` /
    `TekartikFirestoreServiceSembastExt` extensions. Safe on every platform.
  * `package:tekartik_firebase_firestore_sembast/firestore_sembast_io.dart`:
    adds `firestoreServiceIo` (sembast io, VM/Flutter native only).
  * `package:tekartik_firebase_firestore_sembast/firestore_sembast_web.dart`:
    adds `firestoreServiceWeb` (sembast_web/IndexedDB, browser only).
* Pick the service, then bind it to an app: `service.firestore(app)`. The app
  must be a `FirebaseAppLocal` (alias `AppLocal`) from
  `package:tekartik_firebase_local/firebase_local.dart`; a native or REST app
  is rejected. Build it with `FirebaseLocal(localPath: ...).initializeApp()`,
  `newFirebaseAppLocal(...)` or `newFirebaseAppMemory()`.
* `firestore(app)` caches one `Firestore` per app, so calling it again returns
  the same instance, and registers it as a firebase product (`app.firestore()`
  and `Firestore.instance` then resolve to it).
* Isolation in tests, from most to least shared:
  * `firestoreServiceMemory` is a singleton over sembast's shared memory
    factory: two apps with the same `localPath` and `projectId` see the same
    data. Fine for a quick script, risky for a suite.
  * `newFirestoreServiceMemory()` builds a service over its own
    `newDatabaseFactoryMemory()`: nothing is shared with another service.
  * `newFirestoreMemory()` is the one-liner `newFirestoreServiceMemory()
    .firestore(newFirebaseAppMemory())`: a brand new empty database every call.
    Prefer it in `setUp`.
* Storage path: `<app.localPath>/firestore.db`, where `app.localPath` is
  `<FirebaseLocal.localPath>/<projectId>` (defaults:
  `.dart_tool/tekartik_firebase_local` and `local`). Give each test target its
  own `localPath` to avoid two suites fighting over one file.
  `newFirebaseAppMemory()` allocates a unique path per call.
* `newFirestoreServiceSembast(databaseFactory: ...)` accepts any sembast
  `DatabaseFactory` (`databaseFactoryIo`, `databaseFactoryWeb`,
  `databaseFactoryMemory`, `newDatabaseFactoryMemory()`, sqflite's). Use it
  instead of `firestoreServiceIo`/`firestoreServiceWeb` when the factory is
  chosen at runtime or is a Flutter one.
* Capabilities are all true except that transactions are not retried under
  contention: `supportsQuerySelect`, `supportsQuerySnapshotCursor`,
  `supportsFieldValueArray`, `supportsTimestamps`,
  `supportsTimestampsInSnapshots`, `supportsDocumentSnapshotTime`,
  `supportsTrackChanges`, `supportsListCollections`,
  `supportsAggregateQueries`, `supportsVectorValue`, `supportsBlobs`. Read the
  flags from `firestore.service`, do not hardcode them in shared code.
* `service.sembastSupportsTrackChanges = false` (setter of
  `TekartikFirestoreServiceSembastExt`, only valid on a
  `FirestoreServiceSembast`) turns `supportsTrackChanges` off, to exercise the
  polling `onSnapshotSupport` path of
  `package:tekartik_firebase_firestore/utils/track_changes_support.dart`.
* `await firestore.sembastDatabase` (getter of `TekartikFirestoreSembastExt`,
  a `Future<Database>`) opens if needed and returns the raw sembast database,
  for direct store access or a sembast export. It throws a cast error on a
  `Firestore` that is not sembast-backed, so guard with `is` or with
  `firestore.service is FirestoreServiceSembast` when the backend varies.
* `package:tekartik_firebase_firestore_sembast/utils/export_utils.dart` adds
  `firestore.exportLines({collections, documents})`, a list of json-encodable
  lines in the sembast export format (first line
  `{'sembast_export': 1, 'version': 1}`), plus re-exports `exportDatabase`,
  `exportDatabaseLines`, `importDatabase`, `importDatabaseLines` from sembast.
  It also works on a non-sembast `Firestore` that supports
  `listCollections()`: the documents are copied into a temporary memory
  Firestore first.
* Security rules are never enforced: every read and write succeeds. Test
  permission-denied paths against the Firestore emulator (REST or node
  backend), not here.
* Importing `package:sembast/sembast.dart` next to a firestore entry point
  clashes on `Transaction` and `FieldValue`; import it `as sembast` or with
  `hide Transaction, FieldValue`.
* Testing: set `skipConcurrentTransactionTests = true` before
  `runFirestoreTests(firebase:, firestoreService:)` from
  `package:tekartik_firebase_firestore_test/firestore_test.dart`; concurrent
  transactions are not retried like on a real server. Mark io tests
  `@TestOn('vm')` and web tests `@TestOn('browser')`.
* Sibling `tekartik_firebase_firestore_idb` is the same idea on
  `idb_shim`/`sdb`; pick it when the app already stores its data with idb.

## Examples

### In-memory Firestore in a unit test

```dart
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:test/test.dart';

void main() {
  late Firestore firestore;

  // Fresh, isolated database for every test.
  setUp(() => firestore = newFirestoreMemory());
  tearDown(() => firestore.app.delete());

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

  test('transaction', () async {
    var ref = firestore.doc('stats/visits');
    await firestore.runTransaction((transaction) async {
      var snapshot = await transaction.get(ref);
      var count = snapshot.exists ? (snapshot.data['count'] as int) : 0;
      transaction.set(ref, {'count': count + 1});
    });
    expect((await ref.get()).data, {'count': 1});
  });
}
```

### Persistent Firestore on the VM

```dart
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast_io.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

Future<void> main() async {
  // Stored in .local/my_app/my_project/firestore.db
  var firebase = FirebaseLocal(localPath: '.local/my_app');
  var app = firebase.initializeApp(
    options: AppOptions(projectId: 'my_project'),
  );
  var firestore = firestoreServiceIo.firestore(app);

  await firestore.doc('config/app').set({
    'version': 1,
    'updated': FieldValue.serverTimestamp,
  });
  print((await firestore.doc('config/app').get()).data);
  await app.delete();
}
```

### Explicit sembast factory (any platform, including Flutter)

```dart
import 'package:sembast/sembast_io.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

/// [databaseFactory] can also be sembast_web's, sqflite's or a memory one.
Firestore openLocalFirestore({String localPath = '.local/notes'}) {
  var service = newFirestoreServiceSembast(databaseFactory: databaseFactoryIo);
  var app = newFirebaseAppLocal(
    localPath: localPath,
    options: AppOptions(projectId: 'notes'),
  );
  return service.firestore(app);
}
```

### Export the local database and read the raw sembast database

```dart
import 'package:sembast/sembast.dart' as sembast;
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_firestore_sembast/utils/export_utils.dart';

Future<void> main() async {
  var firestore = newFirestoreMemory();
  await firestore.doc('test/doc').set({'test': 1});

  // [{'sembast_export': 1, 'version': 1}, {'store': 'doc'}, [...]]
  var lines = await firestore.exportLines(
    collections: [firestore.collection('test')],
  );
  print(lines);

  // Raw sembast access, opening the database if needed.
  var db = await firestore.sembastDatabase;
  print(await sembast.StoreRef<String, Object?>('doc').count(db));
}
```

### Shared compliance suite, memory and io

```dart
@TestOn('vm')
library;

import 'package:tekartik_firebase_firestore_sembast/firestore_sembast_io.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:test/test.dart';

void main() {
  // Concurrent transactions are not retried locally.
  skipConcurrentTransactionTests = true;

  group('memory', () {
    runFirestoreTests(
      firebase: FirebaseLocal(),
      firestoreService: newFirestoreServiceMemory(),
    );
  });
  group('io', () {
    runFirestoreTests(
      firebase: FirebaseLocal(localPath: '.dart_tool/firestore_sembast_test'),
      firestoreService: firestoreServiceIo,
    );
  });
}
```

## Common mistakes

* Passing a non-local app (native, REST, node) to `firestore(app)`.
* Sharing `firestoreServiceMemory` across tests and being surprised by
  leftover documents: use `newFirestoreMemory()` or
  `newFirestoreServiceMemory()`.
* Accessing `firestoreServiceIo` in web code or `firestoreServiceWeb` on the
  VM instead of splitting on the entry point.
* Treating `firestore.sembastDatabase` as a synchronous getter: it is a
  `Future<Database>`.
* Expecting security rules, contention retries or server-side timestamps
  resolution semantics to match the real Firestore.
