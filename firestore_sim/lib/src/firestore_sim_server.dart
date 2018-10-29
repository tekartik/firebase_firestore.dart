import 'dart:async';
import 'dart:core' hide Error;

import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/firestore_common.dart';
import 'package:tekartik_firebase_firestore_sim/firestore_sim_message.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:tekartik_firebase_sim/src/firebase_sim_common.dart';
import 'package:tekartik_firebase_sim/src/firebase_sim_server.dart';
//import 'package:tekartik_firebase_sim/rpc_message.dart';

class SimSubscription<T> {
  final int id;
  final StreamSubscription<T> _firestoreSubscription;
  final List<T> _list = [];

  void add(T data) {
    _list.add(data);
    if (completer != null) {
      completer.complete();
    }
  }

  bool cancelled = false;
  Completer<T> completer;

  Future<T> get next async {
    if (cancelled) {
      return null;
    }
    if (_list.isNotEmpty) {
      var data = _list.first;
      _list.removeAt(0);
      return data;
    }
    completer = Completer();
    await completer.future;
    return await next;
  }

  SimSubscription(this.id, this._firestoreSubscription);

  // Make sure to cancel the pending completer
  cancel() {
    cancelled = true;
    _firestoreSubscription.cancel();
    if (!completer.isCompleted) {
      completer.complete(null);
    }
  }
}

class FirestireSimPluginClient implements FirebaseSimPluginClient {
  final FirestoreSimServer firestoreSimServer;
  final Firestore firestore;
  int lastTransactionId = 0;
  int lastSubscriptionId = 0;
  Lock get transactionLock => firestoreSimServer.transactionLock(firestore);
  final rpc.Server rpcServer;
  final Map<int, SimSubscription> subscriptions = <int, SimSubscription>{};

  int get newSubscriptionId => ++lastSubscriptionId;

  DocumentReference requestDocumentReference(Map<String, dynamic> params) {
    var firestorePathData = FirestorePathData()..fromMap(params);
    var ref = firestore.doc(firestorePathData.path);
    return ref;
  }

  FirestireSimPluginClient(
      this.firestoreSimServer, this.firestore, this.rpcServer) {
    rpcServer.registerMethod(methodFirestoreAdd,
        (rpc.Parameters parameters) async {
      return await handleFirestoreAddRequest(rpcParams(parameters));
    });
    rpcServer.registerMethod(methodFirestoreSet,
        (rpc.Parameters parameters) async {
      return await handleFirestoreSetRequest(rpcParams(parameters));
    });
    rpcServer.registerMethod(methodFirestoreDelete,
        (rpc.Parameters parameters) async {
      return await handleFirestoreDeleteRequest(rpcParams(parameters));
    });

    rpcServer.registerMethod(methodFirestoreGet,
        (rpc.Parameters parameters) async {
      return await handleFirestoreGetRequest(rpcParams(parameters));
    });
    rpcServer.registerMethod(methodFirestoreGetListen,
        (rpc.Parameters parameters) async {
      return await handleFirestoreGetListen(parameters);
    });
    rpcServer.registerMethod(methodFirestoreGetStream,
        (rpc.Parameters parameters) async {
      return await handleFirestoreGetStream(parameters);
    });
    rpcServer.registerMethod(methodFirestoreGetCancel,
        (rpc.Parameters parameters) async {
      return await handleFirestoreGetCancel(parameters);
    });

    rpcServer.registerMethod(methodFirestoreQuery,
        (rpc.Parameters parameters) async {
      return await handleFirestoreQuery(parameters);
    });
    rpcServer.registerMethod(methodFirestoreQueryListen,
        (rpc.Parameters parameters) async {
      return await handleFirestoreQueryListen(parameters);
    });
    rpcServer.registerMethod(methodFirestoreQueryStream,
        (rpc.Parameters parameters) async {
      return await handleFirestoreQueryStream(parameters);
    });
    rpcServer.registerMethod(methodFirestoreQueryCancel,
        (rpc.Parameters parameters) async {
      return await handleFirestoreQueryCancel(parameters);
    });

    rpcServer.registerMethod(methodFirestoreUpdate,
        (rpc.Parameters parameters) async {
      return await handleFirestoreUpdateRequest(parameters);
    });

    rpcServer.registerMethod(methodFirestoreBatch,
        (rpc.Parameters parameters) async {
      return await handleFirestoreBatch(parameters);
    });

    rpcServer.registerMethod(methodFirestoreTransaction,
        (rpc.Parameters parameters) async {
      return await handleFirestoreTransaction(rpcParams(parameters));
    });

    rpcServer.registerMethod(methodFirestoreTransactionCancel,
        (rpc.Parameters parameters) async {
      return await handleFirestoreTransactionCancel(rpcParams(parameters));
    });
    rpcServer.registerMethod(methodFirestoreTransactionCommit,
        (rpc.Parameters parameters) async {
      return await handleFirestoreTransactionCommit(rpcParams(parameters));
    });
  }

