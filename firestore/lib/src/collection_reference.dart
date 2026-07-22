import 'package:tekartik_firebase_firestore/firestore.dart';

/// A reference to a collection location in Firestore, obtained through
/// [Firestore.collection] or [DocumentReference.collection].
///
/// A [CollectionReference] is also a [Query] matching every document in the
/// collection, so it supports the same `where`/`orderBy`/`limit`/etc.
/// refinement methods.
abstract class CollectionReference extends Query {
  /// The full, slash-separated path to this collection, for example
  /// `'users'` or `'users/123/posts'`.
  String get path;

  /// The last segment of [path]: the collection's id within its parent
  /// document.
  String get id;

  /// The document this collection is nested under, or `null` if this is a
  /// root collection.
  DocumentReference? get parent;

  /// Gets a [DocumentReference] for the document at [path], relative to this
  /// collection.
  ///
  /// The reference is returned even if no document currently exists at that
  /// path.
  DocumentReference doc(String path);

  /// Adds a new document with the given [data] and an auto-generated id to
  /// this collection.
  ///
  /// The returned `Future` completes with a [DocumentReference] pointing to
  /// the newly created document once the write has been committed.
  Future<DocumentReference> add(Map<String, Object?> data);
}
