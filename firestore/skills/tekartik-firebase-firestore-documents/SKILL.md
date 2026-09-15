---
name: tekartik-firebase-firestore-documents
description: >-
  Use when reading or writing Firestore documents with
  tekartik_firebase_firestore (backend-neutral: flutter, rest, node, sembast,
  idb, sim, admin sdk): obtaining a Firestore from a FirestoreService or
  FirebaseApp, collection/document references and paths, get/set/update/
  delete/add, DocumentSnapshot data, Timestamp vs DateTime, FieldValue
  sentinels, Blob/GeoPoint/VectorValue, document snapshot listeners,
  DocumentData typed helpers, logging and in-memory test setup.
---

# tekartik_firebase_firestore documents

Backend-neutral Firestore API: the same code runs on
`tekartik_firebase_firestore_flutter` (cloud_firestore), `_rest`, `_node`,
`_sembast`, `_idb`, `_sim` and the admin sdk. A `Firestore` is always
obtained from a `FirestoreService`, never constructed directly.

## Guidelines

* Import `package:tekartik_firebase_firestore/firestore.dart`. It re-exports
  `package:tekartik_firebase/firebase.dart` (`Firebase`, `FirebaseApp`/`App`,
  `AppOptions`), so no extra import is needed for the app wiring.
* Get the database with `firestoreService.firestore(app)` (cached per app),
  `firebaseApp.firestore()` (extension on `FirebaseApp`) or
  `Firestore.instance` (default app; throws if no Firestore product was
  registered). Prefer passing the `Firestore` explicitly to your classes.
* Check `firestore.service.supportsXxx` before relying on optional features:
  `supportsFieldValueArray`, `supportsTimestamps`, `supportsTimestampsInSnapshots`,
  `supportsDocumentSnapshotTime`, `supportsBlobs`, `supportsVectorValue`,
  `supportsRecordTrackChanges`, `supportsTrackChanges`, `supportsListCollections`.
* References are cheap and do no I/O: `firestore.collection('users')`,
  `firestore.doc('users/123')`, `collRef.doc('123')`, `docRef.collection('posts')`.
  Collection paths have an odd number of segments, document paths an even
  number. `docRef.id`, `docRef.path`, `docRef.parent` (never null) and
  `collRef.parent` (null for a root collection) navigate back up.
* `collRef.add(data)` creates a document with a generated id. For a
  synchronous id use `AutoIdGenerator.autoId()` from
  `utils/auto_id_generator.dart`; inside a transaction use
  `collRef.txnGenerateUniqueId(txn)` from the same file.
* Write with `docRef.set(data)` (replaces the document),
  `docRef.set(data, SetOptions(merge: true))` (merges) and
  `docRef.update(data)` (fails if the document does not exist). Update keys
  can be dotted paths (`{'address.city': 'Paris'}`). `delete()` succeeds on a
  missing document.
* Read with `docRef.get()`; always test `snapshot.exists` before
  `snapshot.data` (it throws on a missing document) or use
  `snapshot.dataOrNull`. `firestore.getAll(refs)` reads several documents in
  one call, results in the same order. `snapshot.updateTime`/`createTime`
  are null unless `supportsDocumentSnapshotTime`.
* Sentinels are static fields, not functions: `FieldValue.serverTimestamp`,
  `FieldValue.delete` (update/merge only), `FieldValue.arrayUnion([...])`,
  `FieldValue.arrayRemove([...])` (the last two need `supportsFieldValueArray`).
* Store dates as `Timestamp` (`Timestamp.now()`, `Timestamp.fromDateTime(dt)`,
  `Timestamp(seconds, nanoseconds)`, `Timestamp.parse(text)`) or `DateTime`.
  Read them back with `Timestamp.tryAnyAsTimestamp(value)` or
  `DocumentData(snapshot.data).getTimestamp('key')` / `getDateTime('key')`:
  backends return `Timestamp` only when `supportsTimestampsInSnapshots`,
  `DateTime` otherwise. Convert with `timestamp.toDateTime()`,
  `toIso8601String()`, `millisecondsSinceEpoch`; there is no `toDate()`.
* Other value types: `Blob(Uint8List)`/`Blob.fromList(bytes)`,
  `GeoPoint(lat, lng)`, `VectorValue(const [0.1, 0.2])` (`toArray()`), a
  `DocumentReference` stored as a field, nested maps and lists. Anything else
  throws an `ArgumentError` at write time.
* `DocumentData(map)` wraps a `Map<String, Object?>` with typed accessors
  (`getString`, `getInt`, `getTimestamp`, `getDocumentReference`, `getData`
  for nested maps, `setTimestamp`, `setFieldValue`, `asMap()`). Prefer the
  typed setters over `setProperty`, which only accepts JSON-like values. For
  real typed models use `tekartik_app_cv_firestore` (cv) instead of ad-hoc maps.
