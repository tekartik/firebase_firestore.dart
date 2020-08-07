import 'dart:async';

import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/firestore_service_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore/src/common/reference_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore/src/firestore.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore/src/firestore_common.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore/utils/firestore_mixin.dart';
import 'package:tekartik_firebase_firestore_sim/firestore_sim_message.dart';
import 'package:tekartik_firebase_firestore_sim/src/firestore_sim_common.dart';
import 'package:tekartik_firebase_sim/firebase_sim_client.dart';
import 'package:tekartik_firebase_sim/rpc_message.dart';
import 'package:tekartik_firebase_sim/src/firebase_sim_client.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_sim/src/firebase_sim_common.dart'; // ignore: implementation_imports

class FirestoreServiceSim
    with FirestoreServiceMixin
    implements FirestoreService {
  @override
  Firestore firestore(App app) {
    return getInstance(app, () {
      assert(app is AppSim, 'app not compatible');
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
  Future deleteApp(App app) async {}

  @override
  bool get supportsQuerySnapshotCursor => true;

  @override
  bool get supportsFieldValueArray => false;

  @override
  bool get supportsTrackChanges => true;
}

FirestoreServiceSim _firestoreServiceSim;

FirestoreServiceSim get firestoreServiceSim =>
    _firestoreServiceSim ?? FirestoreServiceSim();

class DocumentDataSim extends DocumentDataMap {}

class DocumentSnapshotSim implements DocumentSnapshot {
  @override
  final DocumentReferenceSim ref;

  @override
  final bool exists;

  final DocumentData documentData;

  DocumentSnapshotSim(this.ref, this.exists, this.documentData,
      {@required this.createTime, @required this.updateTime});

  @override
  Map<String, dynamic> get data => documentData?.asMap();

  @override
  final Timestamp updateTime;

  @override
  final Timestamp createTime;
}

class DocumentReferenceSim
    with DocumentReferenceMixin, PathReferenceImplMixin, PathReferenceMixin
    implements DocumentReference {
  FirestoreSim get firestoreSim => firestore as FirestoreSim;

  DocumentReferenceSim(Firestore firestore, String path) {
    init(firestore, path);
    checkDocumentReferencePath(this.path);
  }

  @override
  CollectionReference collection(String path) =>
      CollectionReferenceSim(firestoreSim, url.join(this.path, path));

  @override
  Future delete() async {
    var simClient = await firestoreSim.simClient;
    var firestoreDeleteData = FirestorePathData()..path = path;
    await simClient.sendRequest(
        methodFirestoreDelete, firestoreDeleteData.toMap());
  }

  @override
  Future<DocumentSnapshot> get() {
    var requestData = FirestoreGetRequestData()..path = path;
    return firestoreSim.get(requestData);
  }

  @override
  Future set(Map<String, dynamic> data, [SetOptions options]) async {
    var jsonMap = documentDataToJsonMap(DocumentData(data));
    var simClient = await firestoreSim.simClient;
    var firestoreSetData = FirestoreSetData()
      ..path = path
      ..data = jsonMap
      ..merge = options?.merge;
    await simClient.sendRequest(methodFirestoreSet, firestoreSetData.toMap());
  }

  @override
  Future update(Map<String, dynamic> data) async {
    var jsonMap = documentDataToJsonMap(DocumentData(data));
    var simClient = await firestoreSim.simClient;
    var firestoreSetData = FirestoreSetData()
      ..path = path
      ..data = jsonMap;
    await simClient.sendRequest(
        methodFirestoreUpdate, firestoreSetData.toMap());
  }

  DocumentSnapshotSim documentSnapshotFromDataMap(
          String path, Map<String, dynamic> map) =>
      firestoreSim.documentSnapshotFromDataMap(path, map);

  // do until cancelled
  Future _getStream(FirebaseSimClient simClient, String path,
      ServerSubscriptionSim subscription) async {
    var subscriptionId = subscription.id;
    while (true) {
      if (firestoreSim._subscriptions.containsKey(subscriptionId)) {
        var result = resultAsMap(await simClient.sendRequest(
            methodFirestoreGetStream, {paramSubscriptionId: subscriptionId}));
        // devPrint(result);
        // null means cancelled
        if (result[paramDone] == true) {
          break;
        }
        subscription.add(firestoreSim.documentSnapshotFromMessageMap(
            path, (result[paramSnapshot] as Map)?.cast<String, dynamic>()));
      } else {
        break;
      }
    }
    subscription.doneCompleter.complete();
  }

  @override
  Stream<DocumentSnapshot> onSnapshot() {
    ServerSubscriptionSim<DocumentSnapshotSim> subscription;
    FirebaseSimClient simClient;
    subscription = ServerSubscriptionSim(StreamController(onCancel: () async {
      await firestoreSim.removeSubscription(subscription);
      await simClient.sendRequest(
          methodFirestoreGetCancel, {paramSubscriptionId: subscription.id});
      await subscription.done;
    }));

    () async {
      simClient = await firestoreSim.simClient;
      var result = resultAsMap(await simClient
          .sendRequest(methodFirestoreGetListen, {paramPath: path}));

      subscription.id = result[paramSubscriptionId] as int;
      firestoreSim.addSubscription(subscription);

      // Loop until cancelled
      await _getStream(simClient, path, subscription);
    }();
    return subscription.stream;
  }
}

abstract class QueryMixinSim implements Query {
  AppSim get appSim => firestoreSim.appSim;

  QueryInfo get queryInfo;

  CollectionReferenceSim get simCollectionReference;

  FirestoreSim get firestoreSim => simCollectionReference.firestoreSim;

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
    List<dynamic> arrayContainsAny,
    List<dynamic> whereIn,
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
            arrayContainsAny: arrayContainsAny,
            whereIn: whereIn,
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

  DocumentSnapshotSim documentSnapshotFromData(
      DocumentSnapshotData documentSnapshotData) {
    return firestoreSim.documentSnapshotFromData(documentSnapshotData);
  }

  @override
  Future<QuerySnapshot> get() async {
    var simClient = await appSim.simClient;
    var data = FirestoreQueryData()
      ..path = simCollectionReference.path
      ..queryInfo = queryInfo;
    var result = resultAsMap(
        await simClient.sendRequest(methodFirestoreQuery, data.toMap()));

    var querySnapshotData = FirestoreQuerySnapshotData()..fromMap(result);
    return QuerySnapshotSim(
        querySnapshotData.list
            .map((DocumentSnapshotData documentSnapshotData) =>
                documentSnapshotFromData(documentSnapshotData))
            .toList(),
        <DocumentChangeSim>[]);
  }

  // do until cancelled
  Future _getStream(
      FirebaseSimClient simClient, ServerSubscriptionSim subscription) async {
    var subscriptionId = subscription.id;
    while (true) {
      if (firestoreSim._subscriptions.containsKey(subscriptionId)) {
        var result = resultAsMap(await simClient.sendRequest(
            methodFirestoreQueryStream, {paramSubscriptionId: subscriptionId}));
        // null means cancelled
        if (result[paramDone] == true) {
          break;
        }

        var querySnapshotData = FirestoreQuerySnapshotData()
          ..fromMap((result[paramSnapshot] as Map)?.cast<String, dynamic>());

        var docs = querySnapshotData.list
            .map((DocumentSnapshotData documentSnapshotData) =>
                documentSnapshotFromData(documentSnapshotData))
            .toList();

        var changes = <DocumentChangeSim>[];
        for (var changeData in querySnapshotData.changes) {
          // snapshot present?
          DocumentSnapshotSim snapshot;
          if (changeData.data != null) {
            snapshot = firestoreSim.documentSnapshotFromDataMap(
                join(simCollectionReference.path, changeData.id),
                changeData.data);
          } else {
            // find in doc
            snapshot = snapshotsFindById(docs, changeData.id);
          }
          final change = DocumentChangeSim(
              documentChangeTypeFromString(changeData.type),
              snapshot,
              changeData.newIndex,
              changeData.oldIndex);
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
  Stream<QuerySnapshot> onSnapshot() {
    FirebaseSimClient simClient;
    ServerSubscriptionSim<QuerySnapshot> subscription;
    subscription = ServerSubscriptionSim(StreamController(onCancel: () async {
      await firestoreSim.removeSubscription(subscription);
      await simClient.sendRequest(
          methodFirestoreQueryCancel, {paramSubscriptionId: subscription.id});
      await subscription.done;
    }));

    () async {
      simClient = await firestoreSim.simClient;

      var data = FirestoreQueryData()
        ..path = simCollectionReference.path
        ..queryInfo = queryInfo;

      var result = resultAsMap(await simClient.sendRequest(
          methodFirestoreQueryListen, data.toMap()));

      subscription.id = result[paramSubscriptionId] as int;
      firestoreSim.addSubscription(subscription);

      // Loop until cancelled
      await _getStream(simClient, subscription);
    }();
    return subscription.stream;
  }
}

class ServerSubscriptionSim<T> {
  // the streamId;
  int id;
  final StreamController<T> _controller;

  // register for notification during the query
  StreamSubscription<Notification> notificationSubscription;

  ServerSubscriptionSim(this._controller);

  Stream<T> get stream => _controller.stream;

  Future close() async {
    await notificationSubscription?.cancel();
    await _controller.close();
  }

  void add(T snapshot) {
    _controller.add(snapshot);
  }

  Completer doneCompleter = Completer();
  Future get done => doneCompleter.future;
}

class DocumentChangeSim implements DocumentChange {
  @override
  final DocumentChangeType type;

  @override
  final DocumentSnapshotSim document;

  @override
  final int newIndex;

  @override
  final int oldIndex;

  DocumentChangeSim(this.type, this.document, this.newIndex, this.oldIndex);
}

class QuerySnapshotSim implements QuerySnapshot {
  final List<DocumentSnapshotSim> simDocs;
  final List<DocumentChangeSim> simDocChanges;

  QuerySnapshotSim(this.simDocs, this.simDocChanges);

  @override
  List<DocumentSnapshot> get docs => simDocs;

  // TODO: implement documentChanges
  @override
  List<DocumentChange> get documentChanges => simDocChanges;
}

class QuerySim extends Object with QueryMixinSim implements Query {
  @override
  final CollectionReferenceSim simCollectionReference;

  @override
  FirestoreSim get firestoreSim => simCollectionReference.firestoreSim;
  @override
  QueryInfo queryInfo;

  QuerySim(this.simCollectionReference);
}

class CollectionReferenceSim extends Object
    with QueryMixinSim
    implements CollectionReference {
  @override
  QueryInfo queryInfo = QueryInfo();

  @override
  CollectionReferenceSim get simCollectionReference => this;
  @override
  final FirestoreSim firestoreSim;

  @override
  final String path;

  CollectionReferenceSim(this.firestoreSim, this.path) {
    checkCollectionReferencePath(path);
  }

  @override
  Future<DocumentReference> add(Map<String, dynamic> data) async {
    var jsonMap = documentDataToJsonMap(DocumentData(data));
    var simClient = await firestoreSim.simClient;
    var firestoreSetData = FirestoreSetData()
      ..path = path
      ..data = jsonMap;
    var result = await simClient.sendRequest(
        methodFirestoreAdd, firestoreSetData.toMap());
    var firestorePathData = FirestorePathData()
      ..fromMap(result as Map<String, dynamic>);
    return DocumentReferenceSim(firestoreSim, firestorePathData.path);
  }

  @override
  DocumentReference doc([String path]) =>
      DocumentReferenceSim(firestoreSim, url.join(this.path, path));

  @override
  String get id => url.basename(path);

  @override
  DocumentReference get parent =>
      DocumentReferenceSim(firestoreSim, url.dirname(path));
}

class FirestoreSim extends Object with FirestoreMixin implements Firestore {
  FirestoreSim(this.firestoreServiceSim, this.appSim);

  final FirestoreServiceSim firestoreServiceSim;
  final AppSim appSim;

  //final transactionLock = Lock();

  FirestoreSettings firestoreSettingsSim;
  // The key is the streamId from the server
  final Map<int, ServerSubscriptionSim> _subscriptions = {};

  Future<FirebaseSimClient> get simClient => appSim.simClient;

  void addSubscription(ServerSubscriptionSim subscription) {
    _subscriptions[subscription.id] = subscription;
  }

  @override
  CollectionReference collection(String path) =>
      CollectionReferenceSim(this, path);

  @override
  DocumentReference doc(String path) => DocumentReferenceSim(this, path);

  Future removeSubscription(ServerSubscriptionSim subscription) async {
    _subscriptions.remove(subscription.id);
    await subscription.close();
  }

  Future close() async {
    var subscriptions = _subscriptions.values.toList();
    for (var subscription in subscriptions) {
      await removeSubscription(subscription);
    }
  }

  DocumentSnapshotSim documentSnapshotFromData(
      FirestoreDocumentSnapshotData documentSnapshotData) {
    var dataMap = documentSnapshotData.data;
    return DocumentSnapshotSim(
        DocumentReferenceSim(this, documentSnapshotData.path),
        dataMap != null,
        documentDataFromJsonMap(this, dataMap),
        createTime: documentSnapshotData.createTime,
        updateTime: documentSnapshotData.updateTime);
    /*
    return documentSnapshotFromDataMap(
        documentSnapshotData.path, documentSnapshotData.data);
        */
  }

  // warning no createTime and update time here
  DocumentSnapshotSim documentSnapshotFromDataMap(
      String path, Map<String, dynamic> map) {
    return DocumentSnapshotSim(DocumentReferenceSim(this, path), map != null,
        documentDataFromJsonMap(this, map),
        createTime: null, updateTime: null);
  }

  DocumentSnapshotSim documentSnapshotFromMessageMap(
      String path, Map<String, dynamic> map) {
    var documentSnapshotData = DocumentSnapshotData.fromMessageMap(map);
    var data = documentSnapshotData.data;
    return DocumentSnapshotSim(DocumentReferenceSim(this, path), data != null,
        documentDataFromJsonMap(this, data),
        createTime: documentSnapshotData.createTime,
        updateTime: documentSnapshotData.updateTime);
  }

  @override
  WriteBatch batch() => WriteBatchSim(this);

  @override
  Future runTransaction(
      Function(Transaction transaction) updateFunction) async {
    var simClient = await this.simClient;
    var result = resultAsMap(
        await simClient.sendRequest(methodFirestoreTransaction, {}));

    var responseData = FirestoreTransactionResponseData()..fromMap(result);
    final transactionSim = TransactionSim(this, responseData.transactionId);
    try {
      await updateFunction(transactionSim);
      await transactionSim.commit();
    } catch (_) {
      // Make sure to clean up on cancel
      await transactionSim.cancel();
      rethrow;
    }
  }

  Future<DocumentSnapshot> get(FirestoreGetRequestData requestData) async {
    var simClient = await this.simClient;
    var result = resultAsMap(
        await simClient.sendRequest(methodFirestoreGet, requestData.toMap()));

    var documentSnapshotData = FirestoreDocumentSnapshotDataImpl()
      ..fromMap(result);
    return DocumentSnapshotSim(
        DocumentReferenceSim(this, documentSnapshotData.path),
        documentSnapshotData.data != null,
        documentDataFromJsonMap(this, documentSnapshotData.data),
        createTime: documentSnapshotData.createTime,
        updateTime: documentSnapshotData.updateTime);
  }

  // This could be optimized
  @override
  Future<List<DocumentSnapshot>> getAll(List<DocumentReference> refs) async =>
      await Future.wait(refs.map((ref) => ref.get()));

  @override
  String toString() => 'FirestoreSim[${identityHashCode(this)}]';
}

class TransactionSim extends WriteBatchSim implements Transaction {
  final int transactionId;

  TransactionSim(FirestoreSim firestore, this.transactionId) : super(firestore);

  @override
  Future<DocumentSnapshot> get(DocumentReference documentRef) {
    var requestData = FirestoreGetRequestData()
      ..path = documentRef.path
      ..transactionId = transactionId;
    return firestore.get(requestData);
  }

  @override
  Future commit() async {
    var batchData = FirestoreBatchData()..transactionId = transactionId;
    await batchCommit(methodFirestoreTransactionCommit, batchData);
  }

  Future cancel() async {
    var requestData = FirestoreTransactionCancelRequestData()
      ..transactionId = transactionId;
    var simClient = await firestore.simClient;
    await simClient.sendRequest(
        methodFirestoreTransactionCancel, requestData.toMap());
  }
}

class WriteBatchSim extends WriteBatchBase {
  final FirestoreSim firestore;

  WriteBatchSim(this.firestore);

  @override
  Future commit() async {
    var batchData = FirestoreBatchData();
    await batchCommit(methodFirestoreBatch, batchData);
  }

  Future batchCommit(String method, FirestoreBatchData batchData) async {
    for (var operation in operations) {
      if (operation is WriteBatchOperationDelete) {
        batchData.operations.add(BatchOperationDeleteData()
          ..method = methodFirestoreDelete
          ..path = operation.docRef.path);
      } else if (operation is WriteBatchOperationSet) {
        batchData.operations.add(BatchOperationSetData()
          ..method = methodFirestoreSet
          ..path = operation.docRef.path
          ..data = documentDataToJsonMap(operation.documentData)
          ..merge = operation.options?.merge);
      } else if (operation is WriteBatchOperationUpdate) {
        batchData.operations.add(BatchOperationUpdateData()
          ..method = methodFirestoreUpdate
          ..path = operation.docRef.path
          ..data = documentDataToJsonMap(operation.documentData));
      } else {
        throw 'not supported $operation';
      }
    }
    var simClient = await firestore.simClient;
    await simClient.sendRequest(method, batchData.toMap());
  }
}
