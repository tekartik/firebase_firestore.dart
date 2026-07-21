import 'package:idb_shim/sdb.dart';
import 'package:path/path.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_firestore/utils/document_data.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:uuid/uuid.dart';

import 'import_common.dart';
import 'import_firestore.dart';

/// SDB firestore service.
class FirestoreServiceSdb
    with FirebaseProductServiceMixin<Firestore>, FirestoreServiceDefaultMixin
    implements FirestoreService {
  @override
  Firestore firestore(App app) {
    return getInstance(app, () {
      assert(app is AppLocal, 'invalid firebase app type');
      final appLocal = app as AppLocal;
      return FirestoreSdb(appLocal, this);
    });
  }

  /// SDB Factory.
  final SdbFactory sdbFactory;

  /// Constructor.
  FirestoreServiceSdb(this.sdbFactory);

  @override
  bool get supportsQuerySelect => true;

  @override
  bool get supportsDocumentSnapshotTime => true;

  @override
  bool get supportsTimestampsInSnapshots => true;

  @override
  bool get supportsTimestamps => true;

  @override
  bool get supportsQuerySnapshotCursor => true;

  @override
  bool get supportsFieldValueArray => true;

  @override
  bool get supportsTrackChanges => true;

  @override
  bool get supportsVectorValue => true;

  @override
  bool get supportsBlobs => true;
}

/// Create a firestore service from SDB factory.
FirestoreService getFirestoreService(SdbFactory sdbFactory) =>
    FirestoreServiceSdb(sdbFactory);

