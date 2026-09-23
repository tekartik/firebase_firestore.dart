import 'package:tekartik_firebase_firestore/firestore.dart';

/// Options for [CollectionReference.listDocuments].
class FirestoreListDocumentsOptions {
  /// The maximum number of documents to return, `null` to return all of
  /// them. Must be positive.
  final int? pageSize;

  /// The [FirestoreListDocumentsResult.nextPageToken] of a previous call, to
  /// get the next page.
  final String? pageToken;

  /// `true` (the default) to also list the "missing" documents (without data
  /// but with sub-collections), when
  /// [FirestoreService.supportsListMissingDocuments] is `true`.
  ///
  /// When `false`, only the documents returned by [Query.get] are listed.
  final bool showMissing;

  /// Creates options for [CollectionReference.listDocuments].
  const FirestoreListDocumentsOptions({
    this.pageSize,
    this.pageToken,
    this.showMissing = true,
  }) : assert(pageSize == null || pageSize > 0, 'pageSize must be positive');

  @override
  String toString() => {
    'pageSize': ?pageSize,
    'pageToken': ?pageToken,
    if (!showMissing) 'showMissing': showMissing,
  }.toString();
}

/// Result of [CollectionReference.listDocuments].
class FirestoreListDocumentsResult {
  /// The references of the listed documents.
  final List<DocumentReference> refs;

  /// The token to pass as [FirestoreListDocumentsOptions.pageToken] to get
  /// the next page, `null` if there are no more documents.
  ///
  /// A page might hold fewer documents than the requested
  /// [FirestoreListDocumentsOptions.pageSize] (even none) while more
  /// documents remain, only this token tells whether there are more.
  final String? nextPageToken;

  /// Creates a result.
  FirestoreListDocumentsResult({required this.refs, this.nextPageToken});

  @override
  String toString() => {
    'refs': refs.map((ref) => ref.path).toList(),
    'nextPageToken': ?nextPageToken,
  }.toString();
}
