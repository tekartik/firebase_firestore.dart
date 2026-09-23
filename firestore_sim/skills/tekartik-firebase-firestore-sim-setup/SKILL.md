---
name: tekartik-firebase-firestore-sim-setup
description: >-
  Use when a Dart or Flutter client must talk to a Firestore hosted in another
  process over a websocket, with tekartik_firebase_firestore_sim: the client
  firestoreServiceSim (firestore_sim.dart) bound to a getFirebaseSim app, and
  the server FirestoreSimPlugin (firestore_sim_server.dart) registered in
  firebaseSimServe with webSocketChannelServerFactoryIo or ...Memory, plus
  running the shared firestore tests against the simulated service.
---

# Firestore over the firebase simulator (tekartik_firebase_firestore_sim)

Implements the `tekartik_firebase_firestore` abstraction as a JSON-RPC client
over a websocket: the `Firestore` object in the client process forwards every
read, write, query, snapshot stream, batch and transaction to a Firestore
living in a server process (typically a `tekartik_firebase_firestore_sembast`
one). Used to give a browser or Flutter client a real shared database during
development and in multi-client tests, without any Google backend.

## Guidelines

* Dependency (not on pub.dev, git only), on both sides:
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
  ```
  The server also needs a real implementation to host (usually
  `tekartik_firebase_firestore_sembast`, same repo, `path: firestore_sembast`)
  and a websocket transport (`tekartik_web_socket_io`,
  `https://github.com/tekartik/web_socket.dart`, `path: web_socket_io`).
* Two entry points, one per side:
  * client: `package:tekartik_firebase_firestore_sim/firestore_sim.dart`
    exposes the single getter `firestoreServiceSim` (a `FirestoreService`).
  * server: `package:tekartik_firebase_firestore_sim/firestore_sim_server.dart`
    exposes the single class `FirestoreSimPlugin({required firestoreService})`.
  Neither re-exports the firestore API: import
  `package:tekartik_firebase_firestore/firestore.dart` yourself for
  `Firestore`, `DocumentSnapshot`, `Timestamp`, `FieldValue`, ...
* Server: build the hosted service, then
  `firebaseSimServe(firebase, webSocketChannelServerFactory: ..., plugins:
  [FirestoreSimPlugin(firestoreService: ...)], port: ...)` from
  `package:tekartik_firebase_sim/firebase_sim_server.dart`. It returns a
  `FirebaseSimServer` with `url`, `uri` and `close()`. `firebase` is the
  server-side `Firebase` (e.g. `FirebaseLocal()`); `port` defaults to
  `firebaseSimDefaultPort` (4996), pass `0` for a free port and read
  `simServer.uri`.
* Client: `getFirebaseSim(uri: ..., clientFactory: ...)` from
  `package:tekartik_firebase_sim/firebase_sim.dart` returns a `FirebaseSim`;
  `firebase.initializeApp()` gives a `FirebaseAppSim`, and
  `firestoreServiceSim.firestore(app)` the `Firestore`. Passing a non-sim app
  fails an assert. Without `options`, the project id is
  `firebaseSimDefaultProjectId` (`'sim'`); `getFirebaseSimLocalhostUri(port:)`
  builds the default `ws://localhost:<port>` uri.
* Websocket factories: `webSocketChannelServerFactoryIo` and
  `webSocketChannelClientFactoryIo` from
  `package:tekartik_web_socket_io/web_socket_io.dart` (VM, real sockets);
  `webSocketChannelServerFactoryMemory` and
  `webSocketChannelClientFactoryMemory`, re-exported by the same import, for a
  server and a client in the same isolate (fastest for tests, no port).
  Omitting `clientFactory` in `getFirebaseSim` uses the universal one
  (`dart:io` on the VM, browser websocket on the web).
* One `Firestore` per app, cached: `firestoreServiceSim.firestore(app)` twice
  returns the same instance, also reachable as `app.firestore()`. Two clients
  sharing the database means two `FirebaseSim` instances (or two apps), each
  with its own `firestore(app)`.
* Capabilities of `firestoreServiceSim`: `supportsQuerySelect`,
  `supportsQuerySnapshotCursor`, `supportsTimestamps`,
  `supportsTimestampsInSnapshots`, `supportsDocumentSnapshotTime`,
  `supportsTrackChanges` and `supportsBlobs` are true;
  `supportsFieldValueArray`, `supportsListCollections`,
  `supportsAggregateQueries` and `supportsVectorValue` are false, whatever the
  hosted implementation supports. Branch on the flags, not on the service type.
  `supportsListMissingDocuments` is true: `collRef.listDocuments()` runs on
  the server, so it assumes a hosted implementation listing missing
  documents (sembast).
* `runTransaction` and `batch()` work, but the transaction is opened, run and
  committed through round trips: no client-side retry on contention. Set
  `skipConcurrentTransactionTests = true` when running the shared suite.
* Lifecycle: `await app.delete()` on the client drops the connection for that
  app (a new `initializeApp()` reconnects and sees the same server data);
  `await simServer.close()` stops the server. Close the server in
  `tearDownAll`, otherwise the test process hangs on an open socket.
