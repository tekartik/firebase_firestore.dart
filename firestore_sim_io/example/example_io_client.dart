import 'package:tekartik_firebase_firestore_sim/firestore_sim.dart';
import 'package:tekartik_firebase_firestore_test/menu/firebase_client_menu.dart';
import 'package:tekartik_firebase_sim/firebase_sim.dart';
import 'package:tekartik_firebase_sim_io/firebase_sim_client_io.dart';

var urlKv = '4338987.url'.kvFromVar(
  defaultValue: 'ws://localhost:${firebaseSimDefaultPort.toString()}',
);

int? get urlKvPort => int.tryParse((urlKv.value ?? '').split(':').last);
Future<void> main(List<String> args) async {
  var firebase = getFirebaseSim(uri: Uri.parse(urlKv.value!));
  var app = firebase.initializeApp();
  var firestore = firestoreServiceSim.firestore(
    app,
  ); // .debugQuickLoggerWrapper();
  await mainMenu(args, () {
    firestoreMainMenu(
      context: FirestoreMainMenuContext(doc: firestore.doc('test/1')),
    );
    keyValuesMenu('kv', [urlKv]);
  });
}
