// ignore_for_file: avoid_print

import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';

import 'package:tekartik_firebase_firestore_sim/src/firestore_sim_plugin.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';

import 'example_io_client.dart';

Future<void> main(List<String> args) async {
  var firebaseSimServer = await firebaseSimServe(
    FirebaseLocal(),
    webSocketChannelServerFactory: webSocketChannelServerFactoryIo,
    port: urlKvPort,
    plugins: [FirestoreSimPlugin(firestoreServiceMemory)],
  );
  print('url ${firebaseSimServer.url}');
}
