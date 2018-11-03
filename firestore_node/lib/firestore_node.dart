import 'package:tekartik_firebase_firestore/firestore.dart';
import 'src/firestore_node.dart' as _;

FirestoreServiceProvider get firebaseFirestoreServiceProviderNode =>
    _.firestoreServiceProviderNode;
FirestoreServiceProvider get firestoreServiceProvider =>
    firebaseFirestoreServiceProviderNode;
FirestoreService get firestoreService => _.firestoreService;
