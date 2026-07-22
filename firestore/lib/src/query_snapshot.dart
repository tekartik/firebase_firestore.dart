import 'package:tekartik_firebase_firestore/firestore.dart';

/// The result of executing a [Query], as returned by [Query.get] or
/// [Query.onSnapshot].
abstract class QuerySnapshot {
  /// The documents currently matching the query, in the order defined by the
  /// query (or backend-defined order if none was specified). Empty if no
  /// document matches.
  List<DocumentSnapshot> get docs;

  /// The documents that changed since the previous snapshot delivered by the
  /// same [Query.onSnapshot] stream. If this is the first snapshot, all
  /// documents in [docs] are reported here as [DocumentChangeType.added]
  /// changes.
  List<DocumentChange> get documentChanges;
}

/// Helper extension exposing document references and ids for a
/// [QuerySnapshot].
extension QuerySnapshotExtension on QuerySnapshot {
  /// The [DocumentReference] of each document in [QuerySnapshot.docs], in
  /// the same order.
  List<DocumentReference> get refs =>
      docs.map((e) => e.ref).toList(growable: false);

  /// The [DocumentReference.id] of each document in [QuerySnapshot.docs], in
  /// the same order.
  List<String> get ids => refs.map((e) => e.id).toList(growable: false);
}
