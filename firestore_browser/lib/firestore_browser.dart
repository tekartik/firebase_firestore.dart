import 'package:tekartik_firebase_firestore/firestore.dart';
import 'src/firestore_browser.dart' as _;

FirestoreServiceProvider get firebaseFirestoreServiceProviderBrowser =>
    _.firebaseFirestoreServiceProviderBrowser;
FirestoreServiceProvider get firestoreServiceProvider =>
    firebaseFirestoreServiceProviderBrowser;
