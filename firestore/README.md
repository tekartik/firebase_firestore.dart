# tekartik_firebase_firestore

Platform neutral Firestore API: documents, queries, listeners, transactions
and batches. The same code runs on Flutter, the Dart VM (REST, admin SDK),
node, the browser and in memory (tests): write your data code against this
package, pick the backend in the app.

This package has no backend of its own, see [Backends](#backends).

## Getting started

Git package, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_firestore:
    git:
      url: https://github.com/tekartik/firebase_firestore.dart
      path: firestore
```

The in memory backend (sembast), for tests and tools:

```yaml
dev_dependencies:
  tekartik_firebase_firestore_sembast:
    git:
      url: https://github.com/tekartik/firebase_firestore.dart
      path: firestore_sembast
```

```dart
// Re-exports package:tekartik_firebase_firestore/firestore.dart.
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';

Future<void> main() async {
  // In memory: swap for the backend of your platform (see below).
  var firestore = newFirestoreMemory();

  var userRef = firestore.collection('users').doc('alex');
  await userRef.set({'name': 'Alex', 'createdAt': FieldValue.serverTimestamp});
  await userRef.update({'visits': FieldValue.increment(1)});

  var snapshot = await userRef.get();
  print(snapshot.data['visits']); // 1

  var query = firestore.collection('users').where('name', isEqualTo: 'Alex');
  print((await query.get()).ids); // [alex]
}
```

A complete program is in [example/example.md](example/example.md).

## Backends

A `Firestore` always comes from a `FirestoreService`:
`firestoreService.firestore(app)` (one instance per app, also returned by
`app.firestore()`).

| Backend | Package (repo, path) | Service | Runs on |
|---|---|---|---|
| In memory, io file, web | `tekartik_firebase_firestore_sembast` (firebase_firestore.dart, `firestore_sembast`) | `newFirestoreServiceMemory()`, `firestoreServiceIo`, `firestoreServiceWeb` (`newFirestoreMemory()` for a ready Firestore) | everywhere (tests, tools, local apps) |
| IndexedDB | `tekartik_firebase_firestore_idb` (firebase_firestore.dart, `firestore_idb`) | `idbFactory.firestoreService` | web, io (idb_shim) |
| Flutter | `tekartik_firebase_firestore_flutter` (firebase_flutter, `firestore_flutter`) | `firestoreServiceFlutter` | Flutter (cloud_firestore) |
| REST | `tekartik_firebase_firestore_rest` (firebase_rest.dart, `firestore_rest`) | `firestoreServiceRest` | Dart VM |
| Node | `tekartik_firebase_firestore_node` (firebase_node.dart, `firestore_node`) | `firestoreServiceNode` | node, Cloud Functions |
| Admin SDK | `tekartik_firebase_admin_sdk` (firebase_admin_sdk.dart, `firebase_admin_sdk`) | `firestoreServiceAdminSdk` | Dart VM server |
| Sim | `tekartik_firebase_firestore_sim` (firebase_firestore.dart, `firestore_sim`) | `firestoreServiceSim` | client of a sim server (web socket) |

All the repos are under `https://github.com/tekartik/`. The app comes from
`tekartik_firebase` (see its README); a memory app:
`newFirebaseAppMemory()` from `tekartik_firebase_local`.

Backends differ: check `firestore.service.supportsXxx` before an optional
feature (`supportsFieldValueArray`, `supportsFieldValueIncrement`,
`supportsTrackChanges`, `supportsQuerySelect`, `supportsAggregateQueries`,
`supportsListCollections`, `supportsListMissingDocuments`...).

## When to use what

* Import `package:tekartik_firebase_firestore/firestore.dart` (it re-exports
  `package:tekartik_firebase/firebase.dart`).
* References do no I/O: `firestore.collection('users')`,
  `firestore.doc('users/alex')`, `collRef.doc(id)`, `docRef.collection(id)`.
* Write: `set` (replace), `set(data, SetOptions(merge: true))`, `update`
  (fails on a missing document, dotted keys `'address.city'`), `delete`,
  `collRef.add(data)` (generated id). Sentinels: `FieldValue.serverTimestamp`,
  `FieldValue.delete`, `FieldValue.arrayUnion([...])`,
  `FieldValue.arrayRemove([...])`, `FieldValue.increment(n)`.
* Read: `docRef.get()` (test `snapshot.exists`, or use `snapshot.dataOrNull`),
  `firestore.getAll(refs)`, `query.get()`, `query.count()`.
* Query: `where`, `orderBy`, `limit`, `startAt`/`startAfter`/`endAt`/`endBefore`
  (`values:` follow the `orderBy` fields, fewer values than order bys are
  allowed), `select`, `firestore.collectionGroup(id)`, `aggregate`.
* Listen: `docRef.onSnapshot()`, `query.onSnapshot()`; on any backend (polling
  when the backend cannot listen) `onSnapshotSupport` from
  `utils/track_changes_support.dart`.
* Atomic writes: `firestore.runTransaction`, `firestore.batch()`, or
  `firestore.runTransactionSupport` (a batch when transactions are not
  supported).
* Values: `Timestamp`, `DateTime`, `Blob`, `GeoPoint`, `VectorValue`, a
  `DocumentReference`, nested maps and lists.
* Utilities: page by page iteration and joins (`utils/query_iterate.dart`,
  `utils/query_join.dart`), bulk delete and copy (`utils/query.dart`,
  `utils/collection.dart`, `utils/copy_utils.dart`), several document
  listeners at once (`onDocumentSnapshots`, `utils/document.dart`), ids
  (`AutoIdGenerator.autoId()`, `utils/auto_id_generator.dart`), a logger
  (`firestore_logger.dart`).
* Backend authors: the mixins of `firestore_mixin.dart`, the shared tests of
  `tekartik_firebase_firestore_test`.

## Common pitfalls

* `snapshot.data` throws on a missing document: check `snapshot.exists`.
* `docRef.update` throws on a missing document; `set` with merge does not.
* Dates come back as `Timestamp` (not `DateTime`): convert with
  `toDateTime()`, or read with `DocumentData(snapshot.data).getDateTime(key)`.
* A range filter and the cursors apply to ordered fields: add the matching
  `orderBy`.
* `onSnapshot` throws `UnsupportedError` on REST: use `onSnapshotSupport`.
* A transaction action can run several times: no side effect in it, and all
  the reads before the writes.
* Cancel every listener subscription.
* The `DocumentData` typed getters (`getString`, `getInt`...) throw a
  `TypeError` when the field holds another type.
* `recursiveDelete`/`recursiveCopyTo` need `supportsListCollections`; the
  documents under a "missing" document (no data, sub-collections) are only
  visited when `supportsListMissingDocuments`.

## Skills

* [Documents](skills/tekartik-firebase-firestore-documents/SKILL.md): wiring,
  read/write, values, listeners, tests.
* [Queries](skills/tekartik-firebase-firestore-queries/SKILL.md): queries,
  pagination, iteration and joins, transactions, batches, errors.
