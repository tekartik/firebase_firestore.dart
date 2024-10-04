import 'dart:async';

import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/reference_mixin.dart';
import 'package:tekartik_firebase_firestore/src/common/transaction_mixin.dart';
import 'package:tekartik_firebase_firestore/utils/firestore_mixin.dart';

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
  } else if (event is FirestoreLoggerOnSnapshotTriggerEvent) {
    type = 'got';
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
  FirestoreLoggerDeleteEvent(DocumentReferenceLogger ref,
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

  FirestoreLoggerSetEvent(
      DocumentReferenceLogger ref, Map<String, Object?> data,
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
  FirestoreLoggerUpdateEvent(
      DocumentReferenceLogger ref, Map<String, Object?> data,
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

  FirestoreLoggerAddEvent(
      CollectionReferenceLogger ref, Map<String, Object?> data,
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
  final DocumentSnapshotLogger snapshot;

  FirestoreLoggerOnSnapshotEvent(this.snapshot, {Object? exception}) {
    ref = snapshot.ref;
    this.exception = exception;
  }
}

class FirestoreLoggerOnSnapshotTriggerEvent extends FirestoreLoggerEventImpl
    with FirestoreLoggerEventWithDocumentRefMixin
    implements FirestoreLoggerEvent {
  FirestoreLoggerOnSnapshotTriggerEvent(DocumentReferenceLogger ref,
      {Object? exception}) {
    this.ref = ref;
    this.exception = exception;
  }
}

class FirestoreLoggerGetEvent extends FirestoreLoggerEventImpl
    with
        FirestoreLoggerEventWithDocumentRefMixin,
        FirestoreLoggerEventWithTagMixin
    implements FirestoreLoggerEvent {
  /// Data read on success (even if it does not exist)
  final DocumentSnapshotLogger? snapshot;

  FirestoreLoggerGetEvent(DocumentReferenceLogger ref,
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
  final QuerySnapshotLogger? snapshot;

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
  final QuerySnapshotLogger snapshot;

  FirestoreLoggerQueryOnSnapshotEvent(QueryLoggerBase query, this.snapshot,
      {Object? exception}) {
    this.query = query;
    ref = query.refLogger;
    this.exception = exception;
  }
}

mixin FirestoreLoggerEventWithDocumentRefMixin implements FirestoreLoggerEvent {
  late DocumentReferenceLogger ref;
}

/// Batch and transaction
mixin FirestoreLoggerEventWithTagMixin implements FirestoreLoggerEvent {
  late String? tag;
}
mixin FirestoreLoggerEventWithCollectionRefMixin
    implements FirestoreLoggerEvent {
  late CollectionReferenceLogger ref;
}
mixin FirestoreLoggerEventWithQueryMixin implements FirestoreLoggerEvent {
  late QueryLoggerBase query;
}

mixin FirestoreLoggerEventWithDocumentDataMixin
    implements FirestoreLoggerEvent {
  late Map<String, Object?> data;
}

void _logDefault(FirestoreLoggerEvent event) {
  // ignore: avoid_print
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
  final FirestoreLogger firestoreLogger;
  final WriteBatch writeBatch;

  FirestoreLoggerOptions get options => firestoreLogger.options;

  FirestoreLoggerBatch(this.writeBatch, this.firestoreLogger) {
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
      writeBatch.delete((ref as DocumentReferenceLogger).ref);
    } catch (e) {
      exception = e;
      rethrow;
    } finally {
      if (options.write) {
        options.log(FirestoreLoggerDeleteEvent(ref as DocumentReferenceLogger,
            exception: exception, tag: _tag));
      }
    }
  }

  @override
  void set(DocumentReference ref, Map<String, Object?> data,
      [SetOptions? options]) {
    Object? exception;
    try {
      writeBatch.set((ref as DocumentReferenceLogger).ref, data, options);
    } catch (e) {
      exception = e;
      rethrow;
    } finally {
      if (this.options.write) {
        this.options.log(FirestoreLoggerSetEvent(
            ref as DocumentReferenceLogger, data,
            exception: exception, tag: _tag));
      }
    }
  }

  @override
  void update(DocumentReference ref, Map<String, Object?> data) {
    Object? exception;
    try {
      writeBatch.update((ref as DocumentReferenceLogger).ref, data);
    } catch (e) {
      exception = e;
      rethrow;
    } finally {
      if (options.write) {
        options.log(FirestoreLoggerUpdateEvent(
            ref as DocumentReferenceLogger, data,
            exception: exception, tag: _tag));
      }
    }
  }
}

abstract class QueryLoggerBase
    with QueryDefaultMixin, FirestoreQueryExecutorMixin
    implements Query {
  final Query query;

  FirestoreLogger get firestoreLogger => refLogger.firestoreLogger;
  late final CollectionReferenceLogger refLogger;

  FirestoreLoggerOptions get options => firestoreLogger.options;

  QueryLoggerBase(this.query) {
    assert(query is! QueryLoggerBase, 'You cannot reference a logger');
  }

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
    QuerySnapshotLogger? snapshot;
    try {
      snapshot = QuerySnapshotLogger(await query.get(), firestoreLogger);
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
  Stream<QuerySnapshot> onSnapshot({bool includeMetadataChanges = false}) {
    return StreamTransformer<QuerySnapshot, QuerySnapshot>.fromHandlers(
        handleData: (snapshot, sink) {
      var snapshotLogger = QuerySnapshotLogger(snapshot, firestoreLogger);
      if (options.list) {
        options.log(FirestoreLoggerQueryOnSnapshotEvent(this, snapshotLogger));
      }
      sink.add(snapshotLogger);
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

  @override
  Future<int> count() {
    return query.count();
  }

  @override
  AggregateQuery aggregate(List<AggregateField> fields) {
    return query.aggregate(fields);
  }
}

class DocumentSnapshotLogger
    with DocumentSnapshotMixin
    implements DocumentSnapshot {
  final DocumentSnapshot snapshot;
  final FirestoreLogger firestoreLogger;

  DocumentSnapshotLogger(this.snapshot, this.firestoreLogger) {
    assert(
        snapshot is! DocumentSnapshotLogger, 'You cannot reference a logger');
  }

  @override
  Timestamp? get createTime => snapshot.createTime;

  @override
  Map<String, Object?> get data => snapshot.data;

  @override
  bool get exists => snapshot.exists;

  @override
  DocumentReferenceLogger get ref =>
      DocumentReferenceLogger(snapshot.ref, firestoreLogger);

  @override
  Timestamp? get updateTime => snapshot.updateTime;
}

class QuerySnapshotLogger implements QuerySnapshot {
  final QuerySnapshot snapshot;
  final FirestoreLogger firestoreLogger;

  QuerySnapshotLogger(this.snapshot, this.firestoreLogger);

  @override
  List<DocumentSnapshot> get docs => snapshot.docs
      .map((doc) => DocumentSnapshotLogger(doc, firestoreLogger))
      .toList();

  @override
  List<DocumentChange> get documentChanges => snapshot.documentChanges
      .map((docChange) => DocumentChangeLogger(docChange, firestoreLogger))
      .toList();
}

class DocumentChangeLogger implements DocumentChange {
  final DocumentChange documentChange;
  final FirestoreLogger firestoreLogger;

  DocumentChangeLogger(this.documentChange, this.firestoreLogger) {
    assert(documentChange is! DocumentChangeLogger,
        'You cannot reference a logger');
  }

  @override
  DocumentSnapshot get document =>
      DocumentSnapshotLogger(documentChange.document, firestoreLogger);

  @override
  int get newIndex => documentChange.newIndex;

  @override
  int get oldIndex => documentChange.oldIndex;

  @override
  DocumentChangeType get type => documentChange.type;
}

class QueryLogger extends QueryLoggerBase implements Query {
  @override
  Firestore get firestore => firestoreLogger;

  QueryLogger(super.query, CollectionReferenceLogger refLogger) {
    this.refLogger = refLogger;
  }
}

class CollectionReferenceLogger extends QueryLoggerBase
    with CollectionReferenceMixin, PathReferenceMixin
    implements CollectionReference, FirestorePathReference {
  @override
  final FirestoreLogger firestoreLogger;

  CollectionReference get ref => query as CollectionReference;

  CollectionReferenceLogger(CollectionReference ref, this.firestoreLogger)
      : super(ref) {
    assert(ref is! CollectionReferenceLogger, 'You cannot reference a logger');
    refLogger = this;
  }

  @override
  Future<DocumentReferenceLogger> add(Map<String, Object?> data) async {
    Object? exception;
    DocumentReferenceLogger? result;
    try {
      result = DocumentReferenceLogger(await ref.add(data), firestoreLogger);
      return result;
    } catch (e) {
      exception = e;
      rethrow;
    } finally {
      if (options.write) {
        options.log(FirestoreLoggerAddEvent(this, data,
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
    with
        DocumentReferenceDefaultMixin,
        DocumentReferenceMixin,
        PathReferenceMixin
    implements DocumentReference, FirestorePathReference {
  final DocumentReference ref;
  final FirestoreLogger firestoreLogger;

  FirestoreLoggerOptions get options => firestoreLogger.options;

  DocumentReferenceLogger(this.ref, this.firestoreLogger) {
    assert(ref is! DocumentReferenceLogger, 'You cannot reference a logger');
  }

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
        options.log(FirestoreLoggerDeleteEvent(this, exception: exception));
      }
    }
  }

  @override
  Firestore get firestore => firestoreLogger;

  @override
  Future<DocumentSnapshotLogger> get() async {
    Object? exception;
    DocumentSnapshotLogger? snapshot;
    try {
      snapshot = DocumentSnapshotLogger(await ref.get(), firestoreLogger);
      return snapshot;
    } catch (e) {
      exception = e;
      rethrow;
    } finally {
      if (options.read) {
        options.log(FirestoreLoggerGetEvent(this,
            exception: exception, snapshot: snapshot));
      }
    }
  }

  //Future<int> count() =>

  @override
  Stream<DocumentSnapshot> onSnapshot({bool includeMetadataChanges = false}) {
    if (options.read) {
      options.log(FirestoreLoggerOnSnapshotTriggerEvent(this));
    }
    return StreamTransformer<DocumentSnapshot, DocumentSnapshot>.fromHandlers(
        handleData: (snapshot, sink) {
      var snapshotLogger = DocumentSnapshotLogger(snapshot, firestoreLogger);
      if (options.read) {
        options.log(FirestoreLoggerOnSnapshotEvent(snapshotLogger));
      }
      sink.add(snapshotLogger);
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
            .log(FirestoreLoggerSetEvent(this, data, exception: exception));
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
            .log(FirestoreLoggerUpdateEvent(this, data, exception: exception));
      }
    }
  }

  @override
  Future<List<CollectionReference>> listCollections() => ref.listCollections();
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
      transaction.delete((ref as DocumentReferenceLogger).ref);
    } catch (e) {
      exception = e;
      rethrow;
    } finally {
      if (options.write) {
        options.log(FirestoreLoggerDeleteEvent(ref as DocumentReferenceLogger,
            exception: exception, tag: _tag));
      }
    }
  }

  @override
  Future<DocumentSnapshot> get(DocumentReference documentRef) async {
    Object? exception;
    DocumentSnapshotLogger? snapshot;
    try {
      snapshot = DocumentSnapshotLogger(
          await transaction.get((documentRef as DocumentReferenceLogger).ref),
          firestoreLogger);
      return snapshot;
    } catch (e) {
      exception = e;
      rethrow;
    } finally {
      if (options.read) {
        options.log(FirestoreLoggerGetEvent(
            documentRef as DocumentReferenceLogger,
            exception: exception,
            snapshot: snapshot,
            tag: _tag));
      }
    }
  }

  @override
  void set(DocumentReference documentRef, Map<String, Object?> data,
      [SetOptions? options]) {
    Object? exception;
    try {
      transaction.set(
          (documentRef as DocumentReferenceLogger).ref, data, options);
    } catch (e) {
      exception = e;
      rethrow;
    } finally {
      if (this.options.write) {
        this.options.log(FirestoreLoggerSetEvent(
            documentRef as DocumentReferenceLogger, data,
            exception: exception, tag: _tag));
      }
    }
  }

  @override
  void update(DocumentReference documentRef, Map<String, Object?> data) {
    Object? exception;
    try {
      transaction.update((documentRef as DocumentReferenceLogger).ref, data);
    } catch (e) {
      exception = e;
      rethrow;
    } finally {
      if (options.write) {
        options.log(FirestoreLoggerUpdateEvent(
            documentRef as DocumentReferenceLogger, data,
            exception: exception, tag: _tag));
      }
    }
  }
}

class FirestoreLogger
    with
        FirebaseAppProductMixin<Firestore>,
        FirestoreDefaultMixin,
        FirestoreMixin
    implements Firestore {
  late final FirestoreServiceLogger serviceLogger;
  final FirestoreLoggerOptions options;
  final Firestore firestore;

  FirestoreLogger(
      {FirestoreServiceLogger? serviceLogger,
      required this.firestore,
      required this.options}) {
    this.serviceLogger = serviceLogger ??
        FirestoreServiceLogger(
            firestoreService: firestore.service, options: options);
    assert(firestore is! FirestoreLogger, 'You cannot log a logger!');
  }

  @override
  WriteBatch batch() => FirestoreLoggerBatch(firestore.batch(), this);

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

  @override
  FirestoreService get service => serviceLogger;

  @override
  Future<List<CollectionReference>> listCollections() =>
      firestore.listCollections();

  @override
  FirebaseApp get app => firestore.app;
}

class FirestoreServiceLogger
    with FirebaseProductServiceMixin<Firestore>, FirestoreServiceDefaultMixin
    implements FirestoreService {
  final FirestoreLoggerOptions options;
  final FirestoreService firestoreService;

  FirestoreServiceLogger(
      {required this.firestoreService, required this.options});

  @override
  Firestore firestore(App app) => getInstance(app, () {
        return FirestoreLogger(
            serviceLogger: this,
            firestore: firestoreService.firestore(app),
            options: options);
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

  @override
  bool get supportsAggregateQueries =>
      firestoreService.supportsAggregateQueries;
}

/// Debug extension for Logger.
extension FirestoreServiceLoggerDebugExt on FirestoreService {
  /// Quick logger wrapper, useful in unit test.
  ///
  /// databaseFactory = databaseFactory.debugQuickLoggerWrapper()
  @Deprecated('Debug/dev mode')
  FirestoreService debugQuickLoggerWrapper() {
    var firestoreService = FirestoreServiceLogger(
        firestoreService: this, options: FirestoreLoggerOptions.all());
    return firestoreService;
  }
}

/// Debug extension for Logger.
extension FirestoreLoggerDebugExt on Firestore {
  /// Quick logger wrapper, useful in unit test.
  ///
  /// databaseFactory = databaseFactory.debugQuickLoggerWrapper()
  @Deprecated('Debug/dev mode')
  Firestore debugQuickLoggerWrapper() {
    var options = FirestoreLoggerOptions.all();
    var firestore = FirestoreLogger(
        serviceLogger:
            FirestoreServiceLogger(firestoreService: service, options: options),
        firestore: this,
        options: options);
    return firestore;
  }
}