  Future handleFirestoreAddRequest(Map<String, dynamic> params) async {
    var firestoreSetData = FirestoreSetData()..fromMap(params);
    var documentData =
        documentDataFromJsonMap(firestore, firestoreSetData.data);

    return await transactionLock.synchronized(() async {
      var docRef = await firestore
          .collection(firestoreSetData.path)
          .add(documentData.asMap());

      return (FirestorePathData()..path = docRef.path).toMap();
    });
  }

  Future handleFirestoreGetRequest(Map<String, dynamic> params) async {
    var firestoreGetRequesthData = FirestoreGetRequestData()..fromMap(params);
    var ref = requestDocumentReference(params);
    var transactionId = firestoreGetRequesthData.transactionId;

    // Current transaction, read as is
    DocumentSnapshot documentSnapshot;
    if (transactionId == lastTransactionId) {
      documentSnapshot = await ref.get();
    } else {
      // otherwise lock
      await transactionLock.synchronized(() async {
        documentSnapshot = await ref.get();
      });
    }
    var snapshotData = DocumentGetSnapshotData.fromSnapshot(documentSnapshot);
    return snapshotData.toMap();
  }

  Future handleFirestoreSetRequest(Map<String, dynamic> params) async {
    var firestoreSetData = FirestoreSetData()..fromMap(params);
    var documentData =
        documentDataFromJsonMap(firestore, firestoreSetData.data);
    SetOptions options;
    if (firestoreSetData.merge != null) {
      options = SetOptions(merge: firestoreSetData.merge);
    }

    await transactionLock.synchronized(() async {
      await firestore
          .doc(firestoreSetData.path)
          .set(documentData.asMap(), options);
    });
  }

  Future handleFirestoreUpdateRequest(rpc.Parameters parameters) async {
    var firestoreSetData = FirestoreSetData()..fromMap(rpcParams(parameters));
    var documentData =
        documentDataFromJsonMap(firestore, firestoreSetData.data);

    await transactionLock.synchronized(() async {
      await firestore.doc(firestoreSetData.path).update(documentData.asMap());
    });
  }

  Future handleFirestoreDeleteRequest(Map<String, dynamic> params) async {
    var firestoreDeleteData = FirestorePathData()..fromMap(params);

    await transactionLock.synchronized(() async {
      await firestore.doc(firestoreDeleteData.path).delete();
    });
  }

  Future handleFirestoreGetListen(rpc.Parameters parameters) async {
    var subscriptionId = newSubscriptionId;
    String path = parameters[paramPath]?.value as String;
    return await transactionLock.synchronized(() async {
      var ref = firestore.doc(path);

      SimSubscription subscription;
      // ignore: cancel_subscriptions
      StreamSubscription<DocumentSnapshot> streamSubscription =
          ref.onSnapshot().listen((DocumentSnapshot snapshot) {
        subscription.add(snapshot);
      });
      subscriptions[subscriptionId] =
          subscription = SimSubscription(subscriptionId, streamSubscription);
      return {paramSubscriptionId: subscriptionId};
    });
  }

  Future handleFirestoreGetCancel(rpc.Parameters parameters) async {
    var subscriptionId = parameters[paramSubscriptionId]?.value as int;
    var subscription = subscriptions[subscriptionId];
    subscriptions.remove(subscriptionId);
    await subscription.cancel();
  }

  Future handleFirestoreGetStream(rpc.Parameters parameters) async {
    // New stream?
    var subscriptionId = parameters[paramSubscriptionId].value as int;
    var subscription = subscriptions[subscriptionId];
    try {
      DocumentSnapshot snapshot = await subscription.next;
      var data = DocumentSnapshotData.fromSnapshot(snapshot);
      return data.toMap();
    } catch (_) {}
  }

