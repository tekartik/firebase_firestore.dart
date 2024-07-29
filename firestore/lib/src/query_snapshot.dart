import 'package:tekartik_firebase_firestore/firestore.dart';

abstract class QuerySnapshot {
  List<DocumentSnapshot> get docs;

  /// An array of the documents that changed since the last snapshot. If this
  /// is the first snapshot, all documents will be in the list as Added changes.
  List<DocumentChange> get documentChanges;
}

/// Common helpers.
extension QuerySnapshotExtension on QuerySnapshot {
  /// Document reference list.
  List<DocumentReference> get refs =>
      docs.map((e) => e.ref).toList(growable: false);

  /// Document reference ids.
  List<String> get ids => refs.map((e) => e.id).toList(growable: false);
}
