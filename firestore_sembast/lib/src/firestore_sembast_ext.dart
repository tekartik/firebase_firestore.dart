import 'package:sembast/sembast.dart' as smb;
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_sembast/src/firestore_sembast.dart';

extension TekartikFirestoreSembastPrvExt on Firestore {
  /// Get the sembast firstore implementation
  FirestoreSembast get firestoreSembast => this as FirestoreSembast;
}

/// Public extension
extension TekartikFirestoreSembastExt on Firestore {
  /// Get the sembast database
  Future<smb.Database> get sembastDatabase => firestoreSembast.ready;
}

/// Public extension
extension TekartikFirestoreServiceSembastExt on FirestoreService {
  /// Only for FirestoreServiceSembast
  set sembastSupportsTrackChanges(bool value) {
    TekartikFirestoreServiceSembastPrvExt(this as FirestoreServiceSembast)
        .supportsTrackChanges = value;
  }
}
