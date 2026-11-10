# tekartik_firebase_firestore_idb

Local Firestore on [idb_shim](https://pub.dev/packages/idb_shim): the
[tekartik_firebase_firestore](../firestore/README.md) API without any server,
stored in an IndexedDB-like database. Two variants: on an sdb factory
(`SdbFactory`, the one to use in new code) and on a raw `IdbFactory`.

## Getting started

Git packages, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_firestore_idb:
    git:
      url: https://github.com/tekartik/firebase_firestore.dart
      path: firestore_idb
  tekartik_firebase_local:
    git:
      url: https://github.com/tekartik/firebase.dart
      path: firebase_local
  idb_shim: any
```

```dart
import 'package:idb_shim/sdb.dart';
// Re-exports package:tekartik_firebase_firestore/firestore.dart.
import 'package:tekartik_firebase_firestore_idb/firestore_sdb.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

Future<void> main() async {
  var app = newFirebaseAppMemory();
  var firestore = newSdbFactoryMemory().firestoreService.firestore(app);

  await firestore.doc('users/alice').set({'name': 'Alice'});
  print((await firestore.doc('users/alice').get()).data); // {name: Alice}

  await app.delete();
}
```

## Platforms

| Import | Service | Runs on |
|---|---|---|
| `firestore_sdb.dart` | `sdbFactory.firestoreService` (`sdbFactoryMemory`, `newSdbFactoryMemory()`, a Flutter `getSdbFactory()`) | everywhere the factory runs |
| `firestore_sdb.dart` | `firestoreServiceSdbWeb` | browser (IndexedDB) |
| `firestore_idb.dart` | `idbFactory.firestoreService` (`idbFactoryMemory`, `getIdbFactorySembastIo(dir)`) | everywhere the factory runs |
| `firestore_idb_browser.dart` | `firestoreServiceIdbBrowser` | browser (IndexedDB) |

The app must be a local one (`tekartik_firebase_local`): the database is
named after `app.localPath`.

## Pitfalls

* In a browser (IndexedDB), a `runTransaction` update function must only
  await its own `txn.get` calls: awaiting anything else (an http call, a
  delay) lets IndexedDB commit the transaction, and the writes fail with a
  `TransactionInactiveError`. On the sdb variant, the call currently never
  completes in that case (idb_shim 2.11.3). The memory and io factories
  accept it.
* No `listCollections`, no aggregate queries, no missing documents listing
  (check the `supports...` flags of the service).
* Security rules are not enforced, concurrent transactions are not retried:
  the shared test suite needs `skipConcurrentTransactionTests = true`.

## Agent skills

`skills/tekartik-firebase-firestore-idb-local-firestore` (API, Flutter setup,
more examples).
