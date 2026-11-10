# tekartik_firebase_firestore_sim

A `Firestore` whose data lives in another process: a firebase sim server
(`tekartik_firebase_sim`) hosts a local Firestore (usually
`tekartik_firebase_firestore_sembast`) and clients (Dart VM, browser,
Flutter) reach it over a web socket: reads, writes, queries, listeners,
batches and transactions. Handy to give several clients one shared local
database during development and in multi client tests.

## Getting started

Git packages, not on pub.dev:

```yaml
dependencies:
  tekartik_firebase_firestore_sim:
    git:
      url: https://github.com/tekartik/firebase_firestore.dart
      path: firestore_sim
  tekartik_firebase_sim:
    git:
      url: https://github.com/tekartik/firebase.dart
      path: firebase_sim
  # The server side hosts a local firestore on a local firebase.
  tekartik_firebase_firestore_sembast:
    git:
      url: https://github.com/tekartik/firebase_firestore.dart
      path: firestore_sembast
  tekartik_firebase_local:
    git:
      url: https://github.com/tekartik/firebase.dart
      path: firebase_local
  # The in memory transport of the example below.
  tekartik_web_socket:
    git:
      url: https://github.com/tekartik/web_socket.dart
      path: web_socket
```

Server and client in one program, over the in memory transport:

```dart
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_firestore_sim/firestore_sim.dart';
import 'package:tekartik_firebase_firestore_sim/firestore_sim_server.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:tekartik_web_socket/web_socket.dart';

Future<void> main() async {
  // Server: an in memory sembast firestore published over the sim protocol.
  var simServer = await firebaseSimServe(
    FirebaseLocal(),
    webSocketChannelServerFactory: webSocketChannelFactoryMemory.server,
    plugins: [
      FirestoreSimPlugin(firestoreService: newFirestoreServiceMemory()),
    ],
  );

  // Client.
  var firebase = getFirebaseSim(
    clientFactory: webSocketChannelFactoryMemory.client,
    uri: simServer.uri,
  );
  var app = firebase.initializeApp() as FirebaseAppSim;
  var firestore = firestoreServiceSim.firestore(app);

  var ref = firestore.doc('tests/doc1');
  var subscription = ref.onSnapshot().listen((snapshot) {
    print('snapshot: ${snapshot.exists ? snapshot.data : null}');
  });
  await ref.set({'count': 1});
  await firestore.runTransaction((transaction) async {
    var count = (await transaction.get(ref)).data['count'] as int;
    transaction.update(ref, {'count': count + 1});
  });
  print('count: ${(await ref.get()).data['count']}');
  await subscription.cancel();

  // delete() leaves the connection of the app open: close it.
  var simClient = await app.simClient;
  await app.delete();
  await simClient.close();
  await simServer.close();
}
```

In real use the server runs in a Dart VM process
(`webSocketChannelServerFactoryIo` of `tekartik_web_socket_io`,
`port: firebaseSimDefaultPort`) and the clients connect with
`getFirebaseSim(uri: getFirebaseSimLocalhostUri())`.

## Platforms

| Side | Library | Runs on |
|---|---|---|
| client | `firestore_sim.dart` (`firestoreServiceSim`) | Dart VM, web, Flutter |
| server | `firestore_sim_server.dart` (`FirestoreSimPlugin`) | Dart VM only |

## What to know

* `firestore_sim.dart` only exports `firestoreServiceSim`: import
  `package:tekartik_firebase_firestore/firestore.dart` for the API.
* One `Firestore` per app: `firestoreServiceSim.firestore(app)` returns the
  same instance each time.
* The service reports what the client supports, whatever the hosted
  firestore does: no array `FieldValue`, no `listCollections()`, no
  aggregate queries; `listDocuments()` assumes a host listing missing
  documents (sembast). Branch on the `supports...` flags.
* Transactions: the transactions of a client run one at a time (a second one
  waits for the first one's commit), without retry on contention; a write
  outside the transaction inside its update function waits forever, and
  transactions of two clients are not isolated from each other. Set
  `skipConcurrentTransactionTests = true` with the shared test suite.
* `app.delete()` ends the listeners (done) but leaves the connection open:
  close `await app.simClient`, as above, or a program does not exit. When the
  connection closes (server gone), a listener ends with the error.
* A development tool: the transport is not authenticated and there are no
  security rules.

The [tekartik-firebase-firestore-sim-setup skill](skills/tekartik-firebase-firestore-sim-setup/SKILL.md)
has more examples (io server and client, shared and multi client tests).
