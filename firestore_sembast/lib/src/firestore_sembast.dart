import 'package:path/path.dart';
import 'package:sembast/sembast.dart' hide Transaction, FieldValue;
import 'package:sembast/sembast.dart' as sembast;
import 'package:sembast/sembast_memory.dart' as sembast;
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_firestore/src/firestore_common.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore/utils/timestamp_utils.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart'
    show newFirestoreServiceSembast;
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:uuid/uuid.dart';

import 'import_firestore.dart';

class FirestoreServiceSembast
    with FirestoreServiceDefaultMixin, FirestoreServiceMixin
    implements FirestoreService {
  @override
  Firestore firestore(App app) {
    return getInstance(app, () {
      return FirestoreSembast(this, app);
    });
  }

  final sembast.DatabaseFactory databaseFactory;

  FirestoreServiceSembast(this.databaseFactory);

  @override
  bool get supportsQuerySelect => true;

  @override
  bool get supportsDocumentSnapshotTime => true;

  @override
  bool get supportsTimestampsInSnapshots => true;

  @override
  bool get supportsTimestamps => true;

  //TODO
  Future deleteApp(App app) async {}

  @override
  bool get supportsQuerySnapshotCursor => true;

  @override
  bool get supportsFieldValueArray => true;

  @override
  bool get supportsTrackChanges => true;
}

FirestoreServiceSembast? _firestoreServiceSembastMemory;

FirestoreServiceSembast get firestoreServiceSembastMemory =>
    _firestoreServiceSembastMemory ??=
        FirestoreServiceSembast(sembast.databaseFactoryMemory);

FirestoreService newFirestoreServiceSembastMemory() =>
    newFirestoreServiceSembast(
        databaseFactory: sembast.newDatabaseFactoryMemory());

dynamic valueToUpdateValue(dynamic value) {
  if (value == FieldValue.delete) {
    return sembast.FieldValue.delete;
  }
  return valueToRecordValue(value, valueToUpdateValue);
}

Map<String, Object?> documentDataToUpdateMap(
    DocumentData documentData, Map<String, Object?> recordMap) {
  var updateMap = <String, Object?>{};
  documentDataMap(documentData)!.map.forEach((String key, value) {
    if (value is FieldValueArray) {
      updateMap[key] = fieldArrayValueMergeValue(value, recordMap[key]);
    } else {
      updateMap[key] = valueToUpdateValue(value);
    }
  });
  return updateMap;
}

// new format
int firestoreSembastDatabaseVersion = 1;

final StoreRef<String, Map<String, Object?>> docStore =
    stringMapStoreFactory.store('doc');

class WriteResultSembast extends WriteResultBase {
  WriteResultSembast(String path) : super(path);

  DocumentSnapshotSembast? get previousSnapshotSembast =>
      previousSnapshot as DocumentSnapshotSembast?;

  DocumentSnapshotSembast? get newSnapshotSembast =>
      newSnapshot as DocumentSnapshotSembast?;
}

