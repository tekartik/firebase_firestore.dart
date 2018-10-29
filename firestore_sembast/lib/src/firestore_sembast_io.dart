import 'package:sembast/sembast_io.dart';
import 'package:tekartik_firebase_firestore_sembast/src/firestore_sembast.dart';

FirestoreServiceProviderSembast _firebaseFirestoreSembastProviderIo;

FirestoreServiceProviderSembast get firebaseFirestoreSembastProviderIo =>
    _firebaseFirestoreSembastProviderIo ??
    FirestoreServiceProviderSembast(databaseFactory: databaseFactoryIo);
