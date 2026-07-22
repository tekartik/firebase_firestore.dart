import 'package:tekartik_firebase_firestore/firestore.dart';

/// A reference to a document location in Firestore.
///
/// A [DocumentReference] can be used to read, write, delete and listen to a
/// document, and does not necessarily require that the document exists. It
/// is obtained through [Firestore.doc], [CollectionReference.doc] or
/// [CollectionReference.add], and never performs network or storage access
/// by itself; use [get] to read the document's current data.
abstract class DocumentReference {
  /// The [Firestore] instance this document reference belongs to.
  Firestore get firestore;

  /// The last segment of [path]: the document's id within its parent
  /// collection.
  String get id;

  /// The full, slash-separated path to this document, for example
  /// `'users/123'`.
  String get path;

  /// The [CollectionReference] this document belongs to. Never `null`: every
  /// document has a parent collection.
  CollectionReference get parent;

  /// Gets a [CollectionReference] for the sub-collection at [path], relative
  /// to this document.
  CollectionReference collection(String path);

  /// Deletes the document referred to by this [DocumentReference].
  ///
  /// The returned `Future` completes once the delete has been committed.
  /// Deleting a document that does not exist normally succeeds without
  /// error.
  Future<void> delete();

  /// Reads the current content of the document.
  ///
  /// The returned `Future` completes with a [DocumentSnapshot] whose
  /// [DocumentSnapshot.exists] is `false` when the document does not exist.
  Future<DocumentSnapshot> get();

  /// Writes [data] to the document referred to by this [DocumentReference].
  ///
  /// If the document does not yet exist, it will be created. If [options]
  /// is passed with [SetOptions.merge] set to `true`, [data] is merged into
  /// the existing document instead of replacing it. The returned `Future`
  /// completes once the write has been committed.
  Future<void> set(Map<String, Object?> data, [SetOptions? options]);

  /// Updates fields in the document referred to by this [DocumentReference]
  /// with [data].
  ///
  /// The returned `Future` completes once the write has been committed, or
  /// with an error if the update is applied to a document that does not
  /// exist.
  Future<void> update(Map<String, Object?> data);

  /// Notifies of document updates at this location.
  ///
  /// An initial event with the document's current content is sent as soon
  /// as it is available, and further events are sent whenever the document
  /// is modified (created, updated or deleted). When [includeMetadataChanges]
  /// is `true`, additional events are also sent purely for metadata changes
  /// (see [SnapshotMetadata]). The stream stays open until its subscription
  /// is cancelled.
  Stream<DocumentSnapshot> onSnapshot({bool includeMetadataChanges = false});

  /// Lists the sub-collections directly under this document, if supported
  /// by the backend.
  ///
  /// Returns an empty list if there are none. Check
  /// [FirestoreService.supportsListCollections] before calling this method;
  /// implementations that don't support it throw.
  Future<List<CollectionReference>> listCollections();
}

/// Helper extension for working with a list of [DocumentReference]s.
extension DocumentReferenceListExtension on List<DocumentReference> {
  /// The [DocumentReference.id] of each element, in the same order.
  List<String> get ids => map((e) => e.id).toList(growable: false);
}
