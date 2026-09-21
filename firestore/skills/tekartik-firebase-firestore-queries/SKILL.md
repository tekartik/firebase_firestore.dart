---
name: tekartik-firebase-firestore-queries
description: >-
  Use when querying Firestore with tekartik_firebase_firestore: Query
  where/orderBy/limit/select, cursor pagination (startAt, startAfter, endAt,
  endBefore), collection group queries, QuerySnapshot and document changes,
  query listeners on any backend, count and aggregate queries, transactions
  and write batches (runTransaction, runTransactionSupport, WriteBatch), bulk
  delete/copy helpers, page-by-page iteration and join helpers
  (queryIterate, queryStream, queryJoinIterate in utils/query_iterate.dart and
  utils/query_join.dart), and FirestoreException / FirestoreErrorCode handling
  such as permission-denied raised by security rules.
---

# tekartik_firebase_firestore queries, transactions and errors

`Query` is the backend-neutral query builder of `tekartik_firebase_firestore`;
`CollectionReference` extends it, so a collection is already a query over
all its documents. Every refinement returns a new immutable `Query`.

## Guidelines

* Import `package:tekartik_firebase_firestore/firestore.dart`. Bulk helpers
  are in `utils/query.dart`, `utils/collection.dart`, `utils/copy_utils.dart`;
  page-by-page iteration in `utils/query_iterate.dart` and joins in
  `utils/query_join.dart`; polling listeners in
  `utils/track_changes_support.dart`.
* Filter with one comparison per `where` call and chain calls for several
  conditions: `isEqualTo`, `isLessThan`, `isLessThanOrEqualTo`,
  `isGreaterThan`, `isGreaterThanOrEqualTo`, `arrayContains`,
  `arrayContainsAny: [...]`, `whereIn: [...]`, `isNull: true`. Field paths
  can be dotted (`'sub.value'`); map and `Timestamp` values compare fine.
  There is no `isNotEqualTo`/`whereNotIn` in this abstraction: filter in Dart.
* Sort with `orderBy(field, descending: true)` (chain for multi-field sort),
  `orderById()` (must be the last `orderBy`) or `orderBy(firestoreNameFieldPath)`
  (`'__name__'`, the document id). Range filters and cursors apply to the
  ordered fields, so always add the matching `orderBy`.
* Paginate with `limit(n)` and `startAt/startAfter/endAt/endBefore(values: [...])`
  where values follow the `orderBy` order. The `snapshot:` variant requires
  `supportsQuerySnapshotCursor`; `values:` ending with the last document id
  after an `orderBy(firestoreNameFieldPath)` works everywhere and is the
  pattern used by the package helpers. There is no `offset`.
* `select(['field'])` restricts returned fields only when
  `supportsQuerySelect`; the full document comes back otherwise.
* `query.get()` returns a `QuerySnapshot`: `docs` (`DocumentSnapshot` list,
  `exists` is always true), `documentChanges` (`DocumentChange.type`
  added/modified/removed, `oldIndex`, `newIndex`, `document`) and the
  extension getters `ids` and `refs`. `List<DocumentReference>.ids` exists too.
* `firestore.collectionGroup('posts')` queries every collection named `posts`
  at any depth; backend support varies and Firestore needs a group index.
* Listen with `query.onSnapshot()` when `supportsTrackChanges` (REST throws
  `UnsupportedError`); otherwise use
  `query.onSnapshotSupport(options: TrackChangesSupportOptions(refreshDelay: ...))`
  which falls back to polling, or `TrackChangesSupportOptions.first()` for a
  single read. Always cancel the subscription.
* Count with `query.count()` or watch it with `query.onCount()`. Sums and
  averages need `supportsAggregateQueries`:
  `query.aggregate([AggregateField.count(), AggregateField.sum('f'),
  AggregateField.average('f')]).get()` then `snapshot.count`,
  `snapshot.getSum('f')`, `snapshot.getAverage('f')` (field path strings,
  null when not requested; average is null on an empty set).