/// SDB Firestore implementation.
class FirestoreSdb extends Object
    with
        FirebaseAppProductMixin<Firestore>,
        FirestoreDefaultMixin,
        FirestoreMixin,
        FirestoreSubscriptionMixin,
        FirestoreDocumentsMixin
    implements Firestore {
  /// Local app.
  final AppLocal appLocal;

  /// Firestore SDB service.
  final FirestoreServiceSdb firestoreServiceSdb;

  /// Underlying SdbFactory.
  SdbFactory get sdbFactory => firestoreServiceSdb.sdbFactory;

  SdbDatabase? _database;

  /// Document store reference.
  final docStore = SdbStoreRef<String, SdbModel>('documents');

  /// Database is ready future or value.
  FutureOr<SdbDatabase> get databaseReady {
    if (_database != null) {
      return _database!;
    }
    return () async {
      var dbPath = join(appLocal.localPath, 'firestore', 'firestore.sdb');
      try {
        var db = await sdbFactory.openDatabase(
          dbPath,
          options: SdbOpenDatabaseOptions(
            version: 1,
            onVersionChange: (event) {
              var oldVersion = event.oldVersion;
              if (oldVersion == 0) {
                event.db.createStore(docStore);
              }
            },
          ),
        );

        _database = db;
        return db;
      } catch (e) {
        throw Exception('Failed to open database $dbPath: $e');
      }
    }();
  }

  /// Constructor.
  FirestoreSdb(this.appLocal, this.firestoreServiceSdb);

  @override
  CollectionReference collection(String path) =>
      CollectionReferenceSdb(this, path);

  @override
  DocumentReference doc(String path) => getDocumentRef(path);

  /// Get document reference.
  DocumentReferenceSdb getDocumentRef(String path) =>
      DocumentReferenceSdb(this, path);

  @override
  WriteBatch batch() => WriteBatchSdb(this);

  @override
  Future<T> runTransaction<T>(
    FutureOr<T> Function(Transaction transaction) updateFunction,
  ) async {
    var db = await databaseReady;
    return await db.inStoreTransaction(docStore, SdbTransactionMode.readWrite, (
      txn,
    ) async {
      var localTransaction = LocalTransactionSdb(this, txn);
      var txnSdb = TransactionSdb(this, localTransaction);
      var result = await updateFunction(txnSdb);
      localTransaction.notify();
      return result;
    });
  }

  /// Add a document.
  Future<DocumentReferenceSdb> add(
    String path,
    Map<String, Object?> data,
  ) async {
    var db = await databaseReady;
    var documentRef = getDocumentRef(url.join(path, _generateId()));
    await db.inStoreTransaction(docStore, SdbTransactionMode.readWrite, (
      txn,
    ) async {
      var localTransaction = LocalTransactionSdb(this, txn);
      await txnSet(localTransaction, documentRef, DocumentData(data), null);
      localTransaction.notify();
    });
    return documentRef;
  }

  /// Set a document snapshot.
  Future<DocumentReferenceSdb> setDocument(
    DocumentReferenceSdb documentRef,
    DocumentData documentData,
    SetOptions? options,
  ) async {
    var db = await databaseReady;
    await db.inStoreTransaction(docStore, SdbTransactionMode.readWrite, (
      txn,
    ) async {
      var localTransaction = LocalTransactionSdb(this, txn);
      await txnSet(localTransaction, documentRef, documentData, options);
      localTransaction.notify();
    });
    return documentRef;
  }

  /// Update a document snapshot.
  Future<DocumentReferenceSdb> updateDocument(
    DocumentReferenceSdb documentRef,
    DocumentData documentData,
  ) async {
    var db = await databaseReady;
    await db.inStoreTransaction(docStore, SdbTransactionMode.readWrite, (
      txn,
    ) async {
      var localTransaction = LocalTransactionSdb(this, txn);
      await txnUpdate(localTransaction, documentRef, documentData);
      localTransaction.notify();
    });
    return documentRef;
  }

  /// Delete a document snapshot.
  Future deleteDocument(DocumentReferenceSdb documentReferenceSdb) async {
    var db = await databaseReady;
    await db.inStoreTransaction(docStore, SdbTransactionMode.readWrite, (
      txn,
    ) async {
      var localTransaction = LocalTransactionSdb(this, txn);
      await txnDelete(localTransaction, documentReferenceSdb);
      localTransaction.notify();
    });
  }

  /// Transaction delete.
  Future<WriteResultSdb> txnDelete(
    LocalTransactionSdb localTransaction,
    DocumentReferenceSdb ref,
  ) async {
    var result = WriteResultSdb(ref.path);
    var txn = localTransaction.transaction;
    var snapshot = await txnGet(localTransaction, ref);
    result.previousSnapshot = snapshot;
    await docStore.record(ref.path).delete(txn);
    localTransaction.results.add(result);
    return result;
  }

  /// Transaction get.
  Future<DocumentSnapshotSdb> txnGet(
    LocalTransactionSdb localTransaction,
    DocumentReferenceSdb documentReferenceSdb,
  ) async {
    var txn = localTransaction.transaction;
    var value = await docStore.record(documentReferenceSdb.path).get(txn);
    final recordMap = value?.value;
    return DocumentSnapshotSdb(
      documentReferenceSdb,
      recordMap == null ? null : RecordMetaData.fromRecordMap(recordMap),
      documentDataFromRecordMap(this, recordMap),
    );
  }

  /// Get document.
  Future<DocumentSnapshotSdb> getDocument(
    DocumentReferenceSdb documentRef,
  ) async {
    var db = await databaseReady;
    var value = await docStore.record(documentRef.path).get(db);
    final recordMap = value?.value;
    return DocumentSnapshotSdb(
      documentRef,
      recordMap == null ? null : RecordMetaData.fromRecordMap(recordMap),
      documentDataFromRecordMap(this, recordMap),
    );
  }

  /// Transaction set.
  Future<WriteResultSdb> txnSet(
    LocalTransactionSdb localTransaction,
    DocumentReferenceSdb documentRef,
    DocumentData documentData,
    SetOptions? options,
  ) async {
    var result = WriteResultSdb(documentRef.path);
    var txn = localTransaction.transaction;
    var snapshot = await txnGet(localTransaction, documentRef);
    result.previousSnapshot = snapshot;

    Map<String, Object?>? recordMap;

    // Update rev
    final rev = (snapshot.rev ?? 0) + 1;

    DocumentData newDocumentData;
    // merging?
    if (options?.merge == true) {
      if (snapshot.exists) {
        newDocumentData = DocumentData(
          cloneMap(snapshot.data).cast<String, Object?>(),
        );
      } else {
        newDocumentData = DocumentData();
      }
      newDocumentData.merge(documentData);
      recordMap = newDocumentData.toJsonRecordValueMap();
    } else {
      recordMap = documentData.toJsonRecordValueMap();
    }

    recordMap[revKey] = rev;

    // set update Time
    var now = Timestamp.now();
    recordMap[createTimeKey] = (result.previousSnapshot?.createTime ?? now)
        .toIso8601String();
    recordMap[updateTimeKey] = now.toIso8601String();

    result.newSnapshot = documentFromRecordMap(documentRef, recordMap);

    await docStore.record(documentRef.path).put(txn, recordMap);
    localTransaction.results.add(result);
    return result;
  }

  /// Transaction update.
  Future<WriteResultSdb> txnUpdate(
    LocalTransactionSdb localTransaction,
    DocumentReferenceSdb documentRef,
    DocumentData documentData,
  ) async {
    var result = WriteResultSdb(documentRef.path);
    var txn = localTransaction.transaction;
    var snapshot = await txnGet(localTransaction, documentRef);
    if (!snapshot.exists) {
      throw Exception(
        'update failed, record ${documentRef.path} does not exist',
      );
    }
    result.previousSnapshot = snapshot;

    var map = cloneMap(snapshot.data);
    map = recordMapUpdate(map, documentData)!;

    // Update rev
    final rev = (snapshot.rev ?? 0) + 1;
    map[revKey] = rev;

    var now = Timestamp.now();
    map[createTimeKey] = (result.previousSnapshot?.createTime ?? now)
        .toIso8601String();
    map[updateTimeKey] = now.toIso8601String();

    result.newSnapshot = documentFromRecordMap(documentRef, map);

    await docStore.record(documentRef.path).put(txn, map);
    localTransaction.results.add(result);
    return result;
  }

  @override
  DocumentChangeBase documentChange(
    DocumentChangeType type,
    DocumentSnapshot document,
    int newIndex,
    int oldIndex,
  ) {
    return DocumentChangeSdb(type, document, newIndex, oldIndex);
  }

  @override
  DocumentSnapshot cloneSnapshot(DocumentSnapshot documentSnapshot) {
    return DocumentSnapshotSdb.fromSnapshot(
      documentSnapshot as DocumentSnapshotSdb,
    );
  }

  @override
  DocumentSnapshot deletedSnapshot(DocumentReference documentReference) {
    return DocumentSnapshotSdb(documentReference, null, null);
  }

  @override
  QuerySnapshot newQuerySnapshot(
    List<DocumentSnapshot> docs,
    List<DocumentChange> changes,
  ) {
    return QuerySnapshotSdb(docs, changes);
  }

  @override
  DocumentSnapshot newSnapshot(
    DocumentReference ref,
    RecordMetaData? meta,
    DocumentData? data,
  ) {
    return DocumentSnapshotSdb(ref, meta, data as DocumentDataMap?);
  }

  @override
  FirestoreService get service => firestoreServiceSdb;

  @override
  FirebaseApp get app => appLocal;
}

