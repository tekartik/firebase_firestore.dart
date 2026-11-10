library;

import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_sim/firestore_sim.dart';
import 'package:tekartik_firebase_sim/firebase_sim_mixin.dart';
import 'package:test/test.dart';

import 'test_common.dart';

/// Lets the late events (server answers, listeners) come.
Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  await Future<void>.delayed(const Duration(milliseconds: 100));
}

void main() {
  test('service and firestore singletons', () async {
    var testContext = await initFirestoreTestContextSim();
    try {
      var app = testContext.firebase.initializeApp();
      expect(identical(firestoreServiceSim, firestoreServiceSim), isTrue);
      expect(
        identical(
          firestoreServiceSim.firestore(app),
          firestoreServiceSim.firestore(app),
        ),
        isTrue,
      );
      await app.delete();
    } finally {
      await close(testContext);
    }
  });

  group('connection', () {
    late FirebaseAppSim app;
    late Firestore firestore;
    late TestContext testContext;
    setUp(() async {
      testContext = await initFirestoreTestContextSim();
      app = testContext.firebase.initializeApp() as FirebaseAppSim;
      firestore = firestoreServiceSim.firestore(app);
    });

    tearDown(() async {
      await app.delete();
      await close(testContext);
    });

    Future<void> checkEndsOnClose(Stream<Object?> stream) async {
      var events = 0;
      var errors = <Object>[];
      var done = Completer<void>();
      var subscription = stream.listen(
        (_) => events++,
        onError: (Object e) => errors.add(e),
        onDone: done.complete,
      );
      await settle();
      expect(events, 1);
      await (await app.simClient).close();
      await done.future.timeout(const Duration(seconds: 5));
      expect(errors, hasLength(1));
      await subscription.cancel().timeout(const Duration(seconds: 5));
    }

    test('document listener ends when the connection closes', () async {
      var ref = firestore.doc('connection/doc');
      await ref.set({'value': 1});
      await checkEndsOnClose(ref.onSnapshot());
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('query listener ends when the connection closes', () async {
      var ref = firestore.doc('connection/query');
      await ref.set({'value': 1});
      await checkEndsOnClose(firestore.collection('connection').onSnapshot());
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('cancel after the connection closed', () async {
      var subscription = firestore
          .doc('connection/cancel')
          .onSnapshot()
          .listen((_) {});
      await settle();
      await (await app.simClient).close();
      // It hung, waiting for a loop that died with the connection.
      await subscription.cancel().timeout(const Duration(seconds: 5));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('listener ends when the app is deleted', () async {
      var done = Completer<void>();
      var errors = <Object>[];
      firestore
          .doc('connection/delete')
          .onSnapshot()
          .listen(
            (_) {},
            onError: (Object e) => errors.add(e),
            onDone: done.complete,
          );
      await settle();
      var simClient = await app.simClient;
      await app.delete();
      await done.future.timeout(const Duration(seconds: 5));
      // What FirebaseAppSim.delete should do (it keeps the connection).
      await simClient.close();
      await settle();
      expect(errors, isEmpty);
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