  Future handleFirestoreQuery(rpc.Parameters parameters) async {
    var queryData = FirestoreQueryData()
      ..firestoreFromMap(firestore, rpcParams(parameters));
    Query query = await getQuery(queryData);

    return await transactionLock.synchronized(() async {
      var querySnapshot = await query.get();

      var data = FirestoreQuerySnapshotData();
      data.list = <DocumentSnapshotData>[];
      for (DocumentSnapshot doc in querySnapshot.docs) {
        data.list.add(DocumentSnapshotData.fromSnapshot(doc));
      }
      return data.toMap();
    });
  }

  Future handleFirestoreQueryListen(rpc.Parameters parameters) async {
    var subscriptionId = newSubscriptionId;
    var queryData = FirestoreQueryData()
      ..firestoreFromMap(firestore, rpcParams(parameters));
    return await transactionLock.synchronized(() async {
      Query query = await getQuery(queryData);

      SimSubscription subscription;
      // ignore: cancel_subscriptions
      StreamSubscription<QuerySnapshot> streamSubscription =
          query.onSnapshot().listen((QuerySnapshot querySnapshot) {
        subscription.add(querySnapshot);
      });
      subscriptions[subscriptionId] =
          subscription = SimSubscription(subscriptionId, streamSubscription);
      return {paramSubscriptionId: subscriptionId};
    });
  }

  Future handleFirestoreQueryCancel(rpc.Parameters parameters) async {
    var subscriptionId = parameters[paramSubscriptionId]?.value as int;
    var subscription = subscriptions[subscriptionId];
    subscriptions.remove(subscriptionId);
    await subscription.cancel();
  }

  Future handleFirestoreQueryStream(rpc.Parameters parameters) async {
    // New stream?
    var subscriptionId = parameters[paramSubscriptionId].value as int;
    var subscription = subscriptions[subscriptionId];
    try {
      QuerySnapshot querySnapshot = await subscription.next;
      var data = FirestoreQuerySnapshotData();
      data.list = <DocumentSnapshotData>[];
      for (DocumentSnapshot doc in querySnapshot.docs) {
        data.list.add(DocumentSnapshotData.fromSnapshot(doc));
      }
      // Changes
      data.changes = <DocumentChangeData>[];
      for (var change in querySnapshot.documentChanges) {
        var documentChangeData = DocumentChangeData()
          ..id = change.document.ref.id
          ..type = documentChangeTypeToString(change.type)
          ..newIndex = change.newIndex
          ..oldIndex = change.oldIndex;
        // need data?
        var path = change.document.ref.path;

        _find() {
          for (var doc in querySnapshot.docs) {
            if (doc.ref.path == path) {
              return true;
            }
          }
          return false;
        }

        if (!_find()) {
          documentChangeData.data =
              documentDataToJsonMap(documentDataFromSnapshot(change.document));
        }
        data.changes.add(documentChangeData);
      }
      return data.toMap();
    } catch (_) {}
  }

  Future<Query> getQuery(FirestoreQueryData queryData) async {
    var collectionPath = queryData.path;

    Query query = firestore.collection(collectionPath);

    // Handle param
    var queryInfo = queryData.queryInfo;
    if (queryInfo != null) {
      // Select
      if (queryInfo.selectKeyPaths != null) {
        query = query.select(queryInfo.selectKeyPaths);
      }

      // limit
      if (queryInfo.limit != null) {
        query = query.limit(queryInfo.limit);
      }

      // order
      for (var orderBy in queryInfo.orderBys) {
        query = query.orderBy(orderBy.fieldPath,
            descending: orderBy.ascending == false);
      }

      // where
      for (var where in queryInfo.wheres) {
        query = query.where(where.fieldPath,
            isEqualTo: where.isEqualTo,
            isLessThan: where.isLessThan,
            isLessThanOrEqualTo: where.isLessThanOrEqualTo,
            isGreaterThan: where.isGreaterThan,
            isGreaterThanOrEqualTo: where.isGreaterThanOrEqualTo,
            arrayContains: where.arrayContains,
            isNull: where.isNull);
      }

      if (queryInfo.startLimit != null) {
        // get it
        DocumentSnapshot snapshot;
        if (queryInfo.startLimit.documentId != null) {
          snapshot = await firestore
              .collection(collectionPath)
              .doc(queryInfo.startLimit.documentId)
              .get();
        }
        if (queryInfo.startLimit.inclusive == true) {
          query = query.startAt(
              snapshot: snapshot, values: queryInfo.startLimit.values);
        } else {
          query = query.startAfter(
              snapshot: snapshot, values: queryInfo.startLimit.values);
        }
      }
      if (queryInfo.endLimit != null) {
        // get it
        DocumentSnapshot snapshot;
        if (queryInfo.endLimit.documentId != null) {
          snapshot = await firestore
              .collection(collectionPath)
              .doc(queryInfo.endLimit.documentId)
              .get();
        }
        if (queryInfo.endLimit.inclusive == true) {
          query = query.endAt(
              snapshot: snapshot, values: queryInfo.endLimit.values);
        } else {
          query = query.endBefore(
              snapshot: snapshot, values: queryInfo.endLimit.values);
        }
      }
    }
    return query;
  }