/// SDB Local Transaction.
class LocalTransactionSdb {
  /// SDB Firestore.
  final FirestoreSdb firestoreSdb;

  /// Underlying transaction.
  final SdbTransaction transaction;

  /// Result list.
  final List<WriteResultSdb> results = [];

  /// Constructor.
  LocalTransactionSdb(this.firestoreSdb, this.transaction);

  /// Notify change listeners.
  void notify() {
    for (var result in results) {
      firestoreSdb.notify(result);
    }
  }
}

/// Transaction SDB.
class TransactionSdb extends WriteBatchSdb implements Transaction {
  /// Local transaction.
  final LocalTransactionSdb localTransaction;

  /// Constructor.
  TransactionSdb(super.firestore, this.localTransaction);

  @override
  void delete(DocumentReference documentRef) {
    localTransaction.firestoreSdb.txnDelete(
      localTransaction,
      documentRef as DocumentReferenceSdb,
    );
  }

  @override
  Future<DocumentSnapshot> get(DocumentReference documentRef) async =>
      localTransaction.firestoreSdb.txnGet(
        localTransaction,
        documentRef as DocumentReferenceSdb,
      );

  @override
  void set(
    DocumentReference documentRef,
    Map<String, Object?> data, [
    SetOptions? options,
  ]) {
    localTransaction.firestoreSdb.txnSet(
      localTransaction,
      documentRef as DocumentReferenceSdb,
      DocumentData(data),
      options,
    );
  }

