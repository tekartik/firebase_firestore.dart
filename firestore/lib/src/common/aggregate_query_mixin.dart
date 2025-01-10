import 'package:tekartik_firebase_firestore/src/common/import_firestore_mixin.dart';

/// For non native firestore implementation, we need to create a new class.
mixin AggregateQueryMixin implements AggregateQuery {
  /// The query that produced this snapshot.
  late QueryInfo queryInfo;

  /// The list of fields to aggregate.
  late List<AggregateField> aggregateFields;

  @override
  String toString() {
    return 'AggregateQueryImpl(query: $queryInfo, aggregateFields: $aggregateFields)';
  }
}