  // Batch
  Future handleFirestoreBatch(rpc.Parameters parameters) async {
    var batchData = FirestoreBatchData()
      ..firestoreFromMap(firestore, rpcParams(parameters));

    await transactionLock.synchronized(() async {
      await _handleFirestoreBatch(batchData);
    });
  }

  Future _handleFirestoreBatch(FirestoreBatchData batchData) async {
    var batch = firestore.batch();
    for (var item in batchData.operations) {
      if (item is BatchOperationDeleteData) {
        batch.delete(firestore.doc(item.path));
      } else if (item is BatchOperationSetData) {
        batch.set(
            firestore.doc(item.path),
            documentDataFromJsonMap(firestore, item.data)?.asMap(),
            item.merge != null ? SetOptions(merge: item.merge) : null);
      } else if (item is BatchOperationUpdateData) {
        batch.update(firestore.doc(item.path),
            documentDataFromJsonMap(firestore, item.data)?.asMap());
      } else {
        throw 'not supported ${item}';
      }
    }
    await batch.commit();
  }

  Completer transactionCompleter;

  // Transaction
  Future handleFirestoreTransaction(Map<String, dynamic> params) async {
    var responseData = FirestoreTransactionResponseData()
      ..transactionId = ++lastTransactionId;

    // start locking but don't wait
    transactionLock.synchronized(() async {
      transactionCompleter = Completer();
      await transactionCompleter.future;
      transactionCompleter = null;
    });
    return responseData.toMap();
  }

  Future handleFirestoreTransactionCommit(Map<String, dynamic> params) async {
    var batchData = FirestoreBatchData()..firestoreFromMap(firestore, params);

    if (batchData.transactionId == lastTransactionId) {
      try {
        await _handleFirestoreBatch(batchData);
      } finally {
        // terminate transaction
        transactionCompleter.complete();
      }
    } else {
      await transactionLock.synchronized(() async {
        await _handleFirestoreBatch(batchData);
      });
    }
  }

  Future handleFirestoreTransactionCancel(Map<String, dynamic> params) async {
    var requestData = FirestoreTransactionCancelRequestData()..fromMap(params);

    if (requestData.transactionId == lastTransactionId) {
      // terminate transaction
      transactionCompleter.complete();
    }
  }

  @override
  Future close() async {
    // TODO: implement close
  }
}

class FirestoreSimServer implements FirebaseSimPlugin {
  final FirestoreServiceProvider firestoreServiceProvider;
  final FirebaseSimServer firebaseSimServer;
  final Firebase firebase;
  final Map<Firestore, Lock> _locks = <Firestore, Lock>{};

  Lock transactionLock(Firestore firestore) => _locks[firestore];
  // App app;
  FirestoreService firestoreService;
  Firestore firestore;

  FirestoreSimServer(
      this.firestoreServiceProvider, this.firebaseSimServer, this.firebase) {
    firestoreService = firestoreServiceProvider.firestoreService(firebase);
    firebaseSimServer.addPlugin(this);
  }

  @override
  FirebaseSimPluginClient register(App app, rpc.Server rpcServer) {
    var firestore = firestoreService.firestore(app);
    // One transaction lock per server
    _locks[firestore] ??= Lock();
    var client = FirestireSimPluginClient(this, firestore, rpcServer);
    return client;
  }
}

/*

class FirebaseSimServerClient extends Object with FirebaseSimMixin {
  final FirestoreServiceSim firestoreServiceSim;
  final FirebaseSimServer server;
  final WebSocketChannel<String> webSocketChannel;
  App app;
  int appId;
  Completer transactionCompleter;

  Firestore get firestore => firestoreServiceSim.firestore(app);

  final Map<int, SimSubscription> subscriptions = {};

  FirebaseSimServerClient(this.server, this.webSocketChannel) {
    init();
  }

  @override
  Future close() async {
    // Close any pending transaction
    if (transactionCompleter != null) {
      if (!transactionCompleter.isCompleted) {
        transactionCompleter.completeError('database closed');
      }
    }
    await closeMixin();
    List<SimSubscription> subscriptions = this.subscriptions.values.toList();
    for (var subscription in subscriptions) {
      await cancelSubscription(subscription);
    }
  }
  */

