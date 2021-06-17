import 'dart:async';
import 'dart:core' hide Error;

import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:pedantic/pedantic.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/stream/stream_poller.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/firestore_common.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore_sim/firestore_sim_message.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server.dart';
import 'package:tekartik_firebase_sim/src/firebase_sim_common.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_sim/src/firebase_sim_server.dart'; // ignore: implementation_imports

class SimSubscription<T> {
  late StreamPoller<T> _poller;

  Future<StreamPollerEvent<T?>> getNext() => _poller.getNext();

  SimSubscription(Stream<T> stream) {
    _poller = StreamPoller<T>(stream);
  }

  // Make sure to cancel the pending completer
  Future cancel() => _poller.cancel();
}

class FirestireSimPluginClient implements FirebaseSimPluginClient {
  final FirestoreSimServer firestoreSimServer;
  final Firestore firestore;
  int lastTransactionId = 0;
  int lastSubscriptionId = 0;
  Lock? get transactionLock => firestoreSimServer.transactionLock(firestore);
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
      return await handleFirestoreAddRequest(rpcParams(parameters)!);
    });
    rpcServer.registerMethod(methodFirestoreSet,
        (rpc.Parameters parameters) async {
      return await handleFirestoreSetRequest(rpcParams(parameters)!);
    });
    rpcServer.registerMethod(methodFirestoreDelete,
        (rpc.Parameters parameters) async {
      return await handleFirestoreDeleteRequest(rpcParams(parameters)!);
    });

    rpcServer.registerMethod(methodFirestoreGet,
        (rpc.Parameters parameters) async {
      return await handleFirestoreGetRequest(rpcParams(parameters)!);
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
      return await handleFirestoreTransactionCancel(rpcParams(parameters)!);
    });
    rpcServer.registerMethod(methodFirestoreTransactionCommit,
        (rpc.Parameters parameters) async {
      return await handleFirestoreTransactionCommit(rpcParams(parameters)!);
    });
  }

  Future handleFirestoreAddRequest(Map<String, dynamic> params) async {
    var firestoreSetData = FirestoreSetData()..fromMap(params);
    var documentData =
        documentDataFromJsonMap(firestore, firestoreSetData.data);

    return await transactionLock!.synchronized(() async {
      var docRef = await firestore
          .collection(firestoreSetData.path)
          .add(documentData!.asMap());

      return (FirestorePathData()..path = docRef.path).toMap();
    });
  }

  Future handleFirestoreGetRequest(Map<String, dynamic> params) async {
    var firestoreGetRequesthData = FirestoreGetRequestData()..fromMap(params);
    var ref = requestDocumentReference(params);
    var transactionId = firestoreGetRequesthData.transactionId;

    // Current transaction, read as is
    late DocumentSnapshot documentSnapshot;
    if (transactionId == lastTransactionId) {
      documentSnapshot = await ref.get();
    } else {
      // otherwise lock
      await transactionLock!.synchronized(() async {
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
    SetOptions? options;
    if (firestoreSetData.merge != null) {
      options = SetOptions(merge: firestoreSetData.merge);
    }

    await transactionLock!.synchronized(() async {
      await firestore
          .doc(firestoreSetData.path)
          .set(documentData!.asMap(), options);
    });
  }

  Future handleFirestoreUpdateRequest(rpc.Parameters parameters) async {
    var firestoreSetData = FirestoreSetData()..fromMap(rpcParams(parameters)!);
    var documentData =
        documentDataFromJsonMap(firestore, firestoreSetData.data);

    await transactionLock!.synchronized(() async {
      await firestore.doc(firestoreSetData.path).update(documentData!.asMap());
    });
  }

  Future handleFirestoreDeleteRequest(Map<String, dynamic> params) async {
    var firestoreDeleteData = FirestorePathData()..fromMap(params);

    await transactionLock!.synchronized(() async {
      await firestore.doc(firestoreDeleteData.path).delete();
    });
  }

  Future handleFirestoreGetListen(rpc.Parameters parameters) async {
    var subscriptionId = newSubscriptionId;
    final path = parameters[paramPath].value as String?;
    return await transactionLock!.synchronized(() async {
      var ref = firestore.doc(path!);

      subscriptions[subscriptionId] =
          SimSubscription<DocumentSnapshot>(ref.onSnapshot());
      return {paramSubscriptionId: subscriptionId};
    });
  }

  Future handleFirestoreGetCancel(rpc.Parameters parameters) async {
    var subscriptionId = parameters[paramSubscriptionId].value as int?;
    var subscription = subscriptions[subscriptionId!]!;
    subscriptions.remove(subscriptionId);
    await subscription.cancel();
  }

  Future handleFirestoreGetStream(rpc.Parameters parameters) async {
    // New stream?
    var subscriptionId = parameters[paramSubscriptionId].value as int?;
    final subscription =
        subscriptions[subscriptionId!] as SimSubscription<DocumentSnapshot>?;
    var event = (await subscription?.getNext());
    var map = {};
    if (event == null || event.done) {
      map[paramDone] = true;
    } else {
      map[paramSnapshot] =
          DocumentSnapshotData.fromSnapshot(event.data!).toMap();
    }
    return map;
  }

  Future handleFirestoreQuery(rpc.Parameters parameters) async {
    var queryData = FirestoreQueryData()
      ..firestoreFromMap(firestore, rpcParams(parameters)!);
    final query = await getQuery(queryData);

    return await transactionLock!.synchronized(() async {
      var querySnapshot = await query.get();

      var data = FirestoreQuerySnapshotData();
      data.list = <DocumentSnapshotData>[];
      for (final doc in querySnapshot.docs) {
        data.list.add(DocumentSnapshotData.fromSnapshot(doc));
      }
      return data.toMap();
    });
  }

  Future handleFirestoreQueryListen(rpc.Parameters parameters) async {
    var subscriptionId = newSubscriptionId;
    var queryData = FirestoreQueryData()
      ..firestoreFromMap(firestore, rpcParams(parameters)!);
    return await transactionLock!.synchronized(() async {
      final query = await getQuery(queryData);

      subscriptions[subscriptionId] =
          SimSubscription<QuerySnapshot>(query.onSnapshot());

      return {paramSubscriptionId: subscriptionId};
    });
  }

  Future handleFirestoreQueryCancel(rpc.Parameters parameters) async {
    var subscriptionId = parameters[paramSubscriptionId].value as int?;
    var subscription = subscriptions[subscriptionId!]!;
    subscriptions.remove(subscriptionId);
    await subscription.cancel();
  }

  Future handleFirestoreQueryStream(rpc.Parameters parameters) async {
    // New stream?
    var subscriptionId = parameters[paramSubscriptionId].value as int?;
    final subscription =
        subscriptions[subscriptionId!] as SimSubscription<QuerySnapshot>?;
    try {
      var event = (await subscription?.getNext());
      var map = {};
      if (event == null || event.done) {
        map[paramDone] = true; // event.done;
        return map;
      }
      final querySnapshot = event.data!;
      var data = FirestoreQuerySnapshotData();
      data.list = <DocumentSnapshotData>[];
      for (final doc in querySnapshot.docs) {
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

        bool _find() {
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
        data.changes!.add(documentChangeData);
      }
      map[paramSnapshot] = data.toMap();
      return map;
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
        query = query.select(queryInfo.selectKeyPaths!);
      }

      // limit
      if (queryInfo.limit != null) {
        query = query.limit(queryInfo.limit!);
      }

      // order
      for (var orderBy in queryInfo.orderBys) {
        query = query.orderBy(orderBy.fieldPath!,
            descending: orderBy.ascending == false);
      }

      // where
      for (var where in queryInfo.wheres) {
        query = query.where(where.fieldPath!,
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
        DocumentSnapshot? snapshot;
        if (queryInfo.startLimit!.documentId != null) {
          snapshot = await firestore
              .collection(collectionPath)
              .doc(queryInfo.startLimit!.documentId!)
              .get();
        }
        if (queryInfo.startLimit!.inclusive == true) {
          query = query.startAt(
              snapshot: snapshot, values: queryInfo.startLimit!.values);
        } else {
          query = query.startAfter(
              snapshot: snapshot, values: queryInfo.startLimit!.values);
        }
      }
      if (queryInfo.endLimit != null) {
        // get it
        DocumentSnapshot? snapshot;
        if (queryInfo.endLimit!.documentId != null) {
          snapshot = await firestore
              .collection(collectionPath)
              .doc(queryInfo.endLimit!.documentId!)
              .get();
        }
        if (queryInfo.endLimit!.inclusive == true) {
          query = query.endAt(
              snapshot: snapshot, values: queryInfo.endLimit!.values);
        } else {
          query = query.endBefore(
              snapshot: snapshot, values: queryInfo.endLimit!.values);
        }
      }
    }
    return query;
  }

  // Batch
  Future handleFirestoreBatch(rpc.Parameters parameters) async {
    var batchData = FirestoreBatchData()
      ..firestoreFromMap(firestore, rpcParams(parameters)!);

    await transactionLock!.synchronized(() async {
      await _handleFirestoreBatch(batchData);
    });
  }

  Future _handleFirestoreBatch(FirestoreBatchData batchData) async {
    var batch = firestore.batch();
    for (var item in batchData.operations) {
      if (item is BatchOperationDeleteData) {
        batch.delete(firestore.doc(item.path!));
      } else if (item is BatchOperationSetData) {
        batch.set(
            firestore.doc(item.path!),
            documentDataFromJsonMap(firestore, item.data)!.asMap(),
            item.merge != null ? SetOptions(merge: item.merge) : null);
      } else if (item is BatchOperationUpdateData) {
        batch.update(firestore.doc(item.path!),
            documentDataFromJsonMap(firestore, item.data)!.asMap());
      } else {
        throw 'not supported $item';
      }
    }
    await batch.commit();
  }

  Completer? transactionCompleter;

  // Transaction
  Future handleFirestoreTransaction(Map<String, dynamic>? params) async {
    var responseData = FirestoreTransactionResponseData()
      ..transactionId = ++lastTransactionId;

    // start locking but don't wait
    unawaited(transactionLock!.synchronized(() async {
      transactionCompleter = Completer();
      await transactionCompleter!.future;
      transactionCompleter = null;
    }));
    return responseData.toMap();
  }

  Future handleFirestoreTransactionCommit(Map<String, dynamic> params) async {
    var batchData = FirestoreBatchData()..firestoreFromMap(firestore, params);

    if (batchData.transactionId == lastTransactionId) {
      try {
        await _handleFirestoreBatch(batchData);
      } finally {
        // terminate transaction
        transactionCompleter!.complete();
      }
    } else {
      await transactionLock!.synchronized(() async {
        await _handleFirestoreBatch(batchData);
      });
    }
  }

  Future handleFirestoreTransactionCancel(Map<String, dynamic> params) async {
    var requestData = FirestoreTransactionCancelRequestData()..fromMap(params);

    if (requestData.transactionId == lastTransactionId) {
      // terminate transaction
      transactionCompleter!.complete();
    }
  }

  @override
  Future close() async {
    // TODO: implement close
  }
}

class FirestoreSimServer implements FirebaseSimPlugin {
  final FirestoreService firestoreService;
  final FirebaseSimServer firebaseSimServer;
  final Firebase firebase;
  final Map<Firestore, Lock> _locks = <Firestore, Lock>{};

  Lock? transactionLock(Firestore firestore) => _locks[firestore];
  // App app;
  Firestore? firestore;

  FirestoreSimServer(
      this.firestoreService, this.firebaseSimServer, this.firebase) {
    firebaseSimServer.addPlugin(this);
  }

  @override
  FirebaseSimPluginClient register(App? app, rpc.Server rpcServer) {
    var firestore = firestoreService.firestore(app!);
    // One transaction lock per server
    _locks[firestore] ??= Lock();
    var client = FirestireSimPluginClient(this, firestore, rpcServer);
    return client;
  }
}
