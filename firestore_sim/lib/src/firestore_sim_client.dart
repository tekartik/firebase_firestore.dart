import 'dart:async';

import 'package:path/path.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase/firebase_mixin.dart';
import 'package:tekartik_firebase_firestore/src/firestore_common.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore_sim/src/firestore_sim_common.dart';
import 'package:tekartik_firebase_sim/firebase_sim_mixin.dart';
import 'package:tekartik_firebase_sim/src/firebase_sim_client.dart'; // ignore: implementation_imports

import 'firestore_sim_message.dart';
import 'firestore_sim_server_service.dart';
// ignore: implementation_imports

import 'import_firestore.dart'; // ignore: implementation_imports

/// Firestore service simulator.
class FirestoreServiceSim
    with FirebaseProductServiceMixin<Firestore>, FirestoreServiceDefaultMixin
    implements FirestoreService {
  @override
  Firestore firestore(App app) {
    return getInstance(app, () {
      assert(app is FirebaseAppSim, 'app not compatible');
      return FirestoreSim(this, app as AppSim);
    });
  }

  @override
  bool get supportsQuerySelect => true;

  @override
  bool get supportsDocumentSnapshotTime => true;

  @override
  bool get supportsTimestampsInSnapshots => true;

  @override
  bool get supportsTimestamps => true;

  //TODO
  /// Delete the app.
  Future deleteApp(App app) async {}

  @override
  bool get supportsQuerySnapshotCursor => true;

  @override
  bool get supportsFieldValueArray => false;

  @override
  bool get supportsTrackChanges => true;
}

FirestoreServiceSim? _firestoreServiceSim;

/// Firestore simulator service.
FirestoreServiceSim get firestoreServiceSim =>
    _firestoreServiceSim ?? FirestoreServiceSim();

/// Document data simulator.
class DocumentDataSim extends DocumentDataMap {}

/// Document snapshot simulator.
class DocumentSnapshotSim
    with DocumentSnapshotMixin
    implements DocumentSnapshot {
  @override
  final DocumentReferenceSim ref;

  @override
  final bool exists;

  /// Document data.
  final DocumentData? documentData;

  /// Constructor.
  DocumentSnapshotSim(
    this.ref,
    this.exists,
    this.documentData, {
    required this.createTime,
    required this.updateTime,
  });

  @override
  Map<String, Object?> get data => documentData!.asMap();

  @override
  final Timestamp? updateTime;

  @override
  final Timestamp? createTime;
}