* Transactions: `firestore.runTransaction((txn) async { ... })` with
  `txn.get(ref)` before any `txn.set/update/delete`. The action may run
  several times (retried on concurrent modification) so keep it pure; its
  return value is returned by `runTransaction`; a thrown error aborts it.
* Check `firestore.supportsTransaction` (false for REST with email/password
  login). `firestore.runTransactionSupport(action)` (exported by
  `firestore.dart`) uses a real transaction when available and otherwise a
  `WriteBatchTransaction`: reads are plain `get`s and writes go through a
  `WriteBatch` committed at the end, with no isolation or retry.
* Batch writes: `var batch = firestore.batch(); batch.set(ref, data,
  SetOptions(merge: true)); batch.update(ref, data); batch.delete(ref);
  await batch.commit();`. Nothing is applied before `commit`. Keep batches
  small (the helpers default to 10 documents per batch).
* Bulk helpers (extension methods): `query.queryDelete(batchSize:, keepIds:)`,
  `query.queryCopyTo(dstCollRef)`, `query.queryAction(actionFunction: (ids)
  async => ids.length)` which pages by id (return -1 to abort);
  `collRef.delete()`, `collRef.copyTo(dstCollRef, clearExisting: true)`,
  `deleteCollection(firestore, collRef)`. `docRef.recursiveDelete(firestore)`,
  `docRef.recursiveCopyTo(dstFirestore, dstRef)` and
  `collRef.recursiveListDocuments()` need `supportsListCollections`.
* Errors: backends throw a `FirestoreException` (`code`, `message`,
  `details`). Compare `code` with the `FirestoreErrorCode` string constants:
  `permissionDenied` (security rules denial, or missing auth on REST),
  `unauthenticated`, `notFound`, `unknown`, `internal`; other codes use the
  gRPC names (`'aborted'`, `'unavailable'`, ...). The class is abstract:
  never construct it yourself. Missing documents do not throw (`exists` is
  false, `docs` is empty); `update` on a missing document fails at commit.

## Examples

### Filter, order and paginate

```dart
import 'package:tekartik_firebase_firestore/firestore.dart';

/// Returns one page of active users ordered by age, [pageSize] at a time.
/// [after] is the last document of the previous page (null for the first).
Future<List<DocumentSnapshot>> activeUsersPage(
  Firestore firestore, {
  required int pageSize,
  DocumentSnapshot? after,
}) async {
  var query = firestore
      .collection('users')
      .where('active', isEqualTo: true)
      .where('age', isGreaterThanOrEqualTo: 18)
      .orderBy('age')
      .orderBy(firestoreNameFieldPath)
      .limit(pageSize);
  if (after != null) {
    // values follow the orderBy fields; works without snapshot cursor support
    query = query.startAfter(values: [after.data['age'], after.ref.id]);
  }
  var snapshot = await query.get();
  return snapshot.docs;
}
```

### Live list with change tracking

```dart
import 'dart:async';

import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/track_changes_support.dart';

StreamSubscription<QuerySnapshot> watchTodos(Firestore firestore) {
  var query = firestore.collection('todos').orderBy('createdAt', descending: true);
  return query
      .onSnapshotSupport(
        options: TrackChangesSupportOptions(refreshDelay: const Duration(seconds: 15)),
      )
      .listen((snapshot) {
    for (var change in snapshot.documentChanges) {
      switch (change.type) {
        case DocumentChangeType.added:
        case DocumentChangeType.modified:
          print('${change.document.ref.id} => ${change.document.data}');
        case DocumentChangeType.removed:
          print('${change.document.ref.id} removed');
      }
    }
  });
}
```

### Count and aggregate

