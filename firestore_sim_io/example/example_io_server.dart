// ignore_for_file: avoid_print

import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
// ignore: deprecated_member_use
import 'package:tekartik_firebase_firestore_sim/firestore_sim_server.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:tekartik_web_socket_io/web_socket_io.dart';

import 'example_io_client.dart';

Future<void> main(List<String> args) async {
  var firebaseSimServer =
      await serve(FirebaseLocal(), webSocketChannelFactoryIo, port: urlKvPort);
  print('url ${firebaseSimServer.webSocketChannelServer.url}');
  FirestoreSimServer(firestoreServiceMemory, firebaseSimServer);
}
