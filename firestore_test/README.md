# tekartik_firebase_firestore_test

The shared tests every `tekartik_firebase_firestore` implementation runs
(sembast, idb, sdb, sim, rest, grpc, node, admin sdk, flutter): documents,
queries, cursors, transactions, batches, snapshot listeners, timestamps,
blobs, vector values, aggregates, `listCollections`/`listDocuments` and the
`utils/` helpers, plus a console dev menu. Pure Dart on `package:test`: it
runs wherever the implementation under test runs (VM, browser, node).

## Getting started

Git package, not on pub.dev, used as a dev dependency of the implementation
it tests:

```yaml
dev_dependencies:
  tekartik_firebase_firestore_test:
    git:
      url: https://github.com/tekartik/firebase_firestore.dart
      path: firestore_test
  test: '>=1.31.0'
```

The whole suite on the sembast implementation, in memory
(`test/firestore_sembast_test.dart`):

```dart
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test_runner.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

void main() {
  // Set before declaring the tests: a local implementation does not run
  // the update function of a transaction again on contention.
  skipConcurrentTransactionTests = true;
  runFirestoreTests(
    firebase: FirebaseLocal(),
    firestoreService: newFirestoreServiceMemory(),
  );
}
```

Run it with `dart test` (`dart test -p chrome` for a web implementation).

## Entry points

* `runFirestoreTests(firebase:, firestoreService:, options:, testContext:)`
  creates an app named `firestore_tests`, declares every test on its
  firestore and deletes the app at the end (`tearDownAll`).
* `runFirestoreAppTests(app:, firestoreService:, testContext:)` does the same
  on an app you own (a sim client, an authenticated app): delete it yourself.
* One runner per feature (`runFirestoreQueryTests`,
  `runListCollectionsTest`, `runAggregateQueryTest`, `firestoreMulticlientTest`
  for two clients of one database...), each in its own library, for a
  partial implementation.

What runs follows the service flags (`supportsTrackChanges`,
`supportsAggregateQueries`, `supportsListCollections`, `supportsBlobs`...):
an unsupported feature is skipped, set the flags right on the implementation
rather than skipping tests.

## What to know

* Set the global flags before calling a runner, they are read when the tests
  are declared: `skipConcurrentTransactionTests` (sembast, idb, sdb, sim and
  rest set it: forgetting it on sembast hangs `concurrent_get_update` for 30 s
  then fails every later transaction test), `skipFirestoreTransactionTests`,
  `skipFirestoreListCollectionsTests`, `skipFirestoreListMissingDocumentsTests`.
* The suite writes and deletes documents under
  `FirestoreTestContext.rootCollectionPath` (default
  `tests/tekartik_firestore/tests`), plus a few root collections
  (`tekartik_test_root_collection...`) for `listCollections`. Point it at an
  emulator, a local implementation or a test project, never at production
  data, and give each CI target its own root path on a shared project.
* A real backend may need `FirestoreTestContext()..allowedDelayInReadMs = 3000`:
  a failing read is tried again once after that delay (rest).
* Against a real project, `documentTime` compares the server update time
  with the local clock: a local clock ahead of the server fails it.
* The collection group test is always skipped (no local implementation
  supports `collectionGroup`).

## Dev menu

`firestoreMainMenu` (`menu/firestore_client_menu.dart`) is a
[`tekartik_app_dev_menu`](https://github.com/tekartik/app_common_utils.dart)
console menu to add, list and listen to documents under a document of a live
firestore:

```dart
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_firestore_test/menu/firestore_client_menu.dart';

Future<void> main(List<String> args) async {
  var firestore = newFirestoreMemory();
  await mainMenu(args, () {
    firestoreMainMenu(
      context: FirestoreMainMenuContext(doc: firestore.doc('test/menu')),
    );
  });
}
```

More in the
[package skill](skills/tekartik-firebase-firestore-test-suite/SKILL.md).
