import 'package:sembast/sembast_io.dart';
import 'package:tekartik_firebase_firestore_sembast/src/firestore_sembast.dart';

FirestoreServiceSembast _firestoreServiceSembastIo;

FirestoreServiceSembast get firestoreServiceSembastIo =>
    _firestoreServiceSembastIo ??= FirestoreServiceSembast(databaseFactoryIo);
