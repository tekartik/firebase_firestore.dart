import 'dart:async';

import 'package:tekartik_firebase_firestore_sembast/firestore_sembast_io.dart';
import 'package:tekartik_firebase_firestore_sim/src/firestore_sim_server.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:tekartik_firebase_sim_io/firebase_sim_client_io.dart' as sim;
import 'package:tekartik_web_socket_io/web_socket_io.dart';

class TestContext {
  late FirebaseSimServer simServer;
  late Firebase firebase;
}

// using real websocker
Future<TestContext> initTestContextSimIo() async {
  var testContext = TestContext();
  testContext.simServer =
      await serve(FirebaseLocal(), webSocketChannelFactoryIo);
  testContext.firebase = sim.getFirebaseSim(
      clientFactory: webSocketChannelClientFactoryIo,
      url: testContext.simServer.webSocketChannelServer.url);
  FirestoreSimServer(
      firestoreServiceMemory, testContext.simServer, testContext.firebase);
  return testContext;
}

// memory only
Future<TestContext> initTestContextSim() async {
  var testContext = TestContext();
  // The server use firebase io
  testContext.simServer =
      await serve(FirebaseLocal(), webSocketChannelFactoryMemory);
  testContext.firebase = sim.getFirebaseSim(
      clientFactory: webSocketChannelClientFactoryMemory,
      url: testContext.simServer.webSocketChannelServer.url);
  FirestoreSimServer(
      firestoreServiceIo, testContext.simServer, testContext.firebase);
  return testContext;
}

Future close(TestContext testContext) async {
  await testContext.simServer.close();
}
