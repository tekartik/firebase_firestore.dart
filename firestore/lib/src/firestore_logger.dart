import 'dart:async';

import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/reference_mixin.dart';
import 'package:tekartik_firebase_firestore/src/common/transaction_mixin.dart';
import 'package:tekartik_firebase_firestore/utils/firestore_mixin.dart';
import 'package:tekartik_firebase_firestore/utils/json_utils.dart';

import 'common/firestore_service_mixin.dart';
import 'common/query_mixin.dart';

abstract class FirestoreLoggerEvent {
  /// Set on failure
  Object? get exception;
}

abstract class FirestoreLoggerEventImpl implements FirestoreLoggerEvent {
  /// Set on failure
  @override
  Object? exception;

  @override
  String toString() => eventToString(this);
}

String eventToString(FirestoreLoggerEvent event) {
  late String type;
  if (event is FirestoreLoggerSetEvent) {
    type = 'set';
  } else if (event is FirestoreLoggerGetEvent) {
    type = 'get';
  } else if (event is FirestoreLoggerDeleteEvent) {
    type = 'del';
  } else if (event is FirestoreLoggerUpdateEvent) {
    type = 'upd';
  } else if (event is FirestoreLoggerAddEvent) {
    type = 'add';
  } else if (event is FirestoreLoggerOnSnapshotEvent) {
    type = 'gos';
  } else if (event is FirestoreLoggerQueryOnSnapshotEvent) {
    type = 'qos';
  } else if (event is FirestoreLoggerQueryGetEvent) {
    type = 'qry';
  } else {
    type = '??? ${event.runtimeType}';
  }
  late String path;
  if (event is FirestoreLoggerEventWithCollectionRefMixin) {
    path = event.ref.path;
  } else if (event is FirestoreLoggerEventWithDocumentRefMixin) {
    path = event.ref.path;
  } else {
    path = '/?/?';
  }
  var sb = StringBuffer();
  sb.write('$type $path');
  if (event is FirestoreLoggerSetEvent && (event.options?.merge ?? false)) {
    sb.write(' (merge)');
  }
  if (event is FirestoreLoggerEventWithTagMixin && (event.tag != null)) {
    sb.write(' ${event.tag}');
  }
  if (event is FirestoreLoggerAddEvent) {
    sb.write(' ${event.id}');
  }
  if (event is FirestoreLoggerEventWithDocumentDataMixin) {
    sb.write(' ${event.data}');
  } else if (event is FirestoreLoggerGetEvent) {
    sb.write(
        ' ${(event.snapshot?.exists ?? false) ? event.snapshot!.data : 'null'}');
  } else if (event is FirestoreLoggerOnSnapshotEvent) {
    sb.write(' ${(event.snapshot.exists) ? event.snapshot.data : 'null'}');
  } else if (event is FirestoreLoggerEventWithQueryMixin) {
    if (event.query is QueryMixin) {
      sb.write(' ${queryInfoToJsonMap((event.query as QueryMixin).queryInfo)}');
    }
  } else if (event is FirestoreLoggerQueryGetEvent) {
    sb.write(' [${event.snapshot?.docs.length}]');
  } else if (event is FirestoreLoggerQueryOnSnapshotEvent) {
    sb.write(' [${event.snapshot.docs.length}]');
  }
  if (event.exception != null) {
    sb.writeln();
    sb.write('  Exception ${event.exception}');
  }
  return sb.toString();
}

class FirestoreLoggerDeleteEvent extends FirestoreLoggerEventImpl
    with
        FirestoreLoggerEventWithDocumentRefMixin,
        FirestoreLoggerEventWithTagMixin
    implements FirestoreLoggerEvent {
  FirestoreLoggerDeleteEvent(DocumentReference ref,
      {Object? exception, String? tag}) {
    this.ref = ref;
    this.exception = exception;
    this.tag = tag;
  }
}

