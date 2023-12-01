import 'package:tekartik_firebase_firestore/firestore.dart';

/// Collection reference.
abstract class CollectionReference extends Query {
  /// Collection path.
  String get path;

  /// Collection id.
  String get id;

  /// Parent document.
  DocumentReference? get parent;

  /// Get child document.
  DocumentReference doc(String path);

  /// Add a document.
  Future<DocumentReference> add(Map<String, Object?> data);
}
