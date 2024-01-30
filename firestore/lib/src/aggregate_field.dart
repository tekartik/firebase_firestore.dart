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
class AggregateFieldCount implements AggregateField {}

/// Create an object that can be used to compute the sum of a specified field
/// over a range of documents in the result set of a query.
class AggregateFieldSum implements AggregateField {
  AggregateFieldSum(this.field);

  final String field;
}

/// Create an object that can be used to compute the average of a specified field
/// over a range of documents in the result set of a query.
// ignore: camel_case_types
class AggregateFieldAverage implements AggregateField {
  AggregateFieldAverage(this.field);

  final String field;
}
