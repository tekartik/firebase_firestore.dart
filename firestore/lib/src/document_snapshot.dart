import 'package:tekartik_firebase_firestore/firestore.dart';

/// A DocumentSnapshot contains data read from a document in your Cloud
/// Firestore database, as returned by [DocumentReference.get] or
/// [DocumentReference.onSnapshot].
///
/// A snapshot is a point-in-time capture: it does not update itself if the
/// underlying document later changes. Always check [exists] before reading
/// [data], since [data] throws when the document does not exist.
abstract class DocumentSnapshot {
  /// The [DocumentReference] this snapshot was read from.
  DocumentReference get ref;

  /// Returns the fields of the document as a `Map<String, Object?>`.
  ///
  /// Throws if [exists] is `false`; check [exists] first, or use a helper
  /// such as `dataOrNull` for a null-safe alternative.
  Map<String, Object?> get data;

  /// Metadata about this snapshot concerning its source (cache vs. server)
  /// and whether it reflects local, not-yet-committed writes.
  SnapshotMetadata get metadata;

  /// `true` if the document existed in the database at the time this
  /// snapshot was taken.
  bool get exists;

  /// The time the document was last updated, as observed when the snapshot
  /// was generated. `null` for documents that don't exist, and may also be
  /// `null` when [FirestoreService.supportsDocumentSnapshotTime] is `false`.
  Timestamp? get updateTime;

  /// The time the document was created. `null` for documents that don't
  /// exist, and may also be `null` when
  /// [FirestoreService.supportsDocumentSnapshotTime] is `false`.
  Timestamp? get createTime;
}