* Listen with `docRef.onSnapshot()` (first event is the current state, also
  fires with `exists == false`). Backends without `supportsRecordTrackChanges`
  (REST) throw `UnsupportedError`: use
  `docRef.onSnapshotSupport(options: TrackChangesSupportOptions(...))` from
  `utils/track_changes_support.dart`, which polls (`refreshDelay`), reads once
  (`TrackChangesSupportOptions.first()`) or refreshes on demand
  (`TrackChangesSupportOptionsController().trigger()`). Cancel subscriptions.
* Path helpers exported by `firestore.dart`: `firestorePathGetParent`,
  `firestorePathGetChild`, `firestorePathGetId`, `firestorePathGetGenericPath`.
* A security rules denial surfaces as a `FirestoreException` with
  `code == FirestoreErrorCode.permissionDenied`; see the queries skill.
* Debug traffic with `FirestoreLogger(firestore: firestore, options:
  FirestoreLoggerOptions.all())` from `firestore_logger.dart`; dev only.
* Unit tests: use `newFirestoreMemory()` from
  `tekartik_firebase_firestore_sembast` for a real in-memory database.
  `FirestoreMock` (`utils/firestore_mock.dart`) only resolves paths and
  references; its reads and writes throw. Backend implementers run
  `runFirestoreTests` from `tekartik_firebase_firestore_test`.

## Examples

### Wiring and CRUD

```dart
import 'package:tekartik_firebase_firestore/firestore.dart';

/// Any backend: [firebase] and [firestoreService] come from the platform
/// package (flutter, rest, node, sembast...).
Firestore openFirestore(Firebase firebase, FirestoreService firestoreService) {
  var app = firebase.initializeApp();
  return firestoreService.firestore(app);
}

Future<void> userCrud(Firestore firestore, String userId) async {
  var userRef = firestore.doc('users/$userId');
  await userRef.set({
    'name': 'Alex',
    'tags': ['dart'],
    'createdAt': FieldValue.serverTimestamp,
  });
  await userRef.set({'email': 'alex@example.com'}, SetOptions(merge: true));
  await userRef.update({
    'name': 'Alexandre',
    'email': FieldValue.delete,
    if (firestore.service.supportsFieldValueArray)
      'tags': FieldValue.arrayUnion(['flutter']),
  });

  var snapshot = await userRef.get();
  var data = snapshot.dataOrNull;
  if (data != null) {
    var createdAt = Timestamp.tryAnyAsTimestamp(data['createdAt']);
    print('${data['name']} created ${createdAt?.toDateTime()}');
  }
  var postRef = await userRef.collection('posts').add({'title': 'Hello'});
  await userRef.delete();
}
```

### Typed access with DocumentData

```dart
import 'package:tekartik_firebase_firestore/firestore.dart';

class Profile {
  final String name;
  final DateTime? createdAt;
  Profile({required this.name, this.createdAt});

  static Profile? fromSnapshot(DocumentSnapshot snapshot) {
    if (!snapshot.exists) return null;
    var data = DocumentData(snapshot.data);
    return Profile(
      name: data.getString('name') ?? '',
      createdAt: data.getDateTime('createdAt'),
    );
  }

  Map<String, Object?> toMap() {
    var data = DocumentData()..setString('name', name);
    if (createdAt != null) {
      data.setTimestamp('createdAt', Timestamp.fromDateTime(createdAt!));
    }
    return data.asMap();
  }
}
```

### Listening on any backend

```dart
import 'dart:async';

import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/track_changes_support.dart';

StreamSubscription<DocumentSnapshot> watchSettings(
  Firestore firestore, {
  required void Function(Map<String, Object?>? data) onData,
}) {
  var ref = firestore.doc('app/settings');
  // Native listener when supported, polling every 30s otherwise.
  return ref
      .onSnapshotSupport(
        options: TrackChangesSupportOptions(
          refreshDelay: const Duration(seconds: 30),
        ),
      )
      .listen((snapshot) => onData(snapshot.dataOrNull));
}
```

### In-memory test

```dart
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:test/test.dart';

void main() {
  test('set and get', () async {
    var firestore = newFirestoreMemory();
    var ref = firestore.doc('tests/doc1');
    await ref.set({'value': 1, 'when': Timestamp(10, 0)});
    expect((await ref.get()).data, {'value': 1, 'when': Timestamp(10, 0)});
    expect((await firestore.doc('tests/missing').get()).exists, isFalse);
  });
}
```
