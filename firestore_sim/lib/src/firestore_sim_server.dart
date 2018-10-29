import 'dart:async';
import 'dart:core' hide Error;

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:json_rpc_2/src/server.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase/firebase.dart';
//import 'package:tekartik_firebase_sim/rpc_message.dart';
import 'package:tekartik_firebase_sim/src/firebase_sim_common.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/firestore_common.dart';
import 'package:tekartik_firebase_firestore_sim/firestore_sim_message.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:tekartik_firebase_sim/src/firebase_sim_server.dart';

class FirestireSimPluginClient implements FirebaseSimPluginClient {
  final Firestore firestore;
  int lastTransactionId = 0;
  int lastSubscriptionId = 0;
  final transactionLock = Lock();

  DocumentReference requestDocumentReference(Map<String, dynamic> params) {
    var firestorePathData = FirestorePathData()..fromMap(params);
    var ref = firestore.doc(firestorePathData.path);
    return ref;
  }

  FirestireSimPluginClient(this.firestore, Server rpcServer) {
    rpcServer.registerMethod(methodFirestoreAdd,
        (json_rpc.Parameters parameters) async {
      return await handleFirestoreAddRequest(rpcParams(parameters));
    });
    rpcServer.registerMethod(methodFirestoreSet,
        (json_rpc.Parameters parameters) async {
      return await handleFirestoreSetRequest(rpcParams(parameters));
    });
    rpcServer.registerMethod(methodFirestoreDelete,
        (json_rpc.Parameters parameters) async {
      return await handleFirestoreDeleteRequest(rpcParams(parameters));
    });

    rpcServer.registerMethod(methodFirestoreGet,
        (json_rpc.Parameters parameters) async {
      return await handleFirestoreGetRequest(rpcParams(parameters));
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

  Future handleFirestoreDeleteRequest(Map<String, dynamic> params) async {
    var firestoreDeleteData = FirestorePathData()..fromMap(params);

    await transactionLock.synchronized(() async {
      await firestore.doc(firestoreDeleteData.path).delete();
    });
  }

  Future handleFirestoreGetStream(Map<String, dynamic> params) async {
    /*
    var pathData = FirestorePathData()..fromMap(params);
    var ref = firestore.doc(pathData.path);
    int streamId = ++lastSubscriptionId;

    await transactionLock.synchronized(() async {
      // ignore: cancel_subscriptions
      StreamSubscription<DocumentSnapshot> streamSubscription =
      ref.onSnapshot().listen((DocumentSnapshot snapshot) {
        // delayed to make sure the response was send already
        Future.value().then((_) async {
          var data = DocumentGetSnapshotData.fromSnapshot(snapshot);
          data.streamId = streamId;

          var notification =
          Notification(methodFirestoreGetStream, data.toMap());
          rpc
          sendMessage(notification);
        });
      });

      var data = FirestoreQueryStreamResponse();
      subscriptions[streamId] = SimSubscription(streamId, streamSubscription);
      data.streamId = streamId;

      // Get
      var response = Response(request.id, data.toMap());

      sendMessage(response);
    });
    */
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

  // App app;
  FirestoreService firestoreService;
  Firestore firestore;

  FirestoreSimServer(
      this.firestoreServiceProvider, this.firebaseSimServer, this.firebase) {
    firestoreService = firestoreServiceProvider.firestoreService(firebase);
    firebaseSimServer.addPlugin(this);
  }

  @override
  FirebaseSimPluginClient register(App app, Server rpcServer) {
    var firestore = firestoreService.firestore(app);
    var client = FirestireSimPluginClient(firestore, rpcServer);
    return client;
  }
}

class SimSubscription<T> {
  final int id;
  final StreamSubscription<T> firestoreSubscription;

  SimSubscription(this.id, this.firestoreSubscription);
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
      } else if (request.method == methodAdminInitializeApp) {
        await handleAdminInitializeApp(request);
      } else if (request.method == methodFirestoreSet) {
        await handleFirestoreSetRequest(request);
      } else if (request.method == methodFirestoreUpdate) {
        await handleFirestoreUpdateRequest(request);
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

  Future handleFirestoreUpdateRequest(Map<String, dynamic> params) async {
    var firestoreSetData = FirestoreSetData()..fromMap(params);
    var documentData =
        documentDataFromJsonMap(firestore, firestoreSetData.data);

    await server.transactionLock.synchronized(() async {
      await app
          .firestore()
          .doc(firestoreSetData.path)
          .update(documentData.asMap());
    });

    var response = Response(request.id, null);
    sendMessage(response);
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

  Future handleFirestoreQueryStream(Map<String, dynamic> params) async {
    var queryData = FirestoreQueryData()
      ..firestoreFromMap(firestore, params);

    await server.transactionLock.synchronized(() async {
      Query query = await getQuery(queryData);
      int streamId = ++server.lastSubscriptionId;

      // ignore: cancel_subscriptions
      StreamSubscription<QuerySnapshot> streamSubscription =
          query.onSnapshot().listen((QuerySnapshot querySnapshot) {
        // delayed to make sure the response was send already
        Future.value().then((_) async {
          var data = FirestoreQuerySnapshotData();
          data.streamId = streamId;
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
              documentChangeData.data = documentDataToJsonMap(
                  documentDataFromSnapshot(change.document));
            }
            data.changes.add(documentChangeData);
          }
          var notification =
              Notification(methodFirestoreQueryStream, data.toMap());
          sendMessage(notification);
        });
      });

      var data = FirestoreQueryStreamResponse();
      subscriptions[streamId] = SimSubscription(streamId, streamSubscription);
      data.streamId = streamId;

      // Get
      var response = Response(request.id, data.toMap());

      sendMessage(response);
    });
  }

  // Batch
  Future handleFirestoreBatch(Map<String, dynamic> params) async {
    var batchData = FirestoreBatchData()
      ..firestoreFromMap(firestore, params);

    await server.transactionLock.synchronized(() async {
      await _handleFirestoreBatch(batchData, request);
    });
  }

  Future _handleFirestoreBatch(
      FirestoreBatchData batchData, Request request) async {
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

    var response = Response(request.id, {});

    sendMessage(response);
  }

  // Transaction
  Future handleFirestoreTransaction(Map<String, dynamic> params) async {
    var responseData = FirestoreTransactionResponseData()
      ..transactionId = ++server.lastTransactionId;

    // start locking but don't wait
    server.transactionLock.synchronized(() async {
      transactionCompleter = Completer();
      await transactionCompleter.future;
      transactionCompleter = null;
    });
    var response = Response(request.id, responseData.toMap());

    sendMessage(response);
  }

  Future handleFirestoreTransactionCommit(Map<String, dynamic> params) async {
    var batchData = FirestoreBatchData()
      ..firestoreFromMap(firestore, params);

    if (batchData.transactionId == server.lastTransactionId) {
      try {
        await _handleFirestoreBatch(batchData, request);
      } finally {
        // terminate transaction
        transactionCompleter.complete();
      }
    } else {
      await server.transactionLock.synchronized(() async {
        await _handleFirestoreBatch(batchData, request);
      });
    }
  }

  Future handleFirestoreTransactionCancel(Map<String, dynamic> params) async {
    var requestData = FirestoreTransactionCancelRequestData()
      ..fromMap(params);

    if (requestData.transactionId == server.lastTransactionId) {
      // terminate transaction
      transactionCompleter.complete();
    }
    var response = Response(request.id, {});

    sendMessage(response);
  }

  Future handleFirestoreQuery(Map<String, dynamic> params) async {
    var queryData = FirestoreQueryData()
      ..firestoreFromMap(firestore, params);
    Query query = await getQuery(queryData);

    await server.transactionLock.synchronized(() async {
      var querySnapshot = await query.get();

      var data = FirestoreQuerySnapshotData();
      data.list = <DocumentSnapshotData>[];
      for (DocumentSnapshot doc in querySnapshot.docs) {
        data.list.add(DocumentSnapshotData.fromSnapshot(doc));
      }

      // Get
      var response = Response(request.id, data.toMap());

      sendMessage(response);
    });
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
          snapshot = await app
              .firestore()
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
          snapshot = await app
              .firestore()
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
*/
