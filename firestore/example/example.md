# tekartik_firebase_firestore example

Backend neutral code (`TodoStore` only sees a `Firestore`) run on the in memory
backend: writes, a query listener, a transaction and a page by page read.

Dependencies:

```yaml
dependencies:
  tekartik_firebase_firestore:
    git:
      url: https://github.com/tekartik/firebase_firestore.dart
      path: firestore
  tekartik_firebase_firestore_sembast:
    git:
      url: https://github.com/tekartik/firebase_firestore.dart
      path: firestore_sembast
  tekartik_firebase_local:
    git:
      url: https://github.com/tekartik/firebase.dart
      path: firebase_local
```

```dart
import 'dart:async';

import 'package:tekartik_firebase_firestore/utils/query_iterate.dart';
// Re-exports package:tekartik_firebase_firestore/firestore.dart.
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

/// Backend neutral code: it only sees a [Firestore].
class TodoStore {
  final Firestore firestore;

  TodoStore(this.firestore);

  CollectionReference get _todos => firestore.collection('todos');

  Future<String> add(String title) async {
    var ref = await _todos.add({
      'title': title,
      'done': false,
      'createdAt': FieldValue.serverTimestamp,
    });
    return ref.id;
  }

  Future<void> setDone(String id) => _todos.doc(id).update({'done': true});

  /// The open todos, oldest first.
  Query get openTodos =>
      _todos.where('done', isEqualTo: false).orderBy('createdAt');

  /// Counts the todos atomically in a summary document.
  Future<int> incrementTotal() {
    var summaryRef = firestore.doc('summary/todos');
    return firestore.runTransactionSupport((txn) async {
      var snapshot = await txn.get(summaryRef);
      var total = ((snapshot.dataOrNull?['total'] as int?) ?? 0) + 1;
      txn.set(summaryRef, {'total': total});
      return total;
    });
  }
}

Future<void> main() async {
  // The in memory backend: firestoreServiceFlutter, firestoreServiceRest...
  // in a real app.
  var app = newFirebaseAppMemory();
  var firestore = newFirestoreServiceMemory().firestore(app);
  var store = TodoStore(firestore);

  // Listen to the open todos (cancel the subscription when done).
  var subscription = store.openTodos.onSnapshot().listen((snapshot) {
    print('open: ${snapshot.docs.map((doc) => doc.data['title']).toList()}');
  });

  var id = await store.add('write the README');
  await store.add('run the tests');
  await store.incrementTotal();
  print('total: ${await store.incrementTotal()}'); // total: 2
  await store.setDone(id);

  // Read a whole query page by page.
  await store.openTodos.queryIterate(
    options: QueryFindOptions(pageSize: 100),
    onRow: (doc) {
      var createdAt = doc.data['createdAt'] as Timestamp;
      print('${doc.data['title']} created at ${createdAt.toDateTime()}');
      return true; // false to stop
    },
  );

  await Future<void>.delayed(const Duration(milliseconds: 100));
  await subscription.cancel();
  await app.delete();
}
```
