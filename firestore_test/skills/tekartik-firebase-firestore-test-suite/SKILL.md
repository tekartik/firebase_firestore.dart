---
name: tekartik-firebase-firestore-test-suite
description: >-
  Use when validating a tekartik_firebase_firestore implementation (sembast,
  idb, rest, grpc, node, sim, a logger or a custom backend) against the shared
  compliance suite of tekartik_firebase_firestore_test: runFirestoreTests,
  runFirestoreAppTests, runFirestoreCommonTests, FirestoreTestContext,
  skipConcurrentTransactionTests, skipFirestoreTransactionTests,
  skipFirestoreListCollectionsTests, the per-feature runners
  (runFirestoreQueryTests, runFirestoreDocumentTests, runListCollectionsTest,
  runAggregateQueryTest, firestoreMulticlientTest, ...) and the interactive
  firestoreMainMenu dev menu.
---

# Shared Firestore compliance suite (tekartik_firebase_firestore_test)

Backend-agnostic `package:test` suite that every implementation of the
`tekartik_firebase_firestore` API is expected to pass: documents, queries,
cursors, transactions, batches, snapshot streams, timestamps, blobs, vector
values, collection groups and the `utils/` helpers. Every test is defined as a
function you call from your own test file, so each implementation keeps its own
`test/` directory and its own setup.

## Guidelines

* Dependency (not on pub.dev, git only), always a **dev** dependency:
  ```yaml
  dev_dependencies:
    tekartik_firebase_firestore_test:
      git:
        url: https://github.com/tekartik/firebase_firestore.dart
        path: firestore_test
      version: '>=0.8.0'
  ```
  It pulls `tekartik_firebase`, `tekartik_firebase_firestore` and `dev_test`
  (the `package:test` wrapper it uses), so a test file needs no other import
  than the entry point plus your implementation.
* One call covers everything:
  `runFirestoreTests({required Firebase firebase, required FirestoreService
  firestoreService, AppOptions? options, FirestoreTestContext? testContext})`
  from `package:tekartik_firebase_firestore_test/firestore_test_runner.dart`. It
  initializes an app named `firestore_tests` on `firebase`, binds
  `firestoreService.firestore(app)` and declares every group. Call it at the
  top level of `main()`, not inside `setUp`.
* When the app already exists (a simulator client, an authenticated app, a
  shared connection), use
  `runFirestoreAppTests({required FirebaseApp app, required FirestoreService
  firestoreService, AppOptions? options, required FirestoreTestContext
  testContext})` instead and delete the app yourself in `tearDownAll`.
  `runFirestoreCommonTests({firestoreService:, firestore:, testContext:})`
  takes an already built `Firestore` and runs only the core group.
  `run(...)` and the top-level `testsRefPath` variable are deprecated.
* The suite reads the capability flags of the service
  (`supportsQuerySelect`, `supportsTimestamps`, `supportsListCollections`,
  `supportsAggregateQueries`, `supportsFieldValueArray`, `supportsBlobs`,
  `supportsVectorValue`, `supportsTrackChanges`,
  `supportsRecordTrackChanges`, `Firestore.supportsTransaction`, ...) and
  skips what is unsupported. Report the flags honestly in the implementation
  rather than skipping tests here.
* Three global flags, set **before** calling a runner:
  * `skipConcurrentTransactionTests = true`: local backends that do not retry
    transactions under contention (sembast, idb, sim).
  * `skipFirestoreTransactionTests = true`: no transaction support at all.
  * `skipFirestoreListCollectionsTests = true`: `listCollections()` present but
    not usable in this environment (for instance rules-restricted).
* `FirestoreTestContext` tunes the suite for a real, shared backend:
  * `FirestoreTestContext(rootCollectionPath: 'tests/my_app/tests')` moves every
    document under that path (default:
    `FirestoreTestContext.defaultRootCollectionPath`, i.e.
    `tests/tekartik_firestore/tests`). Give each CI target its own path so
    parallel runs do not collide; the suite writes and deletes documents there.
  * `..allowedDelayInReadMs = 3000` retries a failing read once after that
    delay, for eventually consistent backends (REST, gRPC).
  * `noAuthRootCollectionPath:` is accepted for suites exercising unauthorized
    paths; `FirestoreTestContext.getRootCollectionPath(testContext)` resolves a
    nullable context to a path.
* The suite is not sandboxed: point it at an emulator, a local implementation
  or a throw-away project, never at production data.
