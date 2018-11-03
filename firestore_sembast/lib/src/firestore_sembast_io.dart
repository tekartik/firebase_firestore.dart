import 'package:sembast/sembast_io.dart';
import 'package:tekartik_firebase_firestore_sembast/src/firestore_sembast.dart';

//TODO remote
FirestoreServiceProviderSembast _firestoreServiceProviderSembastIo;

//TODO remote
FirestoreServiceProviderSembast get firestoreServiceProviderSembastIo =>
    _firestoreServiceProviderSembastIo ??
    FirestoreServiceProviderSembast(databaseFactory: databaseFactoryIo);

FirestoreServiceSembast _firestoreServiceSembastIo;

FirestoreServiceSembast get firestoreServiceSembastIo =>
    _firestoreServiceSembastIo ??= FirestoreServiceSembast(databaseFactoryIo);
