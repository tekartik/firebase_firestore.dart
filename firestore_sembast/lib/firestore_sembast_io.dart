import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_sembast/src/firestore_sembast_io.dart'
    as _;

FirestoreServiceProvider get firebaseFirestoreServiceProviderSembastIo =>
    _.firestoreServiceProviderSembastIo;
FirestoreServiceProvider get firestoreServiceProvider =>
    firebaseFirestoreServiceProviderSembastIo;