class FirestoreLoggerSetEvent extends FirestoreLoggerEventImpl
    with
        FirestoreLoggerEventWithDocumentRefMixin,
        FirestoreLoggerEventWithDocumentDataMixin,
        FirestoreLoggerEventWithTagMixin
    implements FirestoreLoggerEvent {
  final SetOptions? options;

  FirestoreLoggerSetEvent(DocumentReference ref, Map<String, Object?> data,
      {this.options, Object? exception, String? tag}) {
    this.ref = ref;
    this.data = data;
    this.exception = exception;
    this.tag = tag;
  }
}

class FirestoreLoggerUpdateEvent extends FirestoreLoggerEventImpl
    with
        FirestoreLoggerEventWithDocumentRefMixin,
        FirestoreLoggerEventWithDocumentDataMixin,
        FirestoreLoggerEventWithTagMixin
    implements FirestoreLoggerEvent {
  FirestoreLoggerUpdateEvent(DocumentReference ref, Map<String, Object?> data,
      {Object? exception, String? tag}) {
    this.ref = ref;
    this.data = data;
    this.exception = exception;
    this.tag = tag;
  }
}

class FirestoreLoggerAddEvent extends FirestoreLoggerEventImpl
    with
        FirestoreLoggerEventWithDocumentDataMixin,
        FirestoreLoggerEventWithCollectionRefMixin
    implements FirestoreLoggerEvent {
  /// Added id on success.
  final String? id;
  FirestoreLoggerAddEvent(CollectionReference ref, Map<String, Object?> data,
      {Object? exception, this.id}) {
    this.ref = ref;
    this.data = data;
    this.exception = exception;
  }
}

class FirestoreLoggerOnSnapshotEvent extends FirestoreLoggerEventImpl
    with FirestoreLoggerEventWithDocumentRefMixin
    implements FirestoreLoggerEvent {
  /// Data read on success (even if it does not exist)
  final DocumentSnapshot snapshot;
  FirestoreLoggerOnSnapshotEvent(this.snapshot, {Object? exception}) {
    ref = snapshot.ref;
    this.exception = exception;
  }
}

class FirestoreLoggerGetEvent extends FirestoreLoggerEventImpl
    with
        FirestoreLoggerEventWithDocumentRefMixin,
        FirestoreLoggerEventWithTagMixin
    implements FirestoreLoggerEvent {
  /// Data read on success (even if it does not exist)
  final DocumentSnapshot? snapshot;
  FirestoreLoggerGetEvent(DocumentReference ref,
      {Object? exception, this.snapshot, String? tag}) {
    this.ref = ref;
    this.exception = exception;
    this.tag = tag;
  }
}

class FirestoreLoggerQueryGetEvent extends FirestoreLoggerEventImpl
    with
        FirestoreLoggerEventWithQueryMixin,
        FirestoreLoggerEventWithCollectionRefMixin,
        FirestoreLoggerEventWithTagMixin
    implements FirestoreLoggerEvent {
  /// Data read on success (even if it does not exist)
  final QuerySnapshot? snapshot;
  FirestoreLoggerQueryGetEvent(QueryLoggerBase query,
      {Object? exception, required this.snapshot, String? tag}) {
    this.query = query;
    ref = query.refLogger;
    this.exception = exception;
    this.tag = tag;
  }
}

class FirestoreLoggerQueryOnSnapshotEvent extends FirestoreLoggerEventImpl
    with
        FirestoreLoggerEventWithQueryMixin,
        FirestoreLoggerEventWithCollectionRefMixin
    implements FirestoreLoggerEvent {
  /// Data read on success (even if it does not exist)
  final QuerySnapshot snapshot;
  FirestoreLoggerQueryOnSnapshotEvent(QueryLoggerBase query, this.snapshot,
      {Object? exception}) {
    this.query = query;
    ref = query.refLogger;
    this.exception = exception;
  }
}

mixin FirestoreLoggerEventWithDocumentRefMixin implements FirestoreLoggerEvent {
  late DocumentReference ref;
}

/// Batch and transaction
mixin FirestoreLoggerEventWithTagMixin implements FirestoreLoggerEvent {
  late String? tag;
}
mixin FirestoreLoggerEventWithCollectionRefMixin
    implements FirestoreLoggerEvent {
  late CollectionReference ref;
}
mixin FirestoreLoggerEventWithQueryMixin implements FirestoreLoggerEvent {
  late Query query;
}

