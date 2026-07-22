import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/firestore_common.dart';

/// [Query] mixin providing [count], [onCount] and [orderById] in terms of
/// the other [Query] members, for backends with no native, cheaper way to
/// compute them.
///
/// Every implementation without a native aggregate/count backend should mix
/// this in as a fallback. [count] and [onCount] are expensive: they fetch
/// (or subscribe to) the full result set just to measure its length.
mixin FirestoreQueryExecutorMixin implements Query {
  /// Expensive default implementation: fetches the full result set with
  /// [get] and returns its length.
  @override
  Future<int> count() async {
    return (await get()).docs.length;
  }

  /// Expensive default implementation: derives a live count from [onSnapshot].
  @override
  Stream<int> onCount() => onSnapshot().map((snapshot) => snapshot.docs.length);

  @override
  Query orderById({bool? descending}) =>
      orderBy(firestoreNameFieldPath, descending: descending);
}

/// [Query] mixin providing an [aggregate] implementation that always throws
/// [UnimplementedError], for backends that don't support aggregate queries.
///
/// Every implementation without native aggregate query support should mix
/// this in as a fallback default.
mixin QueryDefaultMixin implements Query {
  @override
  AggregateQuery aggregate(List<AggregateField> fields) {
    throw UnimplementedError();
  }
}

/// Common [Query] mixin implementing every refinement method (`where`,
/// `orderBy`, `limit`, `select`, cursor methods) in terms of a mutable
/// [queryInfo] and [clone], with no query executor of its own.
///
/// Used by implementations that build up a [QueryInfo] description of the
/// query and delegate its actual execution elsewhere (for example by
/// serializing it to a native/remote query). Compare with
/// [FirestoreQueryMixin] in `utils/firestore_mixin.dart`, which additionally
/// executes queries in-memory.
mixin QueryMixin implements Query {
  /// The mutable, cloneable description (filters, ordering, limits, cursors)
  /// of this query, built up by the refinement methods below.
  late QueryInfo queryInfo;

  /// Returns a copy of this query, including a copy of [queryInfo], so that
  /// refinement methods can return a new [Query] without mutating this one.
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
  }) => clone()
    ..queryInfo.addWhere(
      WhereInfo(
        fieldPath,
        isEqualTo: isEqualTo,
        isLessThan: isLessThan,
        isLessThanOrEqualTo: isLessThanOrEqualTo,
        isGreaterThan: isGreaterThan,
        isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
        arrayContains: arrayContains,
        arrayContainsAny: arrayContainsAny,
        whereIn: whereIn,
        isNull: isNull,
      ),
    );

  /// Appends an order-by clause on field [key] to [queryInfo], sorted
  /// ascending unless [directionStr] equals [orderByDescending].
  void addOrderBy(String key, String directionStr) {
    var orderBy = OrderByInfo(
      fieldPath: key,
      ascending: directionStr != orderByDescending,
    );
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
      key,
      descending == true ? orderByDescending : orderByAscending,
    );
}

/// Rebuilds a [Query] on [firestore] at collection [path] applying the
/// filters, ordering and cursors described by [queryInfo], synchronously.
///
/// [queryInfo] may be `null`, in which case the unfiltered collection query
/// is returned. Unlike [applyQueryInfo], cursors expressed with
/// `documentId` (rather than explicit `values`) are not supported: an
/// [ArgumentError] is thrown in that case, since resolving a document id
/// cursor requires fetching the referenced document, which is asynchronous.
Query applyQueryInfoNoDocumentId(
  Firestore firestore,
  String path,
  QueryInfo? queryInfo,
) {
  var query = _applyQueryInfoNoLimit(firestore, path, queryInfo);
  if (queryInfo != null) {
    if (queryInfo.startLimit != null) {
      if (queryInfo.startLimit!.documentId != null) {
        throw ArgumentError(
          'documentId not supported for startLimit use applyQueryInfo',
        );
      }
      if (queryInfo.startLimit!.inclusive) {
        query = query.startAt(values: queryInfo.startLimit!.values);
      } else {
        query = query.startAfter(values: queryInfo.startLimit!.values);
      }
    }
    if (queryInfo.endLimit != null) {
      if (queryInfo.endLimit!.documentId != null) {
        throw ArgumentError(
          'documentId not supported for endLimit use applyQueryInfo',
        );
      }
      if (queryInfo.endLimit!.inclusive) {
        query = query.endAt(values: queryInfo.endLimit!.values);
      } else {
        query = query.endBefore(values: queryInfo.endLimit!.values);
      }
    }
  }
  return query;
}

/// Apply query info to query/collection
Query _applyQueryInfoNoLimit(
  Firestore firestore,
  String path,
  QueryInfo? queryInfo,
) {
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
      query = query.where(
        where.fieldPath,
        isEqualTo: where.isEqualTo,
        isGreaterThan: where.isGreaterThan,
        whereIn: where.whereIn,
        arrayContains: where.arrayContains,
        arrayContainsAny: where.arrayContainsAny,
        isGreaterThanOrEqualTo: where.isGreaterThanOrEqualTo,
        isLessThan: where.isLessThan,
        isNull: where.isNull,
        isLessThanOrEqualTo: where.isLessThanOrEqualTo,
      );
    }
  }
  return query;
}

/// Rebuilds a [Query] on [firestore] at collection [path] applying the
/// filters, ordering and cursors described by [queryInfo].
///
/// [queryInfo] may be `null`, in which case the unfiltered collection query
/// is returned. Unlike [applyQueryInfoNoDocumentId], cursors expressed with
/// a `documentId` are supported: the referenced document is fetched (hence
/// the asynchronous, `Future`-returning signature) and used as the cursor
/// snapshot.
Future<Query> applyQueryInfo(
  Firestore firestore,
  String path,
  QueryInfo? queryInfo,
) async {
  var query = _applyQueryInfoNoLimit(firestore, path, queryInfo);
  if (queryInfo != null) {
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
          snapshot: snapshot,
          values: queryInfo.startLimit!.values,
        );
      } else {
        query = query.startAfter(
          snapshot: snapshot,
          values: queryInfo.startLimit!.values,
        );
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
        query = query.endAt(
          snapshot: snapshot,
          values: queryInfo.endLimit!.values,
        );
      } else {
        query = query.endBefore(
          snapshot: snapshot,
          values: queryInfo.endLimit!.values,
        );
      }
    }
  }
  return query;
}
