import 'package:tekartik_firebase_firestore/firestore.dart';

/// Firestore service on the web
FirestoreService get firestoreServiceBrowser =>
    _stub('firestoreServiceBrowser supported on the web only');

T _stub<T>(String message) {
  throw UnimplementedError(message);
}
