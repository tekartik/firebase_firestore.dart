# firebase_firestore.dart

Platform neutral Firestore API for Dart and Flutter, and its local
implementations. Write the data code once against `tekartik_firebase_firestore`,
run it on Flutter, REST, node, the admin SDK or in memory.

## Packages

| Package | Path | What |
|---|---|---|
| `tekartik_firebase_firestore` | [firestore](firestore) | the API (documents, queries, listeners, transactions, utilities); start here |
| `tekartik_firebase_firestore_sembast` | [firestore_sembast](firestore_sembast) | sembast backend: in memory (tests), io file, web |
| `tekartik_firebase_firestore_idb` | [firestore_idb](firestore_idb) | IndexedDB (idb_shim) backend |
| `tekartik_firebase_firestore_sim` | [firestore_sim](firestore_sim) | client and server of a remote simulation (web socket) |
| `tekartik_firebase_firestore_test` | [firestore_test](firestore_test) | the shared tests every backend runs |

The Flutter, REST, node and admin SDK backends are in their own repos
(`firebase_flutter`, `firebase_rest.dart`, `firebase_node.dart`,
`firebase_admin_sdk.dart`, under `https://github.com/tekartik/`).

## Getting started

Git packages, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_firestore:
    git:
      url: https://github.com/tekartik/firebase_firestore.dart
      path: firestore
dev_dependencies:
  tekartik_firebase_firestore_sembast:
    git:
      url: https://github.com/tekartik/firebase_firestore.dart
      path: firestore_sembast
```

```dart
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';

Future<void> main() async {
  var firestore = newFirestoreMemory();
  await firestore.doc('users/alex').set({'name': 'Alex'});
  print((await firestore.doc('users/alex').get()).data); // {name: Alex}
}
```

See the [firestore package README](firestore/README.md) for the backends,
when to use what and the common pitfalls.

## Tests

Each backend runs the shared suite (`runFirestoreTests` of
`tekartik_firebase_firestore_test`), for example:

```sh
cd firestore_sembast
dart test
```
