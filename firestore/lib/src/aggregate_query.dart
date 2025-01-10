import 'aggregate_query_snapshot.dart';

/// An interface that defines an aggregate query.
abstract class AggregateQuery {
  /// Returns an [AggregateQuerySnapshot] with the count of the documents that match the query.
  Future<AggregateQuerySnapshot> get();
}
