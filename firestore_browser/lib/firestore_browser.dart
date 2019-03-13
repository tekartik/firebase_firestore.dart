import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_browser/src/firestore_browser.dart'
    as firestore_browser;

FirestoreService get firestoreService => firestoreServiceBrowser;
FirestoreService get firestoreServiceBrowser =>
    firestore_browser.firestoreService;
