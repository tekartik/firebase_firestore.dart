import 'package:sembast_web/sembast_web.dart';
import 'package:tekartik_firebase_firestore_sembast/src/firestore_sembast.dart';

FirestoreServiceSembast? _firestoreServiceSembastWeb;

FirestoreServiceSembast get firestoreServiceSembastWeb =>
    _firestoreServiceSembastWeb ??= FirestoreServiceSembast(databaseFactoryWeb);