/*

  void handleRequest(Map<String, dynamic> params) async {
    try {
      if (request.method == methodPing) {
        var response = Response(request.id, null);
        sendMessage(response);

      }
      } else if (request.method == methodFirestoreAdd) {
        await handleFirestoreAddRequest(request);
      } else if (request.method == methodFirestoreGet) {
        await handleFirestoreGet(request);
      } else if (request.method == methodFirestoreGetStream) {
        await handleFirestoreGetStream(request);
      } else if (request.method == methodFirestoreQuery) {
        await handleFirestoreQuery(request);
      } else if (request.method == methodFirestoreQueryStream) {
        await handleFirestoreQueryStream(request);
      } else if (request.method == methodFirestoreQueryStreamCancel) {
        await handleFirestoreQueryStreamCancel(request);
      } else if (request.method == methodFirestoreBatch) {
        await handleFirestoreBatch(request);
      } else if (request.method == methodFirestoreTransaction) {
        await handleFirestoreTransaction(request);
      } else if (request.method == methodFirestoreTransactionCommit) {
        await handleFirestoreTransactionCommit(request);
      } else if (request.method == methodFirestoreTransactionCancel) {
        await handleFirestoreTransactionCancel(request);
      } else if (request.method == methodFirestoreDelete) {
        await handleFirestoreDeleteRequest(request);
      } else {
        var errorResponse = ErrorResponse(
            request.id,
            Error(errorCodeMethodNotFound,
                "unsupported method ${request.method}"));
        sendMessage(errorResponse);
      }
    } catch (e, st) {
      print(e);
      print(st);
      var errorResponse = ErrorResponse(
          request.id,
          Error(errorCodeExceptionThrown,
              "${e} thrown from method ${request.method}\n$st"));
      sendMessage(errorResponse);
    }
  }

  Future handleFirestoreDeleteRequest(Map<String, dynamic> params) async {
    var response = Response(request.id, null);

    var firestoreDeleteData = FirestorePathData()
      ..fromMap(params);

    await server.transactionLock.synchronized(() async {
      await firestore.doc(firestoreDeleteData.path).delete();
    });

    sendMessage(response);
  }

  Future handleFirestoreAddRequest(Map<String, dynamic> params) async {
    var firestoreSetData = FirestoreSetData()..fromMap(params);
    var documentData =
        documentDataFromJsonMap(firestore, firestoreSetData.data);

    await server.transactionLock.synchronized(() async {
      var docRef = await app
          .firestore()
          .collection(firestoreSetData.path)
          .add(documentData.asMap());

      var response = Response(
          request.id, (FirestorePathData()..path = docRef.path).toMap());
      sendMessage(response);
    });
  }




    /*

Map<String, dynamic> snapshotToJsonMap(DocumentSnapshot snapshot) {
  if (snapshot?.exists == true) {
    var map = documentDataToJsonMap(documentDataFromSnapshot(snapshot));
    if (snapshot.createTime != null) {
      map[createTimeKey] = snapshot.createTime;
      map[updateTimeKey] = snapshot.updateTime;
    }
    return map;
  } else {
    return null;
  }
}
     */


    sendMessage(response);
  }


  Future cancelSubscription(SimSubscription simSubscription) async {
    // remove right away
    if (subscriptions.containsKey(simSubscription.id)) {
      subscriptions.remove(simSubscription.id);
      await simSubscription.firestoreSubscription.cancel();
    }
  }

  // Cancel subscription
  Future handleFirestoreQueryStreamCancel(Map<String, dynamic> params) async {
    var cancelData = FirestoreQueryStreamCancelData()
      ..fromMap(params);
    int streamId = cancelData.streamId;

    var simSubscription = subscriptions[streamId];
    if (simSubscription != null) {
      await cancelSubscription(simSubscription);
      var response = Response(request.id, null);
      sendMessage(response);
    } else {
      var errorResponse = ErrorResponse(
          request.id,
          Error(errorCodeSubscriptionNotFound,
              "subscription $streamId not found method ${request.method}"));
      sendMessage(errorResponse);
    }
  }



*/