/// Document reference simulator.
class DocumentReferenceSim
    with
        DocumentReferenceDefaultMixin,
        DocumentReferenceMixin,
        PathReferenceImplMixin,
        PathReferenceMixin
    implements DocumentReference {
  /// Firestore simulator.
  FirestoreSim get firestoreSim => firestore as FirestoreSim;

  /// Constructor.
  DocumentReferenceSim(Firestore firestore, String path) {
    init(firestore, path);
    checkDocumentReferencePath(this.path);
  }

  @override
  CollectionReference collection(String path) =>
      CollectionReferenceSim(firestoreSim, url.join(this.path, path));

  @override
  Future delete() async {
    var simClient = await firestoreSim.simAppClient;
    var firestoreDeleteData = CvFirestorePathData()..path.setValue(path);
    await simClient.sendRequest<void>(
      FirestoreSimServerService.serviceName,
      methodFirestoreDelete,
      firestoreDeleteData.toMap(),
    );
  }

  @override
  Future<DocumentSnapshot> get() {
    var requestData = CvFirestoreGetRequestData()..path.setValue(path);
    return firestoreSim.get(requestData);
  }

  @override
  Future set(Map<String, Object?> data, [SetOptions? options]) async {
    var jsonMap = documentDataToJsonMap(DocumentData(data));
    var simClient = await firestoreSim.simAppClient;
    var firestoreSetData = CvFirestoreSetData()
      ..path.setValue(path)
      ..data.setValue(jsonMap)
      ..merge.setValue(options?.merge);
    await simClient.sendRequest<void>(
      FirestoreSimServerService.serviceName,
      methodFirestoreSet,
      firestoreSetData.toMap(),
    );
  }

  @override
  Future update(Map<String, Object?> data) async {
    var jsonMap = documentDataToJsonMap(DocumentData(data));
    var simClient = await firestoreSim.simAppClient;
    var firestoreSetData = FirestoreSetData()
      ..path = path
      ..data = jsonMap;
    await simClient.sendRequest<void>(
      FirestoreSimServerService.serviceName,
      methodFirestoreUpdate,
      firestoreSetData.toMap(),
    );
  }

  /// Documentation for document snapshot.
  DocumentSnapshotSim documentSnapshotFromDataMap(
    String path,
    Map<String, Object?> map,
  ) => firestoreSim.documentSnapshotFromDataMap(path, map);

  // do until cancelled
  Future _getStream(
    FirebaseSimAppClient? simClient,
    String path,
    ServerSubscriptionSim subscription,
  ) async {
    var subscriptionId = subscription.id;
    while (true) {
      if (firestoreSim._subscriptions.containsKey(subscriptionId)) {
        var result = resultAsMap(
          await simClient!.sendRequest<Object?>(
            FirestoreSimServerService.serviceName,
            methodFirestoreGetStream,
            {paramSubscriptionId: subscriptionId},
          ),
        );
        // devPrint(result);
        // null means cancelled
        if (result[paramDone] == true) {
          break;
        }
        subscription.add(
          firestoreSim.documentSnapshotFromMessageMap(
            path,
            (result[paramSnapshot] as Map).cast<String, dynamic>(),
          ),
        );
      } else {
        break;
      }
    }
    subscription.doneCompleter.complete();
  }

  @override
  Stream<DocumentSnapshot> onSnapshot({bool includeMetadataChanges = false}) {
    late ServerSubscriptionSim<DocumentSnapshot> subscription;
    FirebaseSimAppClient? simClient;
    subscription = ServerSubscriptionSim<DocumentSnapshot>(
      StreamController(
        onCancel: () async {
          await firestoreSim.removeSubscription(subscription);
          await simClient!.sendRequest<void>(
            FirestoreSimServerService.serviceName,
            methodFirestoreGetCancel,
            {paramSubscriptionId: subscription.id},
          );
          await subscription.done;
        },
      ),
    );

    () async {
      simClient = await firestoreSim.simAppClient;
      var result = resultAsMap(
        await simClient!.sendRequest<Object>(
          FirestoreSimServerService.serviceName,
          methodFirestoreGetListen,
          {paramPath: path},
        ),
      );

      subscription.id = result[paramSubscriptionId] as int?;
      firestoreSim.addSubscription(subscription);

      // Loop until cancelled
      await _getStream(simClient, path, subscription);
    }();
    return subscription.stream;
  }
}