mixin FirestoreLoggerEventWithDocumentDataMixin
    implements FirestoreLoggerEvent {
  late Map<String, Object?> data;
}

void _logDefault(FirestoreLoggerEvent event) {
  print(event);
}

class FirestoreLoggerOptions {
  /// True if write should be logged
  final bool write;
  final bool read;
  final bool list;
  late final void Function(FirestoreLoggerEvent event) log;

  FirestoreLoggerOptions.all(
      {void Function(FirestoreLoggerEvent event)? log,
      this.write = true,
      this.read = true,
      this.list = true}) {
    this.log = log ?? _logDefault;
  }
}

class FirestoreLoggerBatch implements WriteBatch {
  static var _id = 0;
  final FirestoreLoggerOptions options;
  final WriteBatch writeBatch;

  FirestoreLoggerBatch(this.writeBatch, this.options) {
    ++_id;
  }

  String get _tag => 'B$_id';

  @override
  Future commit() {
    return writeBatch.commit();
  }

  @override
  void delete(DocumentReference ref) {
    Object? exception;
    try {
      writeBatch.delete(ref);
    } catch (e) {
      exception = e;
      rethrow;
    } finally {
      if (options.write) {
        options.log(
            FirestoreLoggerDeleteEvent(ref, exception: exception, tag: _tag));
      }
    }
  }

  @override
  void set(DocumentReference ref, Map<String, Object?> data,
      [SetOptions? options]) {
    Object? exception;
    try {
      writeBatch.set(ref, data, options);
    } catch (e) {
      exception = e;
      rethrow;
    } finally {
      if (this.options.write) {
        this.options.log(FirestoreLoggerSetEvent(ref, data,
            exception: exception, tag: _tag));
      }
    }
  }

  @override
  void update(DocumentReference ref, Map<String, Object?> data) {
    Object? exception;
    try {
      writeBatch.update(ref, data);
    } catch (e) {
      exception = e;
      rethrow;
    } finally {
      if (options.write) {
        options.log(FirestoreLoggerUpdateEvent(ref, data,
            exception: exception, tag: _tag));
      }
    }
  }
}

abstract class QueryLoggerBase implements Query {
  final Query query;
  FirestoreLogger get firestoreLogger => refLogger.firestoreLogger;
  late final CollectionReferenceLogger refLogger;
  FirestoreLoggerOptions get options => firestoreLogger.options;

  QueryLoggerBase(this.query);

  @override
  Query endAt({DocumentSnapshot? snapshot, List<Object?>? values}) =>
      QueryLogger(query.endAt(snapshot: snapshot, values: values), refLogger);

  @override
  Query endBefore({DocumentSnapshot? snapshot, List<Object?>? values}) =>
      QueryLogger(
          query.endBefore(snapshot: snapshot, values: values), refLogger);

  @override
  Future<QuerySnapshot> get() async {
    Object? exception;
    QuerySnapshot? snapshot;
    try {
      snapshot = await query.get();
      return snapshot;
    } catch (e) {
      exception = e;
      rethrow;
    } finally {
      if (options.list) {
        options.log(FirestoreLoggerQueryGetEvent(this,
            exception: exception, snapshot: snapshot));
      }
    }
  }

  @override
  Query limit(int limit) => QueryLogger(query.limit(limit), refLogger);

  @override
  Stream<QuerySnapshot> onSnapshot() {
    return StreamTransformer<QuerySnapshot, QuerySnapshot>.fromHandlers(
        handleData: (snapshot, sink) {
      if (options.list) {
        options.log(FirestoreLoggerQueryOnSnapshotEvent(this, snapshot));
      }
      sink.add(snapshot);
    }).bind(query.onSnapshot());
  }

  @override
  Query orderBy(String key, {bool? descending}) =>
      QueryLogger(query.orderBy(key, descending: descending), refLogger);

  @override
  Query select(List<String> keyPaths) =>
      QueryLogger(query.select(keyPaths), refLogger);

  @override
  Query startAfter({DocumentSnapshot? snapshot, List<Object?>? values}) =>
      QueryLogger(
          query.startAfter(snapshot: snapshot, values: values), refLogger);