  @override
  void update(DocumentReference documentRef, Map<String, Object?> data) {
    localTransaction.firestoreSdb.txnUpdate(
      localTransaction,
      documentRef as DocumentReferenceSdb,
      DocumentData(data),
    );
  }
}

/// Document snapshot SDB.
class DocumentSnapshotSdb extends DocumentSnapshotBase {
  /// Constructor.
  DocumentSnapshotSdb(
    super.ref,
    super.meta,
    DocumentDataMap? super.documentData, {
    super.exists,
  });

  /// Clone from snapshot.
  DocumentSnapshotSdb.fromSnapshot(DocumentSnapshotSdb snapshot, {bool? exists})
    : this(
        snapshot.ref,
        snapshot.meta,
        snapshot.documentData as DocumentDataMap?,
        exists: exists ?? snapshot.exists,
      );
}

/// Document reference SDB.
class DocumentReferenceSdb
    with
        DocumentReferenceDefaultMixin,
        DocumentReferenceMixin,
        PathReferenceMixin
    implements DocumentReference {
  /// Underlying firestore SDB.
  final FirestoreSdb firestoreSdb;

  @override
  final String path;

  /// Constructor.
  DocumentReferenceSdb(this.firestoreSdb, this.path) {
    checkDocumentReferencePath(path);
  }

  @override
  CollectionReference collection(String path) =>
      CollectionReferenceSdb(firestoreSdb, url.join(this.path, path));

  @override
  Future delete() => firestoreSdb.deleteDocument(this);

  @override
  Future<DocumentSnapshot> get() async => firestoreSdb.getDocument(this);

  @override
  String get id => url.basename(path);

  @override
  CollectionReference get parent => firestoreSdb.collection(url.dirname(path));

  @override
  Future set(Map<String, Object?> data, [SetOptions? options]) async =>
      firestoreSdb.setDocument(this, DocumentData(data), options);

  @override
  Future update(Map<String, Object?> data) =>
      firestoreSdb.updateDocument(this, DocumentData(data));

  @override
  Stream<DocumentSnapshot> onSnapshot({bool includeMetadataChanges = false}) =>
      firestoreSdb.onSnapshot(this);

  @override
  Firestore get firestore => firestoreSdb;

  @override
  int get hashCode => path.hashCode;

  @override
  bool operator ==(other) {
    if (other is DocumentReference) {
      if (path != other.path) {
        return false;
      }
      return true;
    }
    return false;
  }
}

/// Query snapshot SDB.
class QuerySnapshotSdb extends QuerySnapshotBase {
  /// Constructor.
  QuerySnapshotSdb(super.docs, super.documentChanges);
}

/// Document change SDB.
class DocumentChangeSdb extends DocumentChangeBase {
  /// Constructor.
  DocumentChangeSdb(super.type, super.document, super.newIndex, super.oldIndex);
}

