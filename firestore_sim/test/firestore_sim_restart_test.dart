import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_sim/firestore_sim.dart';
import 'package:test/test.dart';

import 'test_common.dart';

void main() {
  // debugRpcServer = devTrue;
  // debugFirebaseSimServer = devTrue;
  // debugFirebaseSimClient = devTrue;
  group('restart', () {
    var docTopPath = 'test/firestore_sim_restart';
    late FirebaseApp app;

    late Firestore firestore;
    late TestContext testContext;

    Future<void> initAppContext() async {
      app = testContext.firebase.initializeApp();
      firestore = firestoreServiceSim.firestore(app);
    }

    Future<void> initContext() async {
      testContext = await initFirestoreTestContextSim();
      await initAppContext();
    }

    setUp(() async {
      await initContext();
    });

    tearDown(() async {
      await app.delete();
      await testContext.close();
    });

    test('restart_app', () async {
      var doc = firestore.doc('$docTopPath/record/record1');
      var now = Timestamp.now();
      var map = {'name': 'test1', 'timestamp': now};
      await doc.set(map);
      await app.delete();
      await initAppContext();
      doc = firestore.doc('$docTopPath/record/record1');
      expect((await doc.get()).data, map);
    });
  });
}
