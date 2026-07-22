/// Describes a single aggregation (count, sum or average) to compute over
/// the result set of a [Query], as passed to [Query.aggregate].
abstract class AggregateField {
  /// Creates an [AggregateField] that computes the count of documents in
  /// the result set of a query.
  factory AggregateField.count() => AggregateFieldCount();

  /// Creates an [AggregateField] that computes the sum of the numeric values
  /// of [field] over the documents in the result set of a query.
  ///
  /// [field] is the field path whose values are summed; documents where it
  /// is missing or non-numeric do not contribute to the sum.
  factory AggregateField.sum(String field) => AggregateFieldSum(field);

  /// Creates an [AggregateField] that computes the average of the numeric
  /// values of [field] over the documents in the result set of a query.
  ///
  /// [field] is the field path whose values are averaged; documents where it
  /// is missing or non-numeric do not contribute to the average.
  factory AggregateField.average(String field) => AggregateFieldAverage(field);
}

/// An [AggregateField] that computes the count of documents in the result
/// set of a query. Create one through [AggregateField.count].
class AggregateFieldCount implements AggregateField {
  @override
  String toString() => 'COUNT(*)';
}

/// An [AggregateField] that computes the sum of a field's numeric values
/// over the result set of a query. Create one through [AggregateField.sum].
class AggregateFieldSum implements AggregateField {
  /// Creates an [AggregateFieldSum] summing the values of [field].
  AggregateFieldSum(this.field);

  /// The field path whose values are summed.
  final String field;

  @override
  String toString() => 'SUM($field)';
}

/// An [AggregateField] that computes the average of a field's numeric values
/// over the result set of a query. Create one through
/// [AggregateField.average].
class AggregateFieldAverage implements AggregateField {
  /// Creates an [AggregateFieldAverage] averaging the values of [field].
  AggregateFieldAverage(this.field);

  /// The field path whose values are averaged.
  final String field;

  @override
  String toString() => 'AVG($field)';
}