/// Query mixin simulator.
abstract mixin class QueryMixinSim implements Query {
  /// App simulator.
  AppSim get appSim => firestoreSim.appSim;

  /// Query info.
  QueryInfo? get queryInfo;

  /// Simulation collection reference.
  CollectionReferenceSim get simCollectionReference;

  /// Firestore simulator.
  FirestoreSim get firestoreSim => simCollectionReference.firestoreSim;

  /// Clone the query.
  QuerySim clone() {
    return QuerySim(simCollectionReference)..queryInfo = queryInfo?.clone();
  }

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
    ..queryInfo!.addWhere(
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

  /// Add order by.
  void addOrderBy(String key, String directionStr) {
    var orderBy = OrderByInfo(
      fieldPath: key,
      ascending: directionStr != orderByDescending,
    );
    queryInfo!.orderBys.add(orderBy);
  }

  @override
  Query startAt({DocumentSnapshot? snapshot, List? values}) =>
      clone()..queryInfo!.startAt(snapshot: snapshot, values: values);

  @override
  Query startAfter({DocumentSnapshot? snapshot, List? values}) =>
      clone()..queryInfo!.startAfter(snapshot: snapshot, values: values);

  @override
  Query endAt({DocumentSnapshot? snapshot, List? values}) =>
      clone()..queryInfo!.endAt(snapshot: snapshot, values: values);

  @override
  Query endBefore({DocumentSnapshot? snapshot, List? values}) =>
      clone()..queryInfo!.endBefore(snapshot: snapshot, values: values);

  @override
  Query select(List<String> list) {
    return clone()..queryInfo!.selectKeyPaths = list;
  }

  @override
  Query limit(int limit) => clone()..queryInfo!.limit = limit;

  @override
  Query orderBy(String key, {bool? descending}) => clone()
    ..addOrderBy(
      key,
      descending == true ? orderByDescending : orderByAscending,
    );

  /// Internal document snapshot from data.
  DocumentSnapshotSim documentSnapshotFromData(
    DocumentSnapshotData documentSnapshotData,
  ) {
    return firestoreSim.documentSnapshotFromData(documentSnapshotData);
  }

  @override
  Future<QuerySnapshot> get() async {
    var simClient = await appSim.simAppClient;
    var data = FirestoreQueryData()
      ..path = simCollectionReference.path
      ..queryInfo = queryInfo;
    var result = resultAsMap(
      await simClient.sendRequest<Map>(
        FirestoreSimServerService.serviceName,
        methodFirestoreQuery,
        data.toMap(),
      ),
    );

    var querySnapshotData = FirestoreQuerySnapshotData()..fromMap(result);
    return QuerySnapshotSim(
      querySnapshotData.list
          .map(
            (DocumentSnapshotData documentSnapshotData) =>
                documentSnapshotFromData(documentSnapshotData),
          )
          .toList(),
      <DocumentChangeSim>[],
    );
  }

  // do until cancelled
  Future _getStream(
    FirebaseSimAppClient? simClient,
    ServerSubscriptionSim subscription,
  ) async {
    var subscriptionId = subscription.id;
    while (true) {
      if (firestoreSim._subscriptions.containsKey(subscriptionId)) {
        var result = resultAsMap(
          await simClient!.sendRequest<Map>(
            FirestoreSimServerService.serviceName,
            methodFirestoreQueryStream,
            {paramSubscriptionId: subscriptionId},
          ),
        );
        // null means cancelled
        if (result[paramDone] == true) {
          break;
        }

        var querySnapshotData = FirestoreQuerySnapshotData()
          ..fromMap((result[paramSnapshot] as Map).cast<String, dynamic>());

        var docs = querySnapshotData.list
            .map(
              (DocumentSnapshotData documentSnapshotData) =>
                  documentSnapshotFromData(documentSnapshotData),
            )
            .toList();

        var changes = <DocumentChangeSim>[];
        for (var changeData in querySnapshotData.changes!) {
          // snapshot present?
          DocumentSnapshotSim? snapshot;
          if (changeData.data != null) {
            snapshot = firestoreSim.documentSnapshotFromDataMap(
              url.join(simCollectionReference.path, changeData.id),
              changeData.data,
            );
          } else {
            // find in doc
            snapshot = snapshotsFindById(docs, changeData.id);
          }
          final change = DocumentChangeSim(
            documentChangeTypeFromString(changeData.type!)!,
            snapshot!,
            changeData.newIndex ?? -1, // -1 for removed event
            changeData.oldIndex ?? -1, // -1 for added event
          );
          changes.add(change);
        }
        var snapshot = QuerySnapshotSim(docs, changes);
        subscription.add(snapshot);
      } else {
        break;
      }
    }
    subscription.doneCompleter.complete();
  }

  @override
  Stream<QuerySnapshot> onSnapshot({bool includeMetadataChanges = false}) {
    FirebaseSimAppClient? simClient;
    late ServerSubscriptionSim<QuerySnapshot> subscription;
    subscription = ServerSubscriptionSim<QuerySnapshot>(
      StreamController(
        onCancel: () async {
          await firestoreSim.removeSubscription(subscription);
          await simClient!.sendRequest<void>(
            FirestoreSimServerService.serviceName,
            methodFirestoreQueryCancel,
            {paramSubscriptionId: subscription.id},
          );
          await subscription.done;
        },
      ),
    );

    () async {
      simClient = await firestoreSim.simAppClient;

      var data = FirestoreQueryData()
        ..path = simCollectionReference.path
        ..queryInfo = queryInfo;

      var result = resultAsMap(
        await simClient!.sendRequest<Map>(
          FirestoreSimServerService.serviceName,
          methodFirestoreQueryListen,
          data.toMap(),
        ),
      );

      subscription.id = result[paramSubscriptionId] as int?;
      firestoreSim.addSubscription(subscription);

      // Loop until cancelled
      await _getStream(simClient, subscription);
    }();
    return subscription.stream;
  }
}

/// Document change simulator.
class DocumentChangeSim implements DocumentChange {
  @override
  final DocumentChangeType type;

  @override
  final DocumentSnapshotSim document;

  @override
  final int newIndex;

  @override
  final int oldIndex;

  /// Constructor.
  DocumentChangeSim(this.type, this.document, this.newIndex, this.oldIndex);
}

/// Query snapshot simulator.
class QuerySnapshotSim implements QuerySnapshot {
  /// Simulation documents.
  final List<DocumentSnapshotSim> simDocs;

  /// Simulation document changes.
  final List<DocumentChangeSim> simDocChanges;

  /// Constructor.
  QuerySnapshotSim(this.simDocs, this.simDocChanges);

  @override
  List<DocumentSnapshot> get docs => simDocs;

  // TODO: implement documentChanges
  @override
  List<DocumentChange> get documentChanges => simDocChanges;
}

/// Query simulator.
class QuerySim extends Object
    with QueryDefaultMixin, QueryMixinSim, FirestoreQueryExecutorMixin
    implements Query {
  @override
  final CollectionReferenceSim simCollectionReference;

  @override
  FirestoreSim get firestoreSim => simCollectionReference.firestoreSim;
  @override
  QueryInfo? queryInfo;

  /// Constructor.
  QuerySim(this.simCollectionReference);

  @override
  Firestore get firestore => firestoreSim;
}

/// Collection reference simulator.
class CollectionReferenceSim extends Object
    with
        QueryDefaultMixin,
        QueryMixinSim,
        FirestoreQueryExecutorMixin,
        CollectionReferenceMixin,
        PathReferenceMixin
    implements CollectionReference {
  @override
  QueryInfo queryInfo = QueryInfo();

  @override
  CollectionReferenceSim get simCollectionReference => this;
  @override
  final FirestoreSim firestoreSim;

  @override
  final String path;

  /// Constructor.
  CollectionReferenceSim(this.firestoreSim, this.path) {
    checkCollectionReferencePath(path);
  }

  @override
  Future<DocumentReference> add(Map<String, Object?> data) async {
    var jsonMap = documentDataToJsonMap(DocumentData(data));
    var simClient = await firestoreSim.simAppClient;
    var firestoreSetData = FirestoreSetData()
      ..path = path
      ..data = jsonMap;
    var result = await simClient.sendRequest<Map>(
      FirestoreSimServerService.serviceName,
      methodFirestoreAdd,
      firestoreSetData.toMap(),
    );
    var firestorePathData = FirestorePathData()
      ..fromMap(result as Map<String, Object?>);
    return DocumentReferenceSim(firestoreSim, firestorePathData.path);
  }

  @override
  DocumentReference doc([String? path]) =>
      DocumentReferenceSim(firestoreSim, url.join(this.path, path));

  @override
  String get id => url.basename(path);

  @override
  int get hashCode => path.hashCode;

  @override
  bool operator ==(other) {
    if (other is CollectionReference) {
      if (path != (other).path) {
        return false;
      }
      return true;
    }
    return false;
  }

  @override
  Firestore get firestore => firestoreSim;
}

/// Firestore simulator.
class FirestoreSim extends Object
    with
        FirebaseAppProductMixin<Firestore>,
        FirestoreDefaultMixin,
        FirestoreMixin
    implements Firestore {
  /// Constructor.
  FirestoreSim(this.firestoreServiceSim, this.appSim);

  /// Firestore simulator service.
  final FirestoreServiceSim firestoreServiceSim;

  /// App simulator.
  final AppSim appSim;

  //final transactionLock = Lock();

  /// Firestore settings simulator.
  FirestoreSettings? firestoreSettingsSim;

  // The key is the streamId from the server
  final Map<int, ServerSubscriptionSim> _subscriptions = {};

  /// Simulator app client.
  Future<FirebaseSimAppClient> get simAppClient => appSim.simAppClient;

  /// Add a subscription.
  void addSubscription(ServerSubscriptionSim subscription) {
    _subscriptions[subscription.id!] = subscription;
  }

  @override
  CollectionReference collection(String path) =>
      CollectionReferenceSim(this, path);

  @override
  DocumentReference doc(String path) => DocumentReferenceSim(this, path);

  /// Remove a subscription.
  Future removeSubscription(ServerSubscriptionSim subscription) async {
    _subscriptions.remove(subscription.id);
    await subscription.close();
  }

  /// Close the simulator.
  Future close() async {
    var subscriptions = _subscriptions.values.toList();
    for (var subscription in subscriptions) {
      await removeSubscription(subscription);
    }
  }

  /// Internal document snapshot from data.
  DocumentSnapshotSim documentSnapshotFromData(
    FirestoreDocumentSnapshotData documentSnapshotData,
  ) {
    var dataMap = documentSnapshotData.data;
    return DocumentSnapshotSim(
      DocumentReferenceSim(this, documentSnapshotData.path),
      dataMap != null,
      documentDataFromJsonMap(this, dataMap),
      createTime: documentSnapshotData.createTime,
      updateTime: documentSnapshotData.updateTime,
    );
    /*
    return documentSnapshotFromDataMap(
        documentSnapshotData.path, documentSnapshotData.data);
        */
  }

  // warning no createTime and update time here
  /// Documentation for document snapshot.
  DocumentSnapshotSim documentSnapshotFromDataMap(
    String path,
    Map<String, Object?>? map,
  ) {
    return DocumentSnapshotSim(
      DocumentReferenceSim(this, path),
      map != null,
      documentDataFromJsonMap(this, map),
      createTime: null,
      updateTime: null,
    );
  }

  /// Documentation for document snapshot.
  DocumentSnapshotSim documentSnapshotFromMessageMap(
    String path,
    Map<String, Object?> map,
  ) {
    var documentSnapshotData = DocumentSnapshotData.fromMessageMap(map);
    var data = documentSnapshotData.data;
    return DocumentSnapshotSim(
      DocumentReferenceSim(this, path),
      data != null,
      documentDataFromJsonMap(this, data),
      createTime: documentSnapshotData.createTime,
      updateTime: documentSnapshotData.updateTime,
    );
  }

  @override
  WriteBatch batch() => WriteBatchSim(this);

  @override
  Future<T> runTransaction<T>(
    FutureOr<T> Function(Transaction transaction) updateFunction,
  ) async {
    var simClient = await simAppClient;
    var result = resultAsMap(
      await simClient.sendRequest<Map>(
        FirestoreSimServerService.serviceName,
        methodFirestoreTransaction,
        <String, Object?>{},
      ),
    );

    var responseData = FirestoreTransactionResponseData()..fromMap(result);
    final transactionSim = TransactionSim(this, responseData.transactionId);
    late T updateResult;
    try {
      updateResult = await updateFunction(transactionSim);
    } catch (_) {
      // Make sure to clean up on cancel
      await transactionSim.cancel();
      rethrow;
    }
    await transactionSim.commit();
    return updateResult;
  }

  /// Get a document.
  Future<DocumentSnapshot> get(CvFirestoreGetRequestData requestData) async {
    var simClient = await simAppClient;
    var result = resultAsMap(
      await simClient.sendRequest<Map>(
        FirestoreSimServerService.serviceName,
        methodFirestoreGet,
        requestData.toMap(),
      ),
    );

    var documentSnapshotData = FirestoreDocumentSnapshotDataImpl()
      ..fromMap(result);
    return DocumentSnapshotSim(
      DocumentReferenceSim(this, documentSnapshotData.path),
      documentSnapshotData.data != null,
      documentDataFromJsonMap(this, documentSnapshotData.data),
      createTime: documentSnapshotData.createTime,
      updateTime: documentSnapshotData.updateTime,
    );
  }

  @override
  String toString() => 'FirestoreSim[${identityHashCode(this)}]';

  @override
  FirestoreService get service => firestoreServiceSim;

  @override
  FirebaseApp get app => appSim;
}

/// Transaction simulator.
class TransactionSim extends WriteBatchSim implements Transaction {
  /// Transaction id.
  final int? transactionId;

  /// Constructor.
  TransactionSim(super.firestore, this.transactionId);

  int? get _appId => firestore.appSim.appServerId;
  @override
  Future<DocumentSnapshot> get(DocumentReference documentRef) {
    var requestData = CvFirestoreGetRequestData()
      ..appId.setValue(_appId)
      ..path.setValue(documentRef.path)
      ..transactionId.setValue(transactionId);
    return firestore.get(requestData);
  }

  @override
  Future commit() async {
    var batchData = FirestoreBatchData()..transactionId = transactionId;
    await batchCommit(methodFirestoreTransactionCommit, batchData);
  }

  /// Cancel the transaction.
  Future cancel() async {
    var requestData = FirestoreTransactionCancelRequestData()
      ..transactionId = transactionId;
    var simClient = await firestore.simAppClient;
    await simClient.sendRequest<void>(
      FirestoreSimServerService.serviceName,
      methodFirestoreTransactionCancel,
      requestData.toMap(),
    );
  }
}

/// Write batch simulator.
class WriteBatchSim extends WriteBatchBase {
  /// Firestore simulator.
  final FirestoreSim firestore;

  /// Constructor.
  WriteBatchSim(this.firestore);

  @override
  Future commit() async {
    var batchData = FirestoreBatchData();
    await batchCommit(methodFirestoreBatch, batchData);
  }

  /// Commit the batch.
  Future batchCommit(String method, FirestoreBatchData batchData) async {
    for (var operation in operations) {
      if (operation is WriteBatchOperationDelete) {
        batchData.operations.add(
          BatchOperationDeleteData()
            ..method = methodFirestoreDelete
            ..path = operation.docRef!.path,
        );
      } else if (operation is WriteBatchOperationSet) {
        batchData.operations.add(
          BatchOperationSetData()
            ..method = methodFirestoreSet
            ..path = operation.docRef!.path
            ..data = documentDataToJsonMap(operation.documentData)
            ..merge = operation.options?.merge,
        );
      } else if (operation is WriteBatchOperationUpdate) {
        batchData.operations.add(
          BatchOperationUpdateData()
            ..method = methodFirestoreUpdate
            ..path = operation.docRef!.path
            ..data = documentDataToJsonMap(operation.documentData),
        );
      } else {
        throw 'not supported $operation';
      }
    }
    var simClient = await firestore.simAppClient;
    await simClient.sendRequest<void>(
      FirestoreSimServerService.serviceName,
      method,
      batchData.toMap(),
    );
  }
}
