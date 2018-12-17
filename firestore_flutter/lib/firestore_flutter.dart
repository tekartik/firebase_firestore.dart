import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_flutter/src/firestore_flutter.dart'
    as firestore_flutter;

FirestoreService get firestoreServiceFlutter =>
    firestore_flutter.firestoreService;
FirestoreService get firestoreService => firestoreServiceFlutter;
