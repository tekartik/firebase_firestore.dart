import 'dart:async';
import 'dart:math';

import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/query_mixin.dart';
import 'package:tekartik_firebase_firestore/utils/firestore_mixin.dart';

/// Documents read per query when a query is iterated.
///
/// Firestore has no cursor: a query is read page by page, each page being one
/// `get()`. Small enough to stop early cheaply, big enough to keep the number
/// of queries low.
const firestoreQueryIterateChunkSize = 100;

/// Callback for iteration. Return `false` to stop.
typedef FirestoreQueryRowCallback =
    FutureOr<bool> Function(DocumentSnapshot doc);

/// Options for [TekartikFirestoreQueryIterateExt.queryIterate],
/// [TekartikFirestoreQueryIterateExt.queryStream] and
/// [TekartikFirestoreQueryIterateExt.findDocs].
class QueryFindOptions {
  /// Page size when querying source documents.
  final int? pageSize;

  /// Creates options for a query find or iteration.
  QueryFindOptions({this.pageSize});
}

/// Alternative alias for [QueryFindOptions].
typedef QueryFindOption = QueryFindOptions;

/// Iterate extension on [Query].
///
/// The firestore counterpart of an sql cursor or of an sdb store iteration:
/// the documents matching a query are handed out one by one, reading them
/// page by page so that the whole result never has to be held in memory, and
/// so that stopping early stops reading.
extension TekartikFirestoreQueryIterateExt on Query {
  /// Iterate over the documents matching this query.
  ///
  /// [onRow] is called for each document. Return `false` to stop the
  /// iteration.
  ///
  /// Paging is done with a `startAfter` cursor, which needs the full sort key
  /// of the last document of a page: the fields this query is already ordered by
  /// are automatically extracted from the query. Ordering by document id
  /// is appended, so the documents of two pages never overlap.
  ///
  /// The documents must not move while the iteration is performed; a document updated
  /// in a way that changes one of its ordered fields can be
  /// read twice or not at all, exactly like it would invalidate a cursor.
  Future<void> queryIterate({
    QueryFindOptions? options,
    required FirestoreQueryRowCallback onRow,
  }) async {
    var stream = firestoreQueryPageStream(this, pageSize: options?.pageSize);
    await for (var page in stream) {
      for (var doc in page) {
        var result = onRow(doc);
        var doContinue = result is Future<bool> ? await result : result;
        if (!doContinue) {
          return;
        }
      }
    }
  }

  /// The documents matching this query, read page by page as a stream.
  ///
  /// The stream is lazy: a page is only read when its first document is asked
  /// for, so a consumer stopping early does not read the rest. Built on
  /// [queryIterate].
  Stream<DocumentSnapshot> queryStream({QueryFindOptions? options}) {
    late StreamController<DocumentSnapshot> controller;
    Completer<void>? resumeCompleter;
    controller = StreamController<DocumentSnapshot>(
      onListen: () {
        queryIterate(
          options: options,
          onRow: (doc) async {
            if (controller.isClosed) {
              return false;
            }
            controller.add(doc);
            if (controller.isPaused) {
              if (resumeCompleter == null || resumeCompleter!.isCompleted) {
                resumeCompleter = Completer<void>();
              }
              await resumeCompleter!.future;
            }
            return !controller.isClosed;
          },
        ).then(
          (_) {
            if (!controller.isClosed) {
              controller.close();
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!controller.isClosed) {
              controller.addError(error, stackTrace);
              controller.close();
            }
          },
        );
      },
      onPause: () {
        if (resumeCompleter == null || resumeCompleter!.isCompleted) {
          resumeCompleter = Completer<void>();
        }
      },
      onResume: () {
        if (resumeCompleter != null && !resumeCompleter!.isCompleted) {
          resumeCompleter!.complete();
        }
        resumeCompleter = null;
      },
      onCancel: () {
        if (resumeCompleter != null && !resumeCompleter!.isCompleted) {
          resumeCompleter!.complete();
        }
        resumeCompleter = null;
      },
    );
    return controller.stream;
  }

  /// The field paths this query is ordered by, in order of priority.
  List<String> get orderByFields => queryGetOrderByFields(this);

  /// The limit applied to this query, if any.
  int? get queryLimit => queryGetLimit(this);

