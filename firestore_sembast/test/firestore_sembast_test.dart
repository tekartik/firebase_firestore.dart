import 'package:sembast/sembast_memory.dart' as sembast;
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';

void main() {
  // needed for memory
  skipConcurrentTransactionTests = true;

  var firebase = FirebaseLocal();
  var firestoreService = newFirestoreServiceSembast(
      databaseFactory: sembast.newDatabaseFactoryMemory());
  runFirestoreTests(firebase: firebase, firestoreService: firestoreService);
}
