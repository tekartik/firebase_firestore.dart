import 'dart:async';

import 'package:idb_shim/idb.dart' as idb;
import 'package:path/path.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_firestore/utils/document_data.dart';
import 'package:tekartik_firebase_firestore/utils/json_utils.dart';
import 'package:tekartik_firebase_firestore/utils/timestamp_utils.dart';
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:uuid/uuid.dart';

import 'import_firestore.dart';

const String parentIndexName = 'parentIndex';

class FirestoreServiceIdb
    with FirestoreServiceDefaultMixin, FirestoreServiceMixin
    implements FirestoreService {
  @override
  Firestore firestore(App app) {
    return getInstance(app, () {
      assert(app is AppLocal, 'invalid firebase app type');
      final appLocal = app as AppLocal;
      return FirestoreIdb(appLocal, this);
    });
  }

  final idb.IdbFactory idbFactory;

  FirestoreServiceIdb(this.idbFactory);

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
  bool get supportsTrackChanges => false;
}

FirestoreService getFirestoreService(idb.IdbFactory idbFactory) =>
    FirestoreServiceIdb(idbFactory);

class FirestoreIdb extends Object
    with
        FirestoreDefaultMixin,
        FirestoreMixin,
        FirestoreSubscriptionMixin,
        FirestoreDocumentsMixin
    implements Firestore {
  final AppLocal appLocal;
  final FirestoreServiceIdb firestoreServiceIdb;

  idb.IdbFactory get idbFactory => firestoreServiceIdb.idbFactory;
  idb.Database? _database;

  FutureOr<idb.Database>? get databaseReady {
    if (_database != null) {
      return _database;
    }
    return idbFactory.open(appLocal.localPath, version: 1,
        onUpgradeNeeded: (idb.VersionChangeEvent versionChangeEvent) {
      // devPrint('old version ${versionChangeEvent.oldVersion}');
      // Just on object store
      if (versionChangeEvent.oldVersion == 0) {
        versionChangeEvent.database.createObjectStore(storeName);
      }
    }).then((idb.Database database) {
      _database = database;
      return _database!;
    });
  }

  FirestoreIdb(this.appLocal, this.firestoreServiceIdb);

  @override
  CollectionReference collection(String path) =>
      CollectionReferenceIdb(this, path);

  @override
  DocumentReference doc(String path) => getDocumentRef(path);

  DocumentReferenceIdb getDocumentRef(String path) =>
      DocumentReferenceIdb(this, path);

  @override
  WriteBatch batch() => WriteBatchIdb(this);

  @override
  Future<T> runTransaction<T>(
      FutureOr<T> Function(Transaction transaction) updateFunction) async {
    var localTransaction = await getReadWriteTransaction();
    var txn = TransactionIdb(this, localTransaction);
    var result = await updateFunction(txn);
    await localTransaction.completed;
    localTransaction.notify();
    return result;
  }

  Future<DocumentReferenceIdb> add(
      String path, Map<String, Object?> data) async {
    var documentData = DocumentData(data);
    var localTransaction = await getReadWriteTransaction();
    var txn = localTransaction.transaction;
    var documentRef = getDocumentRef(url.join(path, _generateId()));
    await txn
        .objectStore(storeName)
        .add(documentDataToJsonMap(documentData)!, documentRef.path);
    await txn.completed;
    return documentRef;
  }

  Future<DocumentReferenceIdb> setDocument(DocumentReferenceIdb documentRef,
      DocumentData documentData, SetOptions? options) async {
    var localTransaction = await getReadWriteTransaction();
    await txnSet(localTransaction, documentRef, documentData, options);
    await localTransaction.completed;
    return documentRef;
  }

  Future<DocumentReferenceIdb> updateDocument(
      DocumentReferenceIdb documentRef, DocumentData documentData) async {
    var localTransaction = await getReadWriteTransaction();
    await txnUpdate(localTransaction, documentRef, documentData);
    await localTransaction.completed;
    return documentRef;
  }

  String get storeName => 'documents';

  Future<LocalTransaction> getReadWriteTransaction() async {
    final db = await databaseReady!;
    var txn = db.transaction(storeName, idb.idbModeReadWrite);
    final localTransaction = LocalTransaction(this, txn);
    return localTransaction;
  }

  Future deleteDocument(DocumentReferenceIdb documentReferenceIdb) async {
    var localTransaction = await getReadWriteTransaction();
    await txnDelete(localTransaction, documentReferenceIdb);
    await localTransaction.completed;
  }

  Future<WriteResultIdb> txnDelete(
      LocalTransaction localTransaction, DocumentReferenceIdb ref) {
    var result = WriteResultIdb(ref.path);
    var txn = localTransaction.transaction;
    // read the previous one for the notifications
    return txnGet(localTransaction, ref).then((snapshot) {
      result.previousSnapshot = snapshot;
      return txn.objectStore(storeName).delete(ref.path);
    }).then((_) {
      return result;
    });
  }

  Future<DocumentSnapshotIdb> txnGet(LocalTransaction localTransaction,
      DocumentReferenceIdb documentReferenceIdb) {
    var txn = localTransaction.transaction;
    return txn
        .objectStore(storeName)
        .getObject(documentReferenceIdb.path)
        .then((value) {
      // we assume it is always a map
      final recordMap = (value as Map?)?.cast<String, Object?>();

      return DocumentSnapshotIdb(
          documentReferenceIdb,
          recordMap == null ? null : RecordMetaData.fromRecordMap(recordMap),
          documentDataFromRecordMap(this, recordMap));
    });
  }

  Future<DocumentSnapshotIdb> getDocument(
      DocumentReferenceIdb documentRef) async {
    var localTransaction = await getReadWriteTransaction();
    return txnGet(localTransaction, documentRef);
  }

  Future<WriteResultIdb> txnSet(
      LocalTransaction localTransaction,
      DocumentReferenceIdb documentRef,
      DocumentData documentData,
      SetOptions? options) {
    var result = WriteResultIdb(documentRef.path);
    var txn = localTransaction.transaction;
    return txnGet(localTransaction, documentRef).then((snapshot) {
      result.previousSnapshot = snapshot;

      Map<String, Object?>? recordMap;

      // Update rev
      final rev = (snapshot.rev ?? 0) + 1;
      // merging?
      if (options?.merge == true && snapshot.exists) {
        recordMap = documentDataToRecordMap(documentData, snapshot.data);
      } else {
        recordMap = documentDataToRecordMap(documentData);
      }

      if (recordMap != null) {
        recordMap[revKey] = rev;
      }

      // set update Time
      if (recordMap != null) {
        var now = Timestamp.now();
        recordMap[createTimeKey] =
            (result.previousSnapshot?.createTime ?? now).toIso8601String();
        recordMap[updateTimeKey] = now.toIso8601String();
      }

      result.newSnapshot = documentFromRecordMap(documentRef, recordMap);

      // TODO
      return txn
          .objectStore(storeName)
          .put(recordMap!, documentRef.path)
          .then((_) {
        return result;
      });
    });
  }

  Future<WriteResultIdb> txnUpdate(LocalTransaction localTransaction,
      DocumentReferenceIdb documentRef, DocumentData documentData) {
    var result = WriteResultIdb(documentRef.path);
    return txnGet(localTransaction, documentRef)
        .then((DocumentSnapshotIdb snapshotIdb) {
      Map<String, Object?>? map = snapshotIdb.data;
      map = recordMapUpdate(map, documentData);
      return localTransaction.transaction
          .objectStore(storeName)
          .put(map!, documentRef.path)
          .then((_) {
        return result;
      });
    });
  }

  @override
  DocumentChangeBase documentChange(DocumentChangeType type,
      DocumentSnapshot document, int newIndex, int oldIndex) {
    return DocumentChangeIdb(type, document, newIndex, oldIndex);
  }

  @override
  DocumentSnapshot cloneSnapshot(DocumentSnapshot documentSnapshot) {
    return DocumentSnapshotIdb.fromSnapshot(
        documentSnapshot as DocumentSnapshotIdb);
  }

  @override
  DocumentSnapshot deletedSnapshot(DocumentReference documentReference) {
    return DocumentSnapshotIdb(documentReference, null, null);
  }

  @override
  QuerySnapshot newQuerySnapshot(
      List<DocumentSnapshot> docs, List<DocumentChange> changes) {
    return QuerySnapshotIdb(docs, changes);
  }

  @override
  DocumentSnapshot newSnapshot(
      DocumentReference ref, RecordMetaData? meta, DocumentData? data) {
    return DocumentSnapshotIdb(ref, meta, data as DocumentDataMap?);
  }

  @override
  FirestoreService get service => firestoreServiceIdb;
}

