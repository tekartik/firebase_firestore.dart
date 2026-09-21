import 'dart:async';

import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/query_iterate.dart';

/// Documents fetched per `getAll` when a join is resolved.
const firestoreQueryJoinGetAllChunkSize = 100;

/// Callback for a join iteration. Return `false` to stop.
typedef FirestoreQueryJoinRowCallback =
    FutureOr<bool> Function(FirestoreJoinRow row);

/// A row of a join iteration, see
/// [TekartikFirestoreQueryJoinExt.queryJoinIterate].
///
/// It holds both sides of the join: the document of the iterated (source)
/// query and the target document it references.
abstract class FirestoreJoinRow {
  /// The document of the iterated (source) query.
  ///
  /// Null when the iteration was started with `withSource: false`.
  DocumentSnapshot? get doc;

  /// The document of the iterated (source) query, alias for [doc].
  DocumentSnapshot? get sourceDoc => doc;

  /// The target document referenced by [targetRef].
  ///
  /// Null when [targetRef] is null, when no document exists there (which
  /// `inner: true` skips altogether), or when the iteration was started with
  /// `withTarget: false`.
  DocumentSnapshot? get targetDoc;

  /// The raw value read at the join field on the source document.
  ///
  /// Null when the source document has no value there.
  Object? get joinKey;

  /// The reference [joinKey] resolves to.
  ///
  /// Null when [joinKey] is null, or when it is not something a reference can
  /// be built from.
  DocumentReference? get targetRef;
}

class _FirestoreJoinRow implements FirestoreJoinRow {
  _FirestoreJoinRow({this.doc, this.joinKey, this.targetRef, this.targetDoc});

  @override
  final DocumentSnapshot? doc;

  @override
  DocumentSnapshot? get sourceDoc => doc;

  @override
  final Object? joinKey;

  @override
  final DocumentReference? targetRef;

  @override
  final DocumentSnapshot? targetDoc;

  @override
  String toString() => 'FirestoreJoinRow(${doc?.ref.id} -> ${targetRef?.path})';
}

/// Options for [TekartikFirestoreQueryJoinExt.queryJoinIterate] and
/// [TekartikFirestoreQueryJoinExt.findJoinRows].
class QueryJoinFindOptions {
  /// Field name, or a dot separated path for a nested field, whose value is
  /// resolved to a target reference.
  ///
  /// The value found there is resolved to a reference:
  /// - a [DocumentReference] is used as is;
  /// - a [String] is a document id inside [targetCollection], or, when
  ///   [targetCollection] is null, the full path of a document.
  final String joinField;

  /// Optional collection reference used to resolve document ids in [joinField].
  /// When null, [joinField] can hold a full document path or a [DocumentReference].
  final CollectionReference? targetCollection;

  /// Whether to include the source document in the [FirestoreJoinRow].
  /// Defaults to `true`. When `false`, only the join field (and cursor fields)
  /// are selected from the source query if supported.
  final bool? withSource;

  /// Whether to include the target document in the [FirestoreJoinRow].
  /// Defaults to `true`. When `false`, the target document is left null
  /// and not fetched unless needed by [inner].
  final bool? withTarget;

  /// Hands out a row only for the first source document referencing each
  /// target document, the source documents with no reference counting as one.
  /// Defaults to `false`.
  final bool? distinct;

  /// When `true`, skip rows whose join field is null or points at a document
  /// that does not exist. Defaults to `false` (left join).
  final bool? inner;

  /// Page size when querying source documents.
  final int? pageSize;

  /// Creates options for a query join iteration or find.
  QueryJoinFindOptions({
    required this.joinField,
    this.targetCollection,
    this.withSource,
    this.withTarget,
    this.distinct,
    this.inner,
    this.pageSize,
  });

  /// Whether source document is requested (defaults to true).
  bool get wantSource => withSource ?? true;

  /// Whether target document is requested (defaults to true).
  bool get wantTarget => withTarget ?? true;

  /// Whether to emit distinct rows by target reference (defaults to false).
  bool get isDistinct => distinct ?? false;

  /// Whether this is an inner join (defaults to false).
  bool get isInner => inner ?? false;
}

/// Alternative alias for [QueryJoinFindOptions].
typedef QueryJoinFindOption = QueryJoinFindOptions;