  @override
  Query startAt({DocumentSnapshot? snapshot, List<Object?>? values}) =>
      QueryLogger(query.startAt(snapshot: snapshot, values: values), refLogger);

  @override
  Query where(String fieldPath,
          {isEqualTo,
          isLessThan,
          isLessThanOrEqualTo,
          isGreaterThan,
          isGreaterThanOrEqualTo,
          arrayContains,
          List<Object>? arrayContainsAny,
          List<Object>? whereIn,
          bool? isNull}) =>
      QueryLogger(
          query.where(fieldPath,
              isEqualTo: isEqualTo,
              isLessThan: isLessThan,
              isLessThanOrEqualTo: isLessThanOrEqualTo,
              isGreaterThan: isGreaterThan,
              isGreaterThanOrEqualTo: isGreaterThanOrEqualTo,
              arrayContains: arrayContains,
              arrayContainsAny: arrayContainsAny,
              whereIn: whereIn,
              isNull: isNull),
          refLogger);
}

class QueryLogger extends QueryLoggerBase implements Query {
  QueryLogger(Query query, CollectionReferenceLogger refLogger) : super(query) {
    this.refLogger = refLogger;
  }
}

class CollectionReferenceLogger extends QueryLoggerBase
    with CollectionReferenceMixin, PathReferenceMixin
    implements CollectionReference {
  @override
  final FirestoreLogger firestoreLogger;
  CollectionReference get ref => query as CollectionReference;

  CollectionReferenceLogger(CollectionReference ref, this.firestoreLogger)
      : super(ref) {
    refLogger = this;
  }

  @override
  Future<DocumentReference> add(Map<String, Object?> data) async {
    Object? exception;
    DocumentReference? result;
    try {
      result = await ref.add(data);
      return result;
    } catch (e) {
      exception = e;
      rethrow;
    } finally {
      if (options.write) {
        options.log(FirestoreLoggerAddEvent(ref, data,
            exception: exception, id: result?.id));
      }
    }
  }

  @override
  Firestore get firestore => firestoreLogger;

  @override
  String get path => ref.path;
}

class DocumentReferenceLogger
    with DocumentReferenceMixin, PathReferenceMixin
    implements DocumentReference {
  final DocumentReference ref;
  final FirestoreLogger firestoreLogger;
  FirestoreLoggerOptions get options => firestoreLogger.options;
  DocumentReferenceLogger(this.ref, this.firestoreLogger);

  @override
  Future<void> delete() async {
    Object? exception;
    try {
      await ref.delete();
    } catch (e) {
      exception = e;
      rethrow;
    } finally {
      if (options.write) {
        options.log(FirestoreLoggerDeleteEvent(ref, exception: exception));
      }
    }
  }

  @override
  Firestore get firestore => firestoreLogger;

  @override
  Future<DocumentSnapshot> get() async {
    Object? exception;
    DocumentSnapshot? snapshot;
    try {
      snapshot = await ref.get();
      return snapshot;
    } catch (e) {
      exception = e;
      rethrow;
    } finally {
      if (options.read) {
        options.log(FirestoreLoggerGetEvent(ref,
            exception: exception, snapshot: snapshot));
      }
    }
  }

  @override
  Stream<DocumentSnapshot> onSnapshot() {
    return StreamTransformer<DocumentSnapshot, DocumentSnapshot>.fromHandlers(
        handleData: (snapshot, sink) {
      if (options.read) {
        options.log(FirestoreLoggerOnSnapshotEvent(snapshot));
      }
      sink.add(snapshot);
    }).bind(ref.onSnapshot());
  }

  @override
  String get path => ref.path;

  @override
  Future<void> set(Map<String, Object?> data, [SetOptions? options]) async {
    Object? exception;
    try {
      await ref.set(data, options);
    } catch (e) {
      exception = e;
      rethrow;
    } finally {
      if (this.options.write) {
        this
            .options
            .log(FirestoreLoggerSetEvent(ref, data, exception: exception));
      }
    }
  }

  @override
  Future<void> update(Map<String, Object?> data) async {
    Object? exception;
    try {
      await ref.update(data);
    } catch (e) {
      exception = e;
      rethrow;
    } finally {
      if (options.write) {
        options
            .log(FirestoreLoggerUpdateEvent(ref, data, exception: exception));
      }
    }
  }
}

