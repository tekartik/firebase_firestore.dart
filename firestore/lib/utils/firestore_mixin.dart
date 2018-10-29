import 'package:tekartik_firebase_firestore/firestore.dart';

// might evolve to be always true
bool firestoreTimestampsInSnapshots(Firestore firestore) {
  if (firestore is FirestoreMixin) {
    return firestore.firestoreSettings?.timestampsInSnapshots == true;
  }
  return false;
}

abstract class FirestoreMixin implements Firestore {
  FirestoreSettings firestoreSettings;

  @override
  void settings(FirestoreSettings settings) {
    if (this.firestoreSettings != null) {
      throw StateError(
          'firestore settings already set to $firestoreSettings cannot set to $settings');
    }
    this.firestoreSettings = settings;
  }
}
