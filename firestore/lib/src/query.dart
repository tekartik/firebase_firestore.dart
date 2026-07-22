import 'package:meta/meta.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';

/// Sentinel value to check whether user passed values explicitly through .where() method
@internal
const notSetQueryParam = Object();

/// Represents a [Query] over the data at a particular location.
///
/// Can construct refined [Query] objects by adding filters and ordering.
/// Every method that refines the query (`where`, `orderBy`, `limit`,
/// `select`, `startAt`/`startAfter`/`endAt`/`endBefore`) returns a *new*
/// [Query] instance; the original query is left unmodified.
abstract class Query {
  /// The [Firestore] instance this query runs against.
  Firestore get firestore;

  /// Executes the query and fetches the matching documents.
  ///
  /// The returned `Future` completes with a [QuerySnapshot] holding the
  /// matching documents, or an empty [QuerySnapshot] if none match.
  Future<QuerySnapshot> get();

  /// Counts the number of documents matching the query without downloading
  /// their content.
  ///
  /// Check [FirestoreService.supportsAggregateQueries] before use; use
  /// [aggregate] with [AggregateField.count] for a lower-level equivalent.
  Future<int> count();

  /// Notifies of the number of documents matching the query, similarly to
  /// [count] but as a live stream.
  ///
  /// An initial event is sent as soon as the count is available, and further
  /// events are sent whenever it changes. The stream stays open until its
  /// subscription is cancelled.
  Stream<int> onCount();

  /// Notifies of the documents matching the query.
  ///
  /// An initial event with the current matching documents is sent as soon as
  /// it is available, and further events are sent whenever the result set
  /// changes. When [includeMetadataChanges] is `true`, additional events are
  /// also sent purely for metadata changes (see [SnapshotMetadata]). The
  /// stream stays open until its subscription is cancelled.
  Stream<QuerySnapshot> onSnapshot({bool includeMetadataChanges = false});

  /// Creates and returns a new [Query] that's additionally limited to only
  /// return up to [limit] documents.
  Query limit(int limit);

  /// Creates and returns a new [Query] additionally sorted by the field at
  /// [key], ascending unless [descending] is `true`.
  ///
  /// Multiple `orderBy` calls can be chained to sort by several fields; the
  /// order in which they are applied determines sort priority.
  Query orderBy(String key, {bool? descending});

  /// Creates and returns a new [Query] additionally sorted by document id,
  /// ascending unless [descending] is `true`.
  ///
  /// No other `orderBy` can be used after `orderById`.
  Query orderById({bool? descending});

  /// Creates and returns a new [Query] that only returns the fields listed
  /// in [keyPaths] for each matching document, if supported by the backend.
  ///
  /// Check [FirestoreService.supportsQuerySelect] before relying on this;
  /// when unsupported, the full document is returned regardless.
  Query select(List<String> keyPaths);

  /// Takes a list of [values], creates and returns a new [Query] that starts at
  /// the provided fields relative to the order of the query.
  ///
  /// The [values] must be in order of [orderBy] filters.
  ///
  /// Calling this method will replace any existing cursor "start" query modifiers.
  Query startAt({DocumentSnapshot? snapshot, List<Object?>? values});

  /// Takes a list of [values], creates and returns a new [Query] that starts
  /// after the provided fields relative to the order of the query.
  ///
  /// The [values] must be in order of [orderBy] filters.
  ///
  /// Calling this method will replace any existing cursor "start" query modifiers.
  Query startAfter({DocumentSnapshot? snapshot, List<Object?>? values});

  /// Takes a list of [values], creates and returns a new [Query] that ends at the
  /// provided fields relative to the order of the query.
  ///
  /// The [values] must be in order of [orderBy] filters.
  ///
  /// Calling this method will replace any existing cursor "end" query modifiers.
  Query endAt({DocumentSnapshot? snapshot, List<Object?>? values});

  /// Takes a list of [values], creates and returns a new [Query] that ends before
  /// the provided fields relative to the order of the query.
  ///
  /// The [values] must be in order of [orderBy] filters.
  ///
  /// Calling this method will replace any existing cursor "end" query modifiers.
  Query endBefore({DocumentSnapshot? snapshot, List<Object?>? values});

  /// Creates and returns a new [Query] with an additional filter on the
  /// field at [fieldPath].
  ///
  /// [fieldPath] is a [String] consisting of a single field name (referring
  /// to a top level field in the document), or a series of field names
  /// separated by dots `.` (referring to a nested field in the document).
  ///
  /// Exactly one of the comparison parameters should be provided to describe
  /// the condition to apply; only documents satisfying it are included in
  /// the result set:
  /// - [isEqualTo]: the field must equal this value.
  /// - [isLessThan] / [isLessThanOrEqualTo]: the field must be less than
  ///   (or equal to) this value.
  /// - [isGreaterThan] / [isGreaterThanOrEqualTo]: the field must be greater
  ///   than (or equal to) this value.
  /// - [arrayContains]: the field, an array, must contain this value.
  /// - [arrayContainsAny]: the field, an array, must contain at least one
  ///   value from this non-empty list.
  /// - [whereIn]: the field must equal one of the values in this non-empty
  ///   list.
  /// - [isNull]: when `true`, the field must be `null`; when `false`, the
  ///   field must be non-`null`.
  Query where(
    String fieldPath, {
    dynamic isEqualTo,
    dynamic isLessThan,
    dynamic isLessThanOrEqualTo,
    dynamic isGreaterThan,
    dynamic isGreaterThanOrEqualTo,
    dynamic arrayContains,
    List<Object>? arrayContainsAny,
    List<Object>? whereIn,
    bool? isNull,
  });

  /// Calculates the specified [aggregateFields] (count, sum, average) over
  /// the documents in the result set of this query, without actually
  /// downloading the documents.
  ///
  /// Check [FirestoreService.supportsAggregateQueries] before use. Call
  /// [AggregateQuery.get] on the returned object to run the computation.
  AggregateQuery aggregate(List<AggregateField> aggregateFields);
}
