import 'package:sembast/sembast.dart' as smb;
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_sembast/src/firestore_sembast.dart';

extension TekartikFirestoreSembastPrvExt on Firestore {
  FirestoreSembast get firestoreSembast => this as FirestoreSembast;
}

/// Public extension
extension TekartikFirestoreSembastExt on Firestore {
  Future<smb.Database> get sembastDatabase => firestoreSembast.ready;
}
