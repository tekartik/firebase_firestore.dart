import 'package:tekartik_firebase_firestore/firestore.dart';

/// A DocumentSnapshot contains data read from a document in your Cloud
/// Firestore database.
abstract class DocumentSnapshot {
  /// Gets the reference to the document.
  DocumentReference get ref;

  /// Returns the fields of the document as a Map, throw if it does not exist.
  Map<String, Object?> get data;

  /// Metadata about this document concerning its source and if it has local
  /// modifications.
  SnapshotMetadata get metadata;

  /// true if the document existed in this snapshot.
  bool get exists;

  /// The time the document was last updated (at the time the snapshot was
  /// generated). Not set for documents that don't exist.
  Timestamp? get updateTime;

  /// The time the document was created. Not set for documents that don't
  /// exist.
  Timestamp? get createTime;
}
