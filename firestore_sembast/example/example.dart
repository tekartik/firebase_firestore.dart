import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_firestore_test/menu/firebase_client_menu.dart';

Future<void> main(List<String> args) async {
  var firestore = newFirestoreMemory(); // .debugQuickLoggerWrapper();
  await mainMenu(args, () {
    firestoreMainMenu(
      context: FirestoreMainMenuContext(doc: firestore.doc('test/1')),
    );
  });
}