class LocalTransaction {
  final FirestoreIdb firestoreIdb;
  final idb.Transaction transaction;
  final List<WriteResultIdb> results = [];

  LocalTransaction(this.firestoreIdb, this.transaction);

  Future get completed => transaction.completed;

  void notify() {
    // To use after txtCommit
    for (var result in results) {
      firestoreIdb.notify(result);
    }
  }
}

class TransactionIdb extends WriteBatchIdb implements Transaction {
  final LocalTransaction localTransaction;

  TransactionIdb(FirestoreIdb firestoreIdb, this.localTransaction)
      : super(firestoreIdb);

  @override
  void delete(DocumentReference documentRef) {
    localTransaction.firestoreIdb
        .txnDelete(localTransaction, documentRef as DocumentReferenceIdb);
  }

  @override
  Future<DocumentSnapshot> get(DocumentReference documentRef) async =>
      localTransaction.firestoreIdb
          .txnGet(localTransaction, documentRef as DocumentReferenceIdb);

  @override
  void set(DocumentReference documentRef, Map<String, Object?> data,
      [SetOptions? options]) {
    localTransaction.firestoreIdb.txnSet(localTransaction,
        documentRef as DocumentReferenceIdb, DocumentData(data), options);
  }

  @override
  void update(DocumentReference documentRef, Map<String, Object?> data) {
    localTransaction.firestoreIdb.txnUpdate(localTransaction,
        documentRef as DocumentReferenceIdb, DocumentData(data));
  }
}

