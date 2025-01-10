/// AggregateField is used to specify the fields to include in the result set
abstract class AggregateField {
  /// Create a CountAggregateField object that can be used to compute
  /// the count of documents in the result set of a query.
  factory AggregateField.count() => AggregateFieldCount();

  /// Create an object that can be used to compute the sum of a specified field
  /// over a range of documents in the result set of a query.
  factory AggregateField.sum(String field) => AggregateFieldSum(field);

  /// Create an object that can be used to compute the sum of a specified field
  /// over a range of documents in the result set of a query.
  factory AggregateField.average(String field) => AggregateFieldAverage(field);
}

/// Create a CountAggregateField object that can be used to compute
/// the count of documents in the result set of a query.
class AggregateFieldCount implements AggregateField {
  @override
  String toString() => 'COUNT(*)';
}

/// Create an object that can be used to compute the sum of a specified field
/// over a range of documents in the result set of a query.
class AggregateFieldSum implements AggregateField {
  /// Create an object that can be used to compute the sum of a specified field
  AggregateFieldSum(this.field);

  /// The field to sum
  final String field;

  @override
  String toString() => 'SUM($field)';
}

/// Create an object that can be used to compute the average of a specified field
/// over a range of documents in the result set of a query.
class AggregateFieldAverage implements AggregateField {
  /// Create an object that can be used to compute the average of a specified field
  AggregateFieldAverage(this.field);

  /// The field to average
  final String field;

  @override
  String toString() => 'AVG($field)';
}