class TransactionLogger with TransactionMixin implements Transaction {
  final Transaction transaction;
  final FirestoreLogger firestoreLogger;
  FirestoreLoggerOptions get options => firestoreLogger.options;
  static var _id = 0;

  TransactionLogger(this.transaction, this.firestoreLogger) {
    ++_id;
  }

  String get _tag => 'T$_id';

  @override
  void delete(DocumentReference ref) {
    Object? exception;
    try {
      transaction.delete(ref);
    } catch (e) {
      exception = e;
      rethrow;
    } finally {
      if (options.write) {
        options.log(
            FirestoreLoggerDeleteEvent(ref, exception: exception, tag: _tag));
      }
    }
  }

  @override
  Future<DocumentSnapshot> get(DocumentReference documentRef) async {
    Object? exception;
    DocumentSnapshot? snapshot;
    try {
      snapshot = await documentRef.get();
      return snapshot;
    } catch (e) {
      exception = e;
      rethrow;
    } finally {
      if (options.read) {
        options.log(FirestoreLoggerGetEvent(documentRef,
            exception: exception, snapshot: snapshot, tag: _tag));
      }
    }
  }

  @override
  void set(DocumentReference documentRef, Map<String, Object?> data,
      [SetOptions? options]) {
    Object? exception;
    try {
      transaction.set(documentRef, data, options);
    } catch (e) {
      exception = e;
      rethrow;
    } finally {
      if (this.options.write) {
        this.options.log(FirestoreLoggerSetEvent(documentRef, data,
            exception: exception, tag: _tag));
      }
    }
  }

  @override
  void update(DocumentReference documentRef, Map<String, Object?> data) {
    Object? exception;
    try {
      transaction.update(documentRef, data);
    } catch (e) {
      exception = e;
      rethrow;
    } finally {
      if (options.write) {
        options.log(FirestoreLoggerUpdateEvent(documentRef, data,
            exception: exception, tag: _tag));
      }
    }
  }
}

class FirestoreLogger with FirestoreMixin implements Firestore {
  final FirestoreLoggerOptions options;
  final Firestore firestore;

  FirestoreLogger({required this.firestore, required this.options});

  @override
  WriteBatch batch() => FirestoreLoggerBatch(firestore.batch(), options);

  @override
  CollectionReference collection(String path) =>
      CollectionReferenceLogger(firestore.collection(path), this);

  @override
  DocumentReference doc(String path) =>
      DocumentReferenceLogger(firestore.doc(path), this);

  @override
  Future<T> runTransaction<T>(
      FutureOr<T> Function(Transaction transaction) action) async {
    return firestore.runTransaction((transaction) {
      return action(TransactionLogger(transaction, this));
    });
  }
}

class FirestoreServiceLogger
    with FirestoreServiceMixin
    implements FirestoreService {
  final FirestoreLoggerOptions options;
  final FirestoreService firestoreService;

  FirestoreServiceLogger(
      {required this.firestoreService, required this.options});

  @override
  Firestore firestore(App app) => getInstance<FirestoreLogger>(app, () {
        return FirestoreLogger(
            firestore: firestoreService.firestore(app), options: options);
      });

  @override
  bool get supportsDocumentSnapshotTime =>
      firestoreService.supportsDocumentSnapshotTime;

  @override
  bool get supportsFieldValueArray => firestoreService.supportsFieldValueArray;

  @override
  bool get supportsQuerySelect => firestoreService.supportsQuerySelect;

  @override
  bool get supportsQuerySnapshotCursor =>
      firestoreService.supportsQuerySnapshotCursor;

  @override
  bool get supportsTimestamps => firestoreService.supportsTimestamps;

  @override
  bool get supportsTimestampsInSnapshots =>
      firestoreService.supportsTimestampsInSnapshots;

  @override
  bool get supportsTrackChanges => firestoreService.supportsTrackChanges;
}
