import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/firestore_common.dart';

// Every implementation should use this default mixin for missing implementation
mixin FirestoreQueryExecutorMixin implements Query {
  /// Expensive default implementation.
  @override
  Future<int> count() async {
    return (await get()).docs.length;
  }

  /// Expensive default implementation.
  @override
  Stream<int> onCount() => onSnapshot().map((snapshot) => snapshot.docs.length);

  @override
  Query orderById({bool? descending}) =>
      orderBy(firestoreNameFieldPath, descending: descending);
}

// Common mixin, no executor for non firestore native implementation
mixin QueryMixin implements Query {
  late QueryInfo queryInfo;

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
    List<Object>? arrayContainsAny,
    List<Object>? whereIn,
    bool? isNull,
  }) =>
      clone()
        ..queryInfo.addWhere(WhereInfo(fieldPath,
            isEqualTo: isEqualTo,
            isLessThan: isLessThan,
            isLessThanOrEqualTo: isLessThanOrEqualTo,
            isGreaterThan: isGreaterThan,
            isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
            arrayContains: arrayContains,
            arrayContainsAny: arrayContainsAny,
            whereIn: whereIn,
            isNull: isNull));

  void addOrderBy(String key, String directionStr) {
    var orderBy = OrderByInfo(
        fieldPath: key, ascending: directionStr != orderByDescending);
    queryInfo.orderBys.add(orderBy);
  }

  @override
  Query startAt({DocumentSnapshot? snapshot, List? values}) =>
      clone()..queryInfo.startAt(snapshot: snapshot, values: values);

  @override
  Query startAfter({DocumentSnapshot? snapshot, List? values}) =>
      clone()..queryInfo.startAfter(snapshot: snapshot, values: values);

  @override
  Query endAt({DocumentSnapshot? snapshot, List? values}) =>
      clone()..queryInfo.endAt(snapshot: snapshot, values: values);

  @override
  Query endBefore({DocumentSnapshot? snapshot, List? values}) =>
      clone()..queryInfo.endBefore(snapshot: snapshot, values: values);

  @override
  Query select(List<String> list) {
    return clone()..queryInfo.selectKeyPaths = list;
  }

  @override
  Query limit(int limit) => clone()..queryInfo.limit = limit;

  @override
  Query orderBy(String key, {bool? descending}) => clone()
    ..addOrderBy(
        key, descending == true ? orderByDescending : orderByAscending);
}

/// Apply query info to query/collection
Future<Query> applyQueryInfo(
    Firestore firestore, String path, QueryInfo? queryInfo) async {
  Query query = firestore.collection(path);
  if (queryInfo != null) {
    if (queryInfo.selectKeyPaths != null) {
      query = query.select(queryInfo.selectKeyPaths!);
    }
    // limit
    if (queryInfo.limit != null) {
      query = query.limit(queryInfo.limit!);
    }

    // order
    for (var orderBy in queryInfo.orderBys) {
      query = query.orderBy(orderBy.fieldPath!, descending: !orderBy.ascending);
    }

    for (var where in queryInfo.wheres) {
      query = query.where(where.fieldPath,
          isEqualTo: where.isEqualTo,
          isGreaterThan: where.isGreaterThan,
          whereIn: where.whereIn,
          arrayContains: where.arrayContains,
          arrayContainsAny: where.arrayContainsAny,
          isGreaterThanOrEqualTo: where.isGreaterThanOrEqualTo,
          isLessThan: where.isLessThan,
          isNull: where.isNull,
          isLessThanOrEqualTo: where.isLessThanOrEqualTo);
    }

    if (queryInfo.startLimit != null) {
      // get it
      DocumentSnapshot? snapshot;
      if (queryInfo.startLimit!.documentId != null) {
        snapshot = await firestore
            .collection(path)
            .doc(queryInfo.startLimit!.documentId!)
            .get();
      }
      if (queryInfo.startLimit!.inclusive) {
        query = query.startAt(
            snapshot: snapshot, values: queryInfo.startLimit!.values);
      } else {
        query = query.startAfter(
            snapshot: snapshot, values: queryInfo.startLimit!.values);
      }
    }
    if (queryInfo.endLimit != null) {
      // get it
      DocumentSnapshot? snapshot;
      if (queryInfo.endLimit!.documentId != null) {
        snapshot = await firestore
            .collection(path)
            .doc(queryInfo.endLimit!.documentId!)
            .get();
      }
      if (queryInfo.endLimit!.inclusive) {
        query =
            query.endAt(snapshot: snapshot, values: queryInfo.endLimit!.values);
      } else {
        query = query.endBefore(
            snapshot: snapshot, values: queryInfo.endLimit!.values);
      }
    }
  }
  return query;
}