/// Query SDB.
class QuerySdb extends FirestoreReferenceBase
    with
        QueryDefaultMixin,
        FirestoreQueryMixin,
        AttributesMixin,
        FirestoreQueryExecutorMixin
    implements Query {
  /// Firestore SDB.
  FirestoreSdb get firestoreSdb => firestore as FirestoreSdb;

  @override
  QueryInfo? queryInfo;

  /// Constructor.
  QuerySdb(super.firestore, super.path) {
    checkCollectionReferencePath(path);
  }

  @override
  FirestoreQueryMixin clone() =>
      QuerySdb(firestore, path)..queryInfo = queryInfo?.clone();

  @override
  Future<List<DocumentSnapshot>> getCollectionDocuments() async {
    var db = await firestoreSdb.databaseReady;
    var records = await firestoreSdb.docStore.findRecords(
      db,
      boundaries: SdbBoundaries.lowerValue(path),
    );
    var docs = <DocumentSnapshot>[];
    for (var record in records) {
      final docPath = record.key;
      if (!docPath.startsWith(path)) {
        break;
      }
      if (dirname(docPath) == path) {
        docs.add(
          firestoreSdb.documentFromRecordMap(
            firestoreSdb.doc(docPath),
            record.value,
          ),
        );
      }
    }
    return docs;
  }
}

/// Collection reference SDB.
class CollectionReferenceSdb extends QuerySdb implements CollectionReference {
  /// Constructor.
  CollectionReferenceSdb(FirestoreSdb super.firestoreSdb, super.path) {
    queryInfo = QueryInfo();
  }

  @override
  Future<DocumentReference> add(Map<String, Object?> data) async =>
      firestoreSdb.add(path, data);

  @override
  DocumentReference doc([String? path]) {
    path ??= _generateId();
    return firestore.doc(url.join(this.path, path));
  }

  @override
  DocumentReference? get parent {
    final parentPath = this.parentPath;
    if (parentPath == null) {
      return null;
    } else {
      return DocumentReferenceSdb(firestoreSdb, parentPath);
    }
  }

  @override
  int get hashCode => path.hashCode;

  @override
  bool operator ==(other) {
    if (other is CollectionReference) {
      if (path != other.path) {
        return false;
      }
      return true;
    }
    return false;
  }
}

/// SDB Write Result.
class WriteResultSdb extends WriteResultBase {
  /// Constructor.
  WriteResultSdb(super.path);
}

/// Write Batch SDB.
class WriteBatchSdb extends WriteBatchBase implements WriteBatch {
  /// Firestore SDB.
  final FirestoreSdb firestore;

  /// Constructor.
  WriteBatchSdb(this.firestore);

  /// Transaction commit.
  Future<List<WriteResultSdb>> txnCommit(LocalTransactionSdb txn) async {
    final results = <WriteResultSdb>[];
    for (var operation in operations) {
      if (operation is WriteBatchOperationDelete) {
        results.add(
          await firestore.txnDelete(
            txn,
            operation.docRef as DocumentReferenceSdb,
          ),
        );
      } else if (operation is WriteBatchOperationSet) {
        results.add(
          await firestore.txnSet(
            txn,
            operation.docRef as DocumentReferenceSdb,
            operation.documentData,
            operation.options,
          ),
        );
      } else if (operation is WriteBatchOperationUpdate) {
        results.add(
          await firestore.txnUpdate(
            txn,
            operation.docRef as DocumentReferenceSdb,
            operation.documentData,
          ),
        );
      } else {
        throw UnsupportedError('not supported $operation');
      }
    }
    return results;
  }

  @override
  Future commit() async {
    var db = await firestore.databaseReady;
    await db.inStoreTransaction(
      firestore.docStore,
      SdbTransactionMode.readWrite,
      (txn) async {
        var localTransaction = LocalTransactionSdb(firestore, txn);
        await txnCommit(localTransaction);
        localTransaction.notify();
      },
    );
  }
}

String _generateId() => const Uuid().v4().toString();
