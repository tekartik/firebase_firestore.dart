library;

import 'dart:async';

import 'package:tekartik_firebase_firestore_sim/firestore_sim.dart';
import 'package:tekartik_firebase_firestore_test/firestore_multi_client_test.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:tekartik_firebase_sim_io/firebase_sim_client_io.dart' as sim;
import 'package:tekartik_web_socket_io/web_socket_io.dart';
import 'package:test/test.dart';

import 'test_common.dart';

Future main() async {
  // debugSimServerMessage = true;
  skipConcurrentTransactionTests = true;
  var testContext = await initTestContextSim();
  var firebase = testContext.firebase;
  var firebase2 = sim.getFirebaseSim(
      clientFactory: webSocketChannelClientFactoryMemory,
      uri: testContext.simServer.uri);
  var app1 = firebase.initializeApp();
  var app2 = firebase2.initializeApp();

  var firestore1 = firestoreServiceSim.firestore(app1);
  var firestore2 = firestoreServiceSim.firestore(app2);

  firestoreMulticlientTest(
      firestore1: firestore1, firestore2: firestore2, docTopPath: 'test/doc');
  tearDownAll(() async {
    await close(testContext);
  });
}
