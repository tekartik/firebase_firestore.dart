import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_browser/src/firestore_browser_impl.dart'
    as firestore_browser;

/// Firestore service on the web
FirestoreService get firestoreServiceBrowser =>
    firestore_browser.firestoreService;