* Debugging the protocol: set `debugFirebaseSimClient = true` (from
  `firebase_sim.dart`) and/or `debugFirebaseSimServer = true` (from
  `firebase_sim_server.dart`) to log the RPC messages.
* The server side pulls `dart:io` through `tekartik_web_socket_io`: run it on
  the VM. A browser client uses the universal client factory and needs nothing
  from `dart:io`.
* Testing: `runFirestoreTests(firebase:, firestoreService: firestoreServiceSim)`
  or `runFirestoreAppTests(app:, firestoreService:, testContext:)` from
  `package:tekartik_firebase_firestore_test/firestore_test_runner.dart`, and
  `firestoreMulticlientTest(firestore1:, firestore2:, docTopPath:)` from
  `firestore_multi_client_test_runner.dart` for cross-client snapshot propagation.

## Examples

### Simulator server hosting an in-memory Firestore

```dart
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_firestore_sim/firestore_sim_server.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:tekartik_web_socket_io/web_socket_io.dart';

Future<void> main(List<String> args) async {
  var simServer = await firebaseSimServe(
    FirebaseLocal(), // server side apps, data in .dart_tool by default
    webSocketChannelServerFactory: webSocketChannelServerFactoryIo,
    plugins: [
      FirestoreSimPlugin(firestoreService: newFirestoreServiceMemory()),
    ],
    port: firebaseSimDefaultPort, // 4996, use 0 for a free port
  );
  print('firestore sim listening on ${simServer.url}');
}
```

### Client connecting to the simulator

```dart
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_sim/firestore_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';

Future<void> main() async {
  var firebase = getFirebaseSim(
    uri: getFirebaseSimLocalhostUri(port: firebaseSimDefaultPort),
  );
  var app = firebase.initializeApp();
  var firestore = firestoreServiceSim.firestore(app);

  var ref = firestore.doc('tests/doc1');
  await ref.set({'name': 'test1', 'timestamp': Timestamp.now()});
  print((await ref.get()).data);

  var subscription = ref.onSnapshot().listen((snapshot) {
    print('changed: ${snapshot.data}');
  });
  await firestore.runTransaction((transaction) async {
    var snapshot = await transaction.get(ref);
    transaction.update(ref, {'hit': ((snapshot.data['hit'] as int?) ?? 0) + 1});
  });
  await subscription.cancel();
  await app.delete();
}
```

### Server and client in the same isolate (memory websocket)

```dart
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_firestore_sim/firestore_sim.dart';
import 'package:tekartik_firebase_firestore_sim/firestore_sim_server.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test_runner.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:tekartik_web_socket_io/web_socket_io.dart';
import 'package:test/test.dart';

Future<void> main() async {
  // No port, no socket: both ends live in this isolate.
  var simServer = await firebaseSimServe(
    FirebaseLocal(),
    webSocketChannelServerFactory: webSocketChannelServerFactoryMemory,
    plugins: [
      FirestoreSimPlugin(firestoreService: newFirestoreServiceMemory()),
    ],
  );
  var firebase = getFirebaseSim(
    clientFactory: webSocketChannelClientFactoryMemory,
    uri: simServer.uri,
  );

  skipConcurrentTransactionTests = true;
  runFirestoreTests(firebase: firebase, firestoreService: firestoreServiceSim);

  tearDownAll(() async {
    await simServer.close();
  });
}
```

### Two clients on one simulated database

```dart
@TestOn('vm')
library;

import 'package:tekartik_firebase_firestore_sembast/firestore_sembast_io.dart';
import 'package:tekartik_firebase_firestore_sim/firestore_sim.dart';
import 'package:tekartik_firebase_firestore_sim/firestore_sim_server.dart';
import 'package:tekartik_firebase_firestore_test/firestore_multi_client_test_runner.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:tekartik_web_socket_io/web_socket_io.dart';
import 'package:test/test.dart';

Future<void> main() async {
  var simServer = await firebaseSimServe(
    FirebaseLocal(localPath: '.dart_tool/firestore_sim_test'),
    webSocketChannelServerFactory: webSocketChannelServerFactoryIo,
    plugins: [FirestoreSimPlugin(firestoreService: firestoreServiceIo)],
    port: 0, // free port, read simServer.uri
  );
  Firestore newClient() {
    var firebase = getFirebaseSim(
      clientFactory: webSocketChannelClientFactoryIo,
      uri: simServer.uri,
    );
    return firestoreServiceSim.firestore(firebase.initializeApp());
  }

  firestoreMulticlientTest(
    firestore1: newClient(),
    firestore2: newClient(),
    docTopPath: 'tests/multi_client',
  );
  tearDownAll(() async {
    await simServer.close();
  });
}
```

## Common mistakes

* Expecting `Firestore`, `Timestamp` or `FieldValue` from
  `firestore_sim.dart`: it only exports `firestoreServiceSim`.
* Passing a `FirebaseLocal` app (or any non-sim app) to
  `firestoreServiceSim.firestore(app)`.
* Mixing transports: a memory server factory only talks to a memory client
  factory, an io server only to an io (or browser) client.
* Assuming the client supports array `FieldValue`s, `listCollections()`,
  aggregate queries or vector values because the hosted sembast/idb
  implementation does: the sim service reports them as unsupported.
* Forgetting `await simServer.close()`, leaving the test process alive.
