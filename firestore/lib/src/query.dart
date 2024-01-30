import 'package:meta/meta.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';

/// Sentinel value to check whether user passed values explicitly through .where() method
@internal
const notSetQueryParam = Object();

/// Represents a [Query] over the data at a particular location.
///
/// Can construct refined [Query] objects by adding filters and ordering.
abstract class Query {
  /// The [Firestore] instance of this query.
  Firestore get firestore;

  /// Execute the query.
  Future<QuerySnapshot> get();

  /// Count the number of element matching the query.
  ///
  /// Check [FirestoreService.supportsQueryCount] before use
  Future<int> count();

  /// Count the number of element matching the query.
  ///
  /// Check [FirestoreService.supportsQueryCount] before use
  Stream<int> onCount();

  Stream<QuerySnapshot> onSnapshot({bool includeMetadataChanges = false});

  /// Creates and returns a new Query that's additionally limited to only return up
  /// to the specified number of documents.
  Query limit(int limit);

  /// Multiple orders by can be used.
  Query orderBy(String key, {bool? descending});

  /// No other orderBy can be used after orderById.
  Query orderById({bool? descending});

  /// Select the retrieved fields (if supported).
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

  /// Creates and returns a new [Query] with additional filter on specified
  /// [fieldPath]. [fieldPath] refers to a field in a document or a [Filter] object.
  ///
  /// The [fieldPath] is a [String] consisting of a single field name
  /// (referring to a top level field in the document),
  /// a series of field names separated by dots '.'
  /// (referring to a nested field in the document),
  ///
  /// Only documents satisfying provided condition are included in the result
  /// set.
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

  /// Calculates the specified aggregations over the documents in the
  /// result set of the given query, without actually downloading the documents.
  AggregateQuery aggregate(List<AggregateField> aggregateFields);
}
