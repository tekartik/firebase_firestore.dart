import 'aggregate_query_snapshot.dart';

abstract class AggregateQuery {
  /// Returns an [AggregateQuerySnapshot] with the count of the documents that match the query.
  Future<AggregateQuerySnapshot> get();
}