```dart
import 'package:tekartik_firebase_firestore/firestore.dart';

Future<String> orderStats(Firestore firestore) async {
  var completed = firestore
      .collection('orders')
      .where('status', isEqualTo: 'completed');
  if (!firestore.service.supportsAggregateQueries) {
    return 'count: ${await completed.count()}';
  }
  var snapshot = await completed.aggregate([
    AggregateField.count(),
    AggregateField.sum('total'),
    AggregateField.average('total'),
  ]).get();
  return 'count: ${snapshot.count} sum: ${snapshot.getSum('total')} '
      'avg: ${snapshot.getAverage('total')}';
}
```

### Iterate a whole query, and join another collection

```dart
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/query_iterate.dart';
import 'package:tekartik_firebase_firestore/utils/query_join.dart';

/// Walks every matching document page by page (one `get()` per page), so the
/// whole result is never held in memory and returning false stops reading.
Future<void> archiveOldBooks(Firestore firestore) async {
  await firestore
      .collection('books')
      .where('archived', isEqualTo: false)
      .queryIterate(
        options: QueryFindOptions(pageSize: 200),
        onRow: (doc) async {
          await doc.ref.update({'archived': true});
          return true; // false to stop
        },
      );
}

/// Each book with its author: the authors of a whole page are fetched in one
/// `getAll`, and an author referenced by several books is fetched once.
Future<void> printBooksWithAuthor(Firestore firestore) async {
  var authors = firestore.collection('authors');
  await firestore.collection('books').queryJoinIterate(
        options: QueryJoinFindOptions(
          joinField: 'authorId', // holds an author document id
          targetCollection: authors,
          inner: true, // skip the books whose author is missing (left join by default)
        ),
        onRow: (row) {
          print('${row.doc!.data['title']} by ${row.targetDoc!.data['name']}');
          return true;
        },
      );
}

/// Only the authors actually referenced by a book, each one once. `withSource`
/// false also selects just the join field on the books.
Future<List<DocumentSnapshot>> referencedAuthors(Firestore firestore) async {
  var rows = await firestore.collection('books').findJoinRows(
        options: QueryJoinFindOptions(
          joinField: 'authorId',
          targetCollection: firestore.collection('authors'),
          withSource: false,
          distinct: true,
          inner: true,
        ),
      );
  return rows.map((row) => row.targetDoc!).toList();
}
```

Notes:

* Paging uses a `startAfter` cursor and appends an ordering by document id.
  The query's existing `orderBy` fields and `limit` are automatically extracted from the query.
* `QueryJoinFindOptions` and `QueryFindOptions` are distinct option classes: `QueryJoinFindOptions` configures
  the join (`joinField`, `targetCollection`, `withSource`, `withTarget`, `distinct`, `inner`, `pageSize`),
  while the query itself provides filters, ordering and limits.
* `joinField` can hold a `DocumentReference`, a document id inside
  `targetCollection`, or a full document path when `targetCollection` is null. A
  dotted path (`'ref.authorId'`) reads a nested field.

### Transaction, batch and error handling

```dart
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/query.dart';

/// Atomic increment (batch fallback when transactions are unsupported).
Future<int> incrementCounter(Firestore firestore, DocumentReference ref) {
  return firestore.runTransactionSupport((txn) async {
    var snapshot = await txn.get(ref);
    var value = ((snapshot.dataOrNull?['value'] as int?) ?? 0) + 1;
    txn.set(ref, {'value': value, 'updatedAt': FieldValue.serverTimestamp},
        SetOptions(merge: true));
    return value;
  });
}

Future<void> archiveUser(Firestore firestore, String userId) async {
  var userRef = firestore.doc('users/$userId');
  try {
    await userRef.collection('posts').queryDelete(batchSize: 10);
    var batch = firestore.batch();
    batch.update(userRef, {'archived': true});
    await batch.commit();
  } on FirestoreException catch (e) {
    if (e.code == FirestoreErrorCode.permissionDenied) {
      print('denied by security rules: ${e.message}');
      return;
    }
    rethrow;
  }
}
```
