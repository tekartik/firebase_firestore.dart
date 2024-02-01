import 'package:tekartik_firebase_firestore/firestore.dart';

/// [AggregateQuerySnapshot] represents a response to an [AggregateQuery] request.
///
abstract class AggregateQuerySnapshot {
  Query get query;

  /// Returns the count of the documents that match the query. if asked
  int? get count;

  /// Returns the sum of the values of the documents that match the query.
  double? getSum(String field);

  /// Returns the average of the values of the documents that match the query.
  double? getAverage(String field);
}
