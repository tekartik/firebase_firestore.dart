import 'package:tekartik_firebase_firestore/firestore.dart';

/// Represents the response to an [AggregateQuery] request, as returned by
/// [AggregateQuery.get].
abstract class AggregateQuerySnapshot {
  /// The [Query] whose result set was aggregated to produce this snapshot.
  Query get query;

  /// The count of the documents that matched the query, or `null` if
  /// [AggregateField.count] was not one of the requested aggregations.
  int? get count;

  /// The sum of the values of [field] over the documents that matched the
  /// query, or `null` if [AggregateField.sum] was not requested for [field].
  double? getSum(String field);

  /// The average of the values of [field] over the documents that matched
  /// the query, or `null` if [AggregateField.average] was not requested for
  /// [field].
  double? getAverage(String field);
}
