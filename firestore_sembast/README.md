# tekartik_firebase_firestore_sembast

Local Firestore on [sembast](https://pub.dev/packages/sembast): the
[tekartik_firebase_firestore](../firestore/README.md) API (documents,
queries, listeners, transactions, batches) without any server. In memory for
unit tests, a `firestore.db` file on the Dart VM and Flutter native, IndexedDB
in the browser.

## Getting started

Git packages, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_firestore_sembast:
    git:
      url: https://github.com/tekartik/firebase_firestore.dart
      path: firestore_sembast
  # For FirebaseLocal / newFirebaseAppMemory when you build the app yourself.
  tekartik_firebase_local:
    git:
      url: https://github.com/tekartik/firebase.dart
      path: firebase_local
```

```dart
// Re-exports package:tekartik_firebase_firestore/firestore.dart.
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';

Future<void> main() async {
  // A new empty in memory database, on its own local app.
  var firestore = newFirestoreMemory();

  var users = firestore.collection('users');
  await users.doc('alice').set({'name': 'Alice', 'age': 30});
  await users.add({'name': 'Bob', 'age': 25});

  var snapshot = await users.where('age', isGreaterThan: 26).get();
  print(snapshot.docs.map((doc) => doc.data['name'])); // (Alice)

  await firestore.app.delete();
}
```

## Platforms

| Import | Service | Storage | Runs on |
|---|---|---|---|
| `firestore_sembast.dart` | `newFirestoreMemory()`, `newFirestoreServiceMemory()`, `firestoreServiceMemory` | memory | everywhere |
| `firestore_sembast.dart` | `newFirestoreServiceSembast(databaseFactory: ...)` | any sembast factory (io, web, sqflite) | where the factory runs |
| `firestore_sembast_io.dart` | `firestoreServiceIo` | `<app.localPath>/firestore.db` | Dart VM, Flutter native |
| `firestore_sembast_web.dart` | `firestoreServiceWeb` | IndexedDB | browser |

A service gives one `Firestore` per app: `service.firestore(app)`, where the
app is a local one (`FirebaseLocal().initializeApp()`,
`newFirebaseAppLocal()`, `newFirebaseAppMemory()` from
`tekartik_firebase_local`).

## When to use what

* Unit tests: `newFirestoreMemory()` in `setUp`, a fresh database each time.
  `newFirestoreServiceMemory()` gives a service of its own (apps of that
  service share it); `firestoreServiceMemory` is shared by the whole process.
* Local tools and desktop apps: `firestoreServiceIo` on a
  `FirebaseLocal(localPath: ...)` app.
* An existing sembast factory (sqflite in a Flutter app, sembast_web):
  `newFirestoreServiceSembast(databaseFactory: ...)`.
* Export: `package:tekartik_firebase_firestore_sembast/utils/export_utils.dart`
  adds `firestore.exportLines()` (sembast export format), also on another
  backend that can list its collections (the documents are copied in memory
  first).
* New app code storing its own local data: prefer sdb (idb_shim) and
  `tekartik_firebase_firestore_idb`'s sdb variant over this sembast layer.

## Pitfalls

* Security rules are not enforced, every read and write succeeds.
* Concurrent transactions are not retried as on a server: the shared test
  suite needs `skipConcurrentTransactionTests = true`.
* `exportLines(collections: ..., documents: ...)` on a sembast firestore
  exports the whole database (the filters only apply on other backends).
* The sembast database stays open until the process ends (`app.delete()`
  does not close it).
* In debug runs (`dart test`, Flutter debug) opening the database prints an
  `opening database ...` line.
* `package:sembast/sembast.dart` also defines `Transaction` and `FieldValue`:
  import it with a prefix next to this package.

## Agent skills

`skills/tekartik-firebase-firestore-sembast-local-firestore` (API, test
setup, more examples).
