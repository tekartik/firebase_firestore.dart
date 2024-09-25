import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_sembast/src/firestore_sembast_web.dart'
    as firestore_sembast_web;
export 'firestore_sembast.dart';

/// Firestore service for web based on sembast web
FirestoreService get firestoreServiceWeb =>
    firestore_sembast_web.firestoreServiceSembastWeb;