dynamic valueToUpdateValue(dynamic value) {
  if (value == FieldValue.delete) {
    throw 'TODO';
    // return sembast.FieldValue.delete;
  }
  return valueToRecordValue(value, valueToUpdateValue);
}

class DocumentSnapshotIdb extends DocumentSnapshotBase {
  DocumentSnapshotIdb(DocumentReference ref, RecordMetaData? meta,
      DocumentDataMap? documentData,
      {bool? exists})
      : super(ref, meta, documentData, exists: exists);

  DocumentSnapshotIdb.fromSnapshot(DocumentSnapshotIdb snapshot, {bool? exists})
      : this(
          snapshot.ref,
          snapshot.meta,
          snapshot.documentData as DocumentDataMap?,
          exists: exists ?? snapshot.exists,
        );
}

class DocumentReferenceIdb
    with
        DocumentReferenceDefaultMixin,
        DocumentReferenceMixin,
        PathReferenceMixin
    implements DocumentReference {
  final FirestoreIdb firestoreIdb;

  @override
  final String path;

  DocumentReferenceIdb(this.firestoreIdb, this.path) {
    checkDocumentReferencePath(path);
  }

  @override
  CollectionReference collection(String path) =>
      CollectionReferenceIdb(firestoreIdb, url.join(this.path, path));

  @override
  Future delete() => firestoreIdb.deleteDocument(this);

  @override
  Future<DocumentSnapshot> get() async => firestoreIdb.getDocument(this);

  @override
  String get id => url.basename(path);

  @override
  CollectionReference get parent => firestoreIdb.collection(url.dirname(path));

  @override
  Future set(Map<String, Object?> data, [SetOptions? options]) async =>
      firestoreIdb.setDocument(this, DocumentData(data), options);

  @override
  Future update(Map<String, Object?> data) =>
      firestoreIdb.updateDocument(this, DocumentData(data));

  @override
  Stream<DocumentSnapshot> onSnapshot({bool includeMetadataChanges = false}) =>
      firestoreIdb.onSnapshot(this);

  @override
  Firestore get firestore => firestoreIdb;

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

class QuerySnapshotIdb extends QuerySnapshotBase {
  QuerySnapshotIdb(
      List<DocumentSnapshot> docs, List<DocumentChange> documentChanges)
      : super(docs, documentChanges);
}

class DocumentChangeIdb extends DocumentChangeBase {
  DocumentChangeIdb(DocumentChangeType type, DocumentSnapshot document,
      int newIndex, int oldIndex)
      : super(type, document, newIndex, oldIndex);
}

class QueryIdb extends FirestoreReferenceBase
    with FirestoreQueryMixin, AttributesMixin, FirestoreQueryExecutorMixin
    implements Query {
  FirestoreIdb get firestoreIdb => firestore as FirestoreIdb;

  @override
  QueryInfo? queryInfo;

  QueryIdb(Firestore firestore, String path) : super(firestore, path) {
    checkCollectionReferencePath(this.path);
  }

  @override
  FirestoreQueryMixin clone() =>
      QueryIdb(firestore, path)..queryInfo = queryInfo?.clone();

  @override
  @override
  Future<List<DocumentSnapshot>> getCollectionDocuments() async {
    var localTransaction = await firestoreIdb.getReadWriteTransaction();
    var txn = localTransaction.transaction;
    var docs = <DocumentSnapshot>[];
    // We start with the key with the given path
    await txn
        .objectStore(firestoreIdb.storeName)
        .openCursor(range: idb.KeyRange.lowerBound(path), autoAdvance: false)
        .listen((cwv) {
      final docPath = cwv.key as String;
      if (dirname(docPath) == path) {
        docs.add(firestoreIdb.documentFromRecordMap(firestoreIdb.doc(docPath),
            (cwv.value as Map).cast<String, Object?>()));
      }
      // continue
      cwv.next();

      // else otherwise just stop
    }).asFuture<void>();
    return docs;
  }
}

class CollectionReferenceIdb extends QueryIdb implements CollectionReference {
  CollectionReferenceIdb(FirestoreIdb firestoreIdb, String path)
      : super(firestoreIdb, path) {
    queryInfo = QueryInfo();
  }

  @override
  Future<DocumentReference> add(Map<String, Object?> data) async =>
      firestoreIdb.add(path, data);

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
      return DocumentReferenceIdb(firestoreIdb, parentPath);
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

class WriteResultIdb extends WriteResultBase {
  WriteResultIdb(String path) : super(path);
}

class WriteBatchIdb extends WriteBatchBase implements WriteBatch {
  final FirestoreIdb firestore;

  WriteBatchIdb(this.firestore);

  Future<List<WriteResultIdb>> txnCommit(LocalTransaction txn) async {
    final results = <WriteResultIdb>[];
    for (var operation in operations) {
      if (operation is WriteBatchOperationDelete) {
        results.add(await firestore.txnDelete(
            txn, operation.docRef as DocumentReferenceIdb));
      } else if (operation is WriteBatchOperationSet) {
        results.add(await firestore.txnSet(
            txn,
            operation.docRef as DocumentReferenceIdb,
            operation.documentData,
            operation.options));
      } else if (operation is WriteBatchOperationUpdate) {
        results.add(await firestore.txnUpdate(txn,
            operation.docRef as DocumentReferenceIdb, operation.documentData));
      } else {
        throw 'not supported $operation';
      }
    }
    return results;
  }

  @override
  Future commit() async {
    var localTransaction = await firestore.getReadWriteTransaction();
    var results = await txnCommit(localTransaction);
    await localTransaction.completed;
    notify(results);
  }

  // To use after txtCommit
  void notify(List<WriteResultIdb> results) {
    for (var result in results) {
      firestore.notify(result);
    }
  }
}

String _generateId() => const Uuid().v4().toString();