  /// The documents matching this query, as a list.
  ///
  /// Built on [queryIterate]; prefer [queryIterate] or [queryStream] when the
  /// whole result does not have to be held in memory.
  Future<List<DocumentSnapshot>> findDocs({QueryFindOptions? options}) async {
    var docs = <DocumentSnapshot>[];
    await queryIterate(
      options: options,
      onRow: (doc) {
        docs.add(doc);
        return true;
      },
    );
    return docs;
  }
}

/// The documents matching [query], page by page.
///
/// Lazy: a page is only read when it is asked for. [scanLimit] caps the total
/// number of documents read, `null` meaning the whole query (or [TekartikFirestoreQueryIterateExt.queryLimit]
/// if set on [query]).
///
/// [orderByFields] defaults to [TekartikFirestoreQueryIterateExt.orderByFields].
Stream<List<DocumentSnapshot>> firestoreQueryPageStream(
  Query query, {
  int? pageSize,
  List<String>? orderByFields,
  int? scanLimit,
}) async* {
  var chunkSize = pageSize ?? firestoreQueryIterateChunkSize;
  var fields = orderByFields ?? query.orderByFields;
  var queryLimit = query.queryLimit;
  var limit = scanLimit == null
      ? queryLimit
      : (queryLimit == null ? scanLimit : min(scanLimit, queryLimit));
  // `orderById` cannot be followed by another `orderBy`, so an explicit
  // ordering by document id is kept as is.
  var orderedById = fields.isNotEmpty && fields.last == firestoreNameFieldPath;
  var lastOrderBy = _queryGetQueryInfo(query)?.orderBys.lastOrNull;
  var descending = lastOrderBy != null && !lastOrderBy.ascending;
  var pagedQuery = orderedById
      ? query
      : query.orderBy(firestoreNameFieldPath, descending: descending);
  var cursorFields = orderedById ? fields : [...fields, firestoreNameFieldPath];

  var read = 0;
  DocumentSnapshot? last;
  while (true) {
    var wanted = limit == null ? chunkSize : min(chunkSize, limit - read);
    if (wanted <= 0) {
      return;
    }
    var pageQuery = pagedQuery;
    if (last != null) {
      pageQuery = pageQuery.startAfter(
        values: [
          for (var field in cursorFields) firestoreDocumentValueAt(last, field),
        ],
      );
    }
    var snapshot = await pageQuery.limit(wanted).get();
    var docs = snapshot.docs;
    if (docs.isEmpty) {
      return;
    }
    read += docs.length;
    last = docs.last;
    yield docs;
    if (docs.length < wanted || (limit != null && read >= limit)) {
      // Short page or limit reached, the end is reached.
      return;
    }
  }
}

/// The value of [doc] at [fieldPath], the document id for
/// [firestoreNameFieldPath].
///
/// [fieldPath] is a field name, or a dot separated path for a nested field.
Object? firestoreDocumentValueAt(DocumentSnapshot doc, String fieldPath) {
  if (fieldPath == firestoreNameFieldPath) {
    return doc.ref.id;
  }
  Object? value = doc.data;
  for (var part in fieldPath.split('.')) {
    if (value is Map) {
      value = value[part];
    } else {
      return null;
    }
  }
  return value;
}

/// Internal helper to extract [QueryInfo] from a [Query].
QueryInfo? _queryGetQueryInfo(Query query) {
  var current = query;
  while (true) {
    final c = current;
    if (c is HasQueryInfo) {
      return (c as HasQueryInfo).queryInfo;
    }
    if (c is FirestoreQueryMixin) {
      return c.queryInfo;
    }
    if (c is QueryMixin) {
      return c.queryInfo;
    }
    try {
      var info = (current as dynamic).queryInfo;
      if (info is QueryInfo) {
        return info;
      }
    } catch (_) {}
    try {
      var inner = (current as dynamic).query;
      if (inner is Query && inner != current) {
        current = inner;
        continue;
      }
    } catch (_) {}
    break;
  }
  return null;
}

/// Extracts the order by field paths from [query], if available.
List<String> queryGetOrderByFields(Query query) {
  var queryInfo = _queryGetQueryInfo(query);
  return queryInfo?.orderBys
          .map((o) => o.fieldPath)
          .whereType<String>()
          .toList() ??
      const <String>[];
}

/// Extracts the limit from [query], if set.
int? queryGetLimit(Query query) {
  return _queryGetQueryInfo(query)?.limit;
}
