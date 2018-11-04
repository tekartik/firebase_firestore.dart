import 'package:tekartik_firebase_firestore/firestore.dart';
import 'src/firestore_flutter.dart' as _;

FirestoreServiceProvider get firebaseFirestoreServiceProviderFlutter =>
    _.firestoreServiceProviderFlutter;
FirestoreServiceProvider get firestoreServiceProvider =>
    firebaseFirestoreServiceProviderFlutter;