class FirestoreSembast extends Object
    with
        FirestoreDefaultMixin,
        FirestoreMixin,
        FirestoreSubscriptionMixin,
        FirestoreDocumentsMixin
    implements Firestore {
  var dbLock = Lock();
  Database? db;
  final FirestoreServiceSembast firestoreService;
  final App app;

  FirestoreSembast(this.firestoreService, this.app);

  String get appLocalPath => ((app is AppLocal)
      ? (app as AppLocal).localPath
      : join('.dart_tool', 'tekartik_firebase_firestore_local',
          AppLocal.appPathPart(app.name)));

  Future close() async {
    await closeSubscriptions();
  }

  String get dbPath => join(appLocalPath, 'firestore.db');

  @override
  CollectionReference collection(String path) {
    return CollectionReferenceSembast(this, path);
  }

  @override
  DocumentReference doc(String path) {
    return DocumentReferenceSembast(this, path);
  }

  Future<Database> get ready async {
    if (db != null) {
      return db!;
    }
    return await dbLock.synchronized(() async {
      if (db == null) {
        // If it is a name (no path, no extension) use it as id

        final name = dbPath;
        print('opening database $name');
        var openedDb = await firestoreService.databaseFactory
            .openDatabase(name, version: firestoreSembastDatabaseVersion,
                onVersionChanged: (db, oldVersion, newVersion) async {
          if (oldVersion == 0) {
            // creating ok
          } else {
            if (oldVersion < firestoreSembastDatabaseVersion) {
              // clear store
              await docStore.delete(db);
            }
          }
        });
        db = openedDb;
        return openedDb;
      } else {
        return db!;
      }
    });
  }

  Future<Map<String, Object?>?> txnGetRecordMap(
      sembast.Transaction txn, String path) async {
    var recordMap = await docStore.record(path).get(txn);
    return recordMap;
  }

  Future<DocumentSnapshotSembast> txnGetDocumentSnapshot(
      sembast.Transaction txn, DocumentReference ref) async {
    final recordMap = await txnGetRecordMap(txn, ref.path);
    return documentFromRecordMap(ref, recordMap) as DocumentSnapshotSembast;
  }

  // return previous data
  Future<WriteResultSembast> txnDelete(
      sembast.Transaction txn, DocumentReference ref) async {
    var result = WriteResultSembast(ref.path);
    result.previousSnapshot = await txnGetDocumentSnapshot(txn, ref);
    await docStore.record(ref.path).delete(txn);
    return result;
  }

  Future<WriteResultSembast> txnSet(
      sembast.Transaction txn, DocumentReference ref, DocumentData documentData,
      [SetOptions? options]) async {
    var result = WriteResultSembast(ref.path);
    var existingRecordMap = await txnGetRecordMap(txn, ref.path);
    result.previousSnapshot = documentFromRecordMap(ref, existingRecordMap);
    Map<String, Object?>? recordMap;

    // Update rev
    final rev = (result.previousSnapshotSembast?.rev ?? 0) + 1;
    // merging?
    if (options?.merge == true) {
      recordMap = documentDataToRecordMap(documentData, existingRecordMap);
    } else {
      // Map needed to handle arrayRemove and arrayUnion
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

    result.newSnapshot = documentFromRecordMap(ref, recordMap!);
    await docStore.record(ref.path).put(txn, recordMap);
    return result;
  }

  Future<WriteResultSembast> txnUpdate(sembast.Transaction txn,
      DocumentReference ref, DocumentData documentData) async {
    var result = WriteResultSembast(ref.path);

    // Need to get first to change rev
    var existingRecordMap = await txnGetRecordMap(txn, ref.path);
    if (existingRecordMap == null) {
      throw Exception('No document found at $ref');
    }
    result.previousSnapshot = documentFromRecordMap(ref, existingRecordMap);

    // Update rev
    var rev = (result.previousSnapshotSembast?.rev ?? 0) + 1;

    var updateMap = <String, Object?>{};
    updateMap[revKey] = rev;
    var now = Timestamp.now();
    updateMap[createTimeKey] =
        (result.previousSnapshot?.createTime ?? now).toIso8601String();
    updateMap[updateTimeKey] = now.toIso8601String();

    var recordMap = await docStore
        .record(ref.path)
        .update(txn, documentDataToUpdateMap(documentData, existingRecordMap));

    result.newSnapshot = documentFromRecordMap(ref, recordMap);
    return result;
  }

  @override
  WriteBatch batch() => WriteBatchSembast(this);

  @override
  Future<T> runTransaction<T>(
      FutureOr<T> Function(Transaction transaction) updateFunction) async {
    var db = await ready;
    late T result;
    var transaction = TransactionSembast(this);
    final results = await db.transaction((txn) async {
      // Initialize the transaction
      transaction.nativeTransaction = txn;

      result = await updateFunction(transaction);
      return await transaction.txnCommit(txn);
    });
    transaction.notify(results);
    return result;
  }

  @override
  DocumentChangeBase documentChange(DocumentChangeType type,
      DocumentSnapshot document, int newIndex, int oldIndex) {
    return DocumentChangeSembast(type, document, newIndex, oldIndex);
  }

  @override
  DocumentSnapshot cloneSnapshot(DocumentSnapshot documentSnapshot) {
    return DocumentSnapshotSembast.fromSnapshot(
        documentSnapshot as DocumentSnapshotSembast);
  }

  @override
  DocumentSnapshot deletedSnapshot(DocumentReference documentReference) {
    return DocumentSnapshotSembast(
        documentReference as DocumentReferenceSembast, null, null);
  }

  @override
  QuerySnapshot newQuerySnapshot(
      List<DocumentSnapshot> docs, List<DocumentChange> changes) {
    return QuerySnapshotSembast(docs, changes);
  }

  @override
  DocumentSnapshot newSnapshot(
      DocumentReference ref, RecordMetaData? meta, DocumentData? data) {
    return DocumentSnapshotSembast(ref, meta, data);
  }

  @override
  FirestoreService get service => firestoreService;
}

class WriteBatchSembast extends WriteBatchBase implements WriteBatch {
  final FirestoreSembast firestore;

  WriteBatchSembast(this.firestore);

  Future<List<WriteResultSembast>> txnCommit(sembast.Transaction txn) async {
    final results = <WriteResultSembast>[];
    for (var operation in operations) {
      if (operation is WriteBatchOperationDelete) {
        results.add(await firestore.txnDelete(txn, operation.docRef!));
      } else if (operation is WriteBatchOperationSet) {
        results.add(await firestore.txnSet(
            txn, operation.docRef!, operation.documentData, operation.options));
      } else if (operation is WriteBatchOperationUpdate) {
        results.add(await firestore.txnUpdate(
            txn, operation.docRef!, operation.documentData));
      } else {
        throw 'not supported $operation';
      }
    }
    return results;
  }

  @override
  Future commit() async {
    var db = await firestore.ready;

    final results = await db.transaction((txn) async {
      return txnCommit(txn);
    });

    notify(results);
  }

  // To use after txtCommit
  void notify(List<WriteResultSembast> results) {
    for (var result in results) {
      firestore.notify(result);
    }
  }
}

// It is basically a batch with gets before in a transaction
class TransactionSembast extends WriteBatchSembast implements Transaction {
  late sembast.Transaction nativeTransaction;

  TransactionSembast(FirestoreSembast firestore) : super(firestore);

  @override
  Future<DocumentSnapshot> get(DocumentReference documentRef) async {
    var snapshot =
        await firestore.txnGetDocumentSnapshot(nativeTransaction, documentRef);
    return snapshot;
  }
}

class DocumentSnapshotSembast extends DocumentSnapshotBase {
  DocumentSnapshotSembast(
      DocumentReference ref, RecordMetaData? meta, DocumentData? documentData,
      {bool? exists})
      : super(ref, meta, documentData, exists: exists);

  DocumentSnapshotSembast.fromSnapshot(DocumentSnapshotSembast snapshot,
      {bool? exists})
      : this(snapshot.ref, snapshot.meta, snapshot.documentData,
            exists: exists ?? snapshot.exists);
}

class DocumentReferenceSembast extends FirestoreReferenceBase
    with AttributesMixin, DocumentReferenceMixin, PathReferenceMixin
    implements DocumentReference {
  DocumentReferenceSembast(Firestore firestore, String path)
      : super(firestore, path) {
    checkDocumentReferencePath(this.path);
  }

  FirestoreSembast get firestoreSembast => firestore as FirestoreSembast;

  @override
  CollectionReference collection(String path) =>
      CollectionReferenceSembast(firestore, url.join(this.path, path));

  @override
  Future delete() async {
    late WriteResultSembast result;
    var db = await firestoreSembast.ready;
    await db.transaction((txn) async {
      result = await firestoreSembast.txnDelete(txn, this);
    });
    // We must either have added or removed it
    if (result.shouldNotify) {
      firestoreSembast.notify(result);
    }
  }

  @override
  Future<DocumentSnapshot> get() async {
    var db = await firestoreSembast.ready;
    var recordMap = await docStore.record(path).get(db);
    // always create a snapshot even if it doest not exist
    return firestoreSembast.documentFromRecordMap(this, recordMap);
  }

  @override
  Future set(Map<String, Object?> data, [SetOptions? options]) async {
    WriteResultBase? result;
    var db = await firestoreSembast.ready;
    await db.transaction((txn) async {
      result =
          await firestoreSembast.txnSet(txn, this, DocumentData(data), options);
    });
    if (result != null) {
      firestoreSembast.notify(result!);
    }
  }

  String get _key => path;

  @override
  Future update(Map<String, Object?> data) async {
    WriteResultSembast? result;

    var db = await firestoreSembast.ready;
    await db.transaction((txn) async {
      var record = await docStore.record(_key).get(txn);
      if (record == null) {
        throw Exception('update failed, record $path does not exit');
      }
      result = await firestoreSembast.txnUpdate(txn, this, DocumentData(data));
    });
    if (result != null) {
      firestoreSembast.notify(result!);
    }
  }

  @override
  String toString() {
    return 'DocumentReferenceSembast($path)';
  }

  @override
  Stream<DocumentSnapshot> onSnapshot({bool includeMetadataChanges = false}) =>
      firestoreSembast.onSnapshot(this);
}

class CollectionReferenceSembast extends QuerySembast
    implements CollectionReference {
  @override
  FirestoreSembast get firestoreSembast => firestore as FirestoreSembast;

  CollectionReferenceSembast(Firestore firestore, String path)
      : super(firestore, path) {
    queryInfo = QueryInfo();
    checkCollectionReferencePath(this.path);
  }

  @override
  DocumentReference doc([String? path]) {
    path ??= _generateId();
    return firestore.doc(url.join(this.path, path));
  }

  String _generateId() => const Uuid().v4().toString();

  @override
  Future<DocumentReference> add(Map<String, Object?> data) async {
    final id = _generateId();
    final path = url.join(this.path, id);

    WriteResultSembast? result;
    var db = await firestoreSembast.ready;
    final documentReference = DocumentReferenceSembast(firestore, path);

    await db.transaction((txn) async {
      result = await firestoreSembast.txnSet(
          txn, firestoreSembast.doc(path), DocumentData(data));
    });
    if (result != null) {
      firestoreSembast.notify(result!);
    }

    return documentReference;
  }

  @override
  DocumentReference? get parent {
    final parentPath = this.parentPath;
    if (parentPath == null) {
      return null;
    } else {
      return DocumentReferenceSembast(firestore, parentPath);
    }
  }

  @override
  int get hashCode => path.hashCode;

  @override
  bool operator ==(other) {
    if (other is CollectionReferenceSembast) {
      if (firestore != (other).firestore) {
        return false;
      }
      if (path != (other).path) {
        return false;
      }
      return true;
    }
    return false;
  }
}

class QuerySembast extends FirestoreReferenceBase
    with FirestoreQueryMixin, AttributesMixin, FirestoreQueryExecutorMixin
    implements Query {
  FirestoreSembast get firestoreSembast => firestore as FirestoreSembast;

  QuerySembast(Firestore firestore, String path) : super(firestore, path);

  @override
  QueryInfo? queryInfo;

  @override
  FirestoreQueryMixin clone() =>
      QuerySembast(firestore, path)..queryInfo = queryInfo?.clone();

  @override
  Future<List<DocumentSnapshot>> getCollectionDocuments() async {
    var db = await firestoreSembast.ready;
    final docs = <DocumentSnapshot>[];
    for (var record in await docStore.find(db)) {
      final recordPath = record.key;
      final parentPath = url.dirname(recordPath);
      if (parentPath == path) {
        docs.add(firestoreSembast.documentFromRecordMap(
            firestoreSembast.doc(recordPath), record.value));
      }
    }
    return docs;
  }
}

class DocumentChangeSembast extends DocumentChangeBase {
  DocumentChangeSembast(DocumentChangeType type, DocumentSnapshot document,
      int newIndex, int oldIndex)
      : super(type, document, newIndex, oldIndex);

  DocumentSnapshotSembast get documentSembast =>
      document as DocumentSnapshotSembast;
}

class QuerySnapshotSembast extends QuerySnapshotBase {
  QuerySnapshotSembast(
      List<DocumentSnapshot> docs, List<DocumentChange> documentChanges)
      : super(docs, documentChanges);
}
