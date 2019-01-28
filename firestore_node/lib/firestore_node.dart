import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_node/src/firestore_node.dart'
    as firestore_node;

FirestoreService get firestoreService => firestoreServiceNode;
FirestoreService get firestoreServiceNode => firestore_node.firestoreService;