/// Join extension on [Query].
///
/// The firestore counterpart of an sdb store join: the documents matching a
/// query are handed out with the document each one references, the referenced
/// documents of a whole page being fetched in one `getAll` instead of one
/// `get` each.
extension TekartikFirestoreQueryJoinExt on Query {
  /// Iterate the documents matching this query, each with the document it
  /// references according to [options].
  ///
  /// This is a left join: a document whose join field is null, or whose join
  /// field points at a document that does not exist, is still handed to
  /// [onRow] with a null [FirestoreJoinRow.targetDoc]. Pass `inner: true` in
  /// [options] to skip those rows instead.
  ///
  /// The referenced documents of a page are fetched in a single
  /// [Firestore.getAll], and a document referenced by several source
  /// documents is only fetched once for the whole iteration.
  ///
  /// [onRow] returns false to stop the iteration.
  Future<void> queryJoinIterate({
    required QueryJoinFindOptions options,
    required FirestoreQueryJoinRowCallback onRow,
  }) async {
    var wantSource = options.wantSource;
    var wantTarget = options.wantTarget;
    var isDistinct = options.isDistinct;
    var isInner = options.isInner;
    var joinField = options.joinField;
    var targetCollection = options.targetCollection;

    var sourceQuery = this;
    if (!wantSource) {
      // Only the join field (and the cursor fields) are needed.
      sourceQuery = _selectJoinFields(sourceQuery, joinField: joinField);
    }

    /// Documents already fetched, by reference path. A missing document is
    /// cached as null, a reference is very often shared by several documents.
    var cache = <String, DocumentSnapshot?>{};

    /// Reference paths already handed out, for [distinct].
    var seen = isDistinct ? <String?>{} : null;

    var pages = firestoreQueryPageStream(
      sourceQuery,
      pageSize: options.pageSize,
    );

    await for (var page in pages) {
      // Resolve every reference of the page, then fetch the ones that are not
      // known yet in one go.
      var targetRefs = <DocumentReference?>[];
      var joinKeys = <Object?>[];
      for (var doc in page) {
        var joinKey = firestoreDocumentValueAt(doc, joinField);
        joinKeys.add(joinKey);
        targetRefs.add(_targetRef(firestore, joinKey, targetCollection));
      }
      if (wantTarget || isInner) {
        await _fillCache(firestore, targetRefs, cache);
      }

      for (var i = 0; i < page.length; i++) {
        var targetRef = targetRefs[i];
        if (seen != null && !seen.add(targetRef?.path)) {
          continue;
        }
        var targetDoc = targetRef == null ? null : cache[targetRef.path];
        if (isInner && targetDoc == null) {
          continue;
        }
        var result = onRow(
          _FirestoreJoinRow(
            doc: wantSource ? page[i] : null,
            joinKey: joinKeys[i],
            targetRef: targetRef,
            targetDoc: wantTarget ? targetDoc : null,
          ),
        );
        var doContinue = result is Future<bool> ? await result : result;
        if (!doContinue) {
          return;
        }
      }
    }
  }

  /// The documents matching this query joined with the documents they
  /// reference according to [options], as a list.
  ///
  /// Same options as [queryJoinIterate], which it is built on; prefer
  /// [queryJoinIterate] when the whole result does not have to be held in
  /// memory.
  Future<List<FirestoreJoinRow>> findJoinRows({
    required QueryJoinFindOptions options,
  }) async {
    var rows = <FirestoreJoinRow>[];
    await queryJoinIterate(
      options: options,
      onRow: (row) {
        rows.add(row);
        return true;
      },
    );
    return rows;
  }
}

/// [query] returning only the fields needed to resolve the join and to page,
/// when the backend supports it.
Query _selectJoinFields(Query query, {required String joinField}) {
  if (!query.firestore.service.supportsQuerySelect) {
    return query;
  }
  var fields = <String>{
    joinField,
    // The cursor of the next page is built from them.
    ...query.orderByFields.where((field) => field != firestoreNameFieldPath),
  };
  return query.select(fields.toList());
}

/// The reference [joinKey] resolves to, null when it resolves to none.
DocumentReference? _targetRef(
  Firestore firestore,
  Object? joinKey,
  CollectionReference? targetCollection,
) {
  if (joinKey is DocumentReference) {
    return joinKey;
  }
  if (joinKey is String && joinKey.isNotEmpty) {
    if (targetCollection != null) {
      return targetCollection.doc(joinKey);
    }
    // A full document path has an even number of segments.
    var segments = joinKey.split('/');
    if (segments.length.isEven && !segments.any((part) => part.isEmpty)) {
      return firestore.doc(joinKey);
    }
  }
  return null;
}

/// Fetch the documents of [refs] that are not in [cache] yet, in one `getAll`
/// per [firestoreQueryJoinGetAllChunkSize] documents.
///
/// A document that does not exist is cached as null.
Future<void> _fillCache(
  Firestore firestore,
  List<DocumentReference?> refs,
  Map<String, DocumentSnapshot?> cache,
) async {
  var wanted = <String, DocumentReference>{};
  for (var ref in refs) {
    if (ref != null && !cache.containsKey(ref.path)) {
      wanted[ref.path] = ref;
    }
  }
  if (wanted.isEmpty) {
    return;
  }
  var toFetch = wanted.values.toList();
  for (var i = 0; i < toFetch.length; i += firestoreQueryJoinGetAllChunkSize) {
    var chunk = toFetch.sublist(
      i,
      (i + firestoreQueryJoinGetAllChunkSize).clamp(0, toFetch.length),
    );
    var snapshots = await firestore.getAll(chunk);
    for (var snapshot in snapshots) {
      cache[snapshot.ref.path] = snapshot.exists ? snapshot : null;
    }
  }
}
