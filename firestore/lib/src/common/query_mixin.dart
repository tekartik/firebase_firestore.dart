import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/firestore_common.dart';

mixin QueryMixin implements Query {
  QueryInfo queryInfo;

  QueryMixin clone();

  @override
  Query where(
    String fieldPath, {
    dynamic isEqualTo,
    dynamic isLessThan,
    dynamic isLessThanOrEqualTo,
    dynamic isGreaterThan,
    dynamic isGreaterThanOrEqualTo,
    dynamic arrayContains,
    bool isNull,
  }) =>
      clone()
        ..queryInfo.addWhere(WhereInfo(fieldPath,
            isEqualTo: isEqualTo,
            isLessThan: isLessThan,
            isLessThanOrEqualTo: isLessThanOrEqualTo,
            isGreaterThan: isGreaterThan,
            isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
            arrayContains: arrayContains,
            isNull: isNull));

  void addOrderBy(String key, String directionStr) {
    var orderBy = OrderByInfo(
        fieldPath: key, ascending: directionStr != orderByDescending);
    queryInfo.orderBys.add(orderBy);
  }

  @override
  Query startAt({DocumentSnapshot snapshot, List values}) =>
      clone()..queryInfo.startAt(snapshot: snapshot, values: values);

  @override
  Query startAfter({DocumentSnapshot snapshot, List values}) =>
      clone()..queryInfo.startAfter(snapshot: snapshot, values: values);

  @override
  Query endAt({DocumentSnapshot snapshot, List values}) =>
      clone()..queryInfo.endAt(snapshot: snapshot, values: values);

  @override
  Query endBefore({DocumentSnapshot snapshot, List values}) =>
      clone()..queryInfo.endBefore(snapshot: snapshot, values: values);

  @override
  Query select(List<String> list) {
    return clone()..queryInfo.selectKeyPaths = list;
  }

  @override
  Query limit(int limit) => clone()..queryInfo.limit = limit;

  @override
  Query orderBy(String key, {bool descending}) => clone()
    ..addOrderBy(
        key, descending == true ? orderByDescending : orderByAscending);
}