* Per-feature runners, each in its own library, when only part of the API is
  implemented or when a group must be isolated (all take named arguments,
  `testContext` nullable except where noted):
  * `query_test_runner.dart`: `runFirestoreQueryTests(firestore:, testContext:)`
    (non-null context).
  * `firestore_document_test_runner.dart`: `runFirestoreDocumentTests(firestore:,
    testContext:)`.
  * `firestore_collection_group_test_runner.dart`:
    `runFirestoreCollectionGroupTests(firestore:, testContext:)`.
  * `list_collections_test_runner.dart`: `runListCollectionsTest(firestore:,
    testContext:)`.
  * `aggregate_query_test_runner.dart`: `runAggregateQueryTest(firestore:,
    testContext:)`.
  * `copy_utils_test_runner.dart`: `runCopyUtilsTest(firestore:, testContext:)`.
  * `utils_collection_test_runner.dart`: `runUtilsCollectionTests(firestoreService:,
    firestore:, testContext:)`.
  * `utils_query_test_runner.dart`: `runUtilsQueryTest(firestoreService:, firestore:,
    testContext:)`.
  * `utils_test_runner.dart`: `utilsTest(firestoreService:, firestore:,
    testContext:)`.
  * `utils_auto_id_test_runner.dart`: `utilsAutoIdTest(firestore:, testContext:)`.
  * `timestamp_test_runner.dart`: `timestampGroup(service:, firestore:,
    testContext:)`.
  * `vector_value_test_runner.dart`: `vectorValueGroup(firestore:, testContext:)`.
  * `firestore_track_changes_test_runner.dart`:
    `runFirestoreTrackChangesTests(firestoreService:, firestore:,
    testContext:)`.
  * `firestore_track_changes_support_test_runner.dart`:
    `runFirestoreTrackChangesSupportTests(firestoreService:, firestore:,
    testContext:)`.
  * `firestore_multi_client_test_runner.dart`: `firestoreMulticlientTest(firestore1:,
    firestore2:, docTopPath:)` plus the `dataMatch(data1, data2)` helper, for
    two clients over one database.
* `docsKeys(List<DocumentSnapshot>)` returns the matching
  `List<DocumentReference?>`, handy in your own expectations.
* `package:tekartik_firebase_firestore_test/menu/firestore_client_menu.dart` is
  not a test: it builds an interactive console/browser dev menu
  (`firestoreMainMenu(context: FirestoreMainMenuContext(doc: someDoc))` inside
  `mainMenu(args, ...)`) to poke a live implementation by hand. It re-exports
  `package:tekartik_app_dev_menu/dev_menu.dart` and
  `package:tekartik_firebase_firestore/firestore.dart`.
* Place the calls in `test/<impl>_test.dart` of the implementation package and
  annotate the platform (`@TestOn('vm')` for io, `@TestOn('browser')` for web).
  Run with `dart test` (add `-p chrome` for browser targets).

## Examples

### Full suite against a local implementation

```dart
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test_runner.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

void main() {
  // Local backends do not retry concurrent transactions.
  skipConcurrentTransactionTests = true;

  runFirestoreTests(
    firebase: FirebaseLocal(),
    firestoreService: newFirestoreServiceMemory(),
  );
}
```

### Remote backend: own root path and read delay

```dart
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test_runner.dart';

/// [firebase] and [firestoreService] come from the implementation under test
/// (rest, grpc, node, ...), pointing at an emulator or a throw-away project.
void defineTests(Firebase firebase, FirestoreService firestoreService) {
  runFirestoreTests(
    firebase: firebase,
    firestoreService: firestoreService,
    options: AppOptions(projectId: 'my-test-project'),
    testContext: FirestoreTestContext(
      rootCollectionPath: 'tests/my_app/ci_linux',
    )..allowedDelayInReadMs = 3000,
  );
}
```

### Existing app, plus only the groups that make sense

```dart
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test_runner.dart';
import 'package:tekartik_firebase_firestore_test/list_collections_test_runner.dart';
import 'package:tekartik_firebase_firestore_test/query_test_runner.dart';
import 'package:test/test.dart';

void defineTests(FirebaseApp app, FirestoreService firestoreService) {
  var testContext = FirestoreTestContext();
  // Everything, on an app the caller already connected.
  runFirestoreAppTests(
    app: app,
    firestoreService: firestoreService,
    testContext: testContext,
  );

  // Or, for a partial implementation, only some groups.
  var firestore = firestoreService.firestore(app);
  runFirestoreQueryTests(firestore: firestore, testContext: testContext);
  if (firestoreService.supportsListCollections) {
    runListCollectionsTest(firestore: firestore, testContext: testContext);
  }

  tearDownAll(() => app.delete());
}
```

### Two clients on one database

```dart
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_test/firestore_multi_client_test_runner.dart';

/// [firestore1] and [firestore2] must be two clients of the same database.
void defineTests(Firestore firestore1, Firestore firestore2) {
  firestoreMulticlientTest(
    firestore1: firestore1,
    firestore2: firestore2,
    docTopPath: 'tests/my_app/multi_client',
  );
}
```

### Interactive dev menu against a live Firestore

```dart
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_firestore_test/menu/firestore_client_menu.dart';

Future<void> main(List<String> args) async {
  var firestore = newFirestoreMemory();
  await mainMenu(args, () {
    firestoreMainMenu(
      context: FirestoreMainMenuContext(doc: firestore.doc('test/1')),
    );
  });
}
```

## Common mistakes

* Adding the package to `dependencies` instead of `dev_dependencies`.
* Setting `skipConcurrentTransactionTests` after calling `runFirestoreTests`:
  the flags are read while the groups are declared.
* Calling a runner inside `setUp`/`test`: they declare groups, they do not run
  assertions.
* Running two CI targets on the same `rootCollectionPath` of a shared backend.
* Skipping a failing group instead of fixing the `supportsXxx` flag of the
  implementation.
