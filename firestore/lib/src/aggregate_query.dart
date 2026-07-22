import 'aggregate_query_snapshot.dart';

/// An aggregation (count, sum, average, ...) to run over the result set of a
/// [Query], as created by [Query.aggregate].
abstract class AggregateQuery {
  /// Executes the aggregation on the backend and returns its result.
  ///
  /// The returned `Future` completes with an [AggregateQuerySnapshot] holding
  /// the computed value(s) for each requested [AggregateField], without the
  /// matching documents themselves ever being downloaded.
  Future<AggregateQuerySnapshot> get();
}
