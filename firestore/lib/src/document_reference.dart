import 'package:tekartik_firebase_firestore/firestore.dart';

/// Document reference.
abstract class DocumentReference {
  /// The Firestore instance associated with this document reference.
  Firestore get firestore;

  /// Document id.
  String get id;

  /// Document path
  String get path;

  /// Parent collection, never null.
  CollectionReference get parent;

  /// Get a child collection.
  CollectionReference collection(String path);

  /// Delete a document.
  Future<void> delete();

  /// Get a document.
  Future<DocumentSnapshot> get();

  /// Set the document to the given data.
  Future<void> set(Map<String, Object?> data, [SetOptions? options]);

  /// Update the document with the given data.
  Future<void> update(Map<String, Object?> data);

  /// Notifies of document updates at this location.
  ///
  /// An initial event is immediately sent, and further events will be
  /// sent whenever the document is modified.
  Stream<DocumentSnapshot> onSnapshot({bool includeMetadataChanges = false});

  /// If supported list sub collections
  Future<List<CollectionReference>> listCollections();
}

/// Common helpers.
extension DocumentReferenceListExtension on List<DocumentReference> {
  /// Document reference ids.
  List<String> get ids => map((e) => e.id).toList(growable: false);
}
