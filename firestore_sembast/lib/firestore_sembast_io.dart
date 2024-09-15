import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_sembast/src/firestore_sembast_io.dart'
    as firestore_sembast_io;

/// Firestore service for io based on sembast io
FirestoreService get firestoreServiceIo =>
    firestore_sembast_io.firestoreServiceSembastIo;
