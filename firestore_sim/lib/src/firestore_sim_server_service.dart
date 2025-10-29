import 'dart:core' hide Error;

import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/stream/stream_poller.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/query_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore/src/firestore_common.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_sim/firebase_sim_mixin.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server_mixin.dart'
    hide AdminInitializeAppData;
// ignore: implementation_imports

import 'firestore_sim_message.dart';
import 'firestore_sim_plugin.dart'; // ignore: implementation_imports
// ignore: implementation_imports

class FirestoreSimServerService extends FirebaseSimServerServiceBase {
  late FirestoreSimPlugin firestoreSimPlugin;

  //final _expando = Expando<_FirestoreSimPluginServer>();
  final _appServers =
      <FirebaseSimServerProjectApp, _FirestoreSimPluginServer>{};
  static final serviceName = 'firebase_firestore';

  FirestoreSimServerService() : super(serviceName) {
    firebaseSimFirestoreInitCvBuilders();
  }

  @override
  FutureOr<Object?> onAppCall(
    FirebaseSimServerProjectApp projectApp,
    RpcServerChannel channel,
    RpcMethodCall methodCall,
  ) async {
    var firestoreSimPluginServer = _appServers[projectApp] ??= () {
      var app = projectApp.app!;
      var firestore = firestoreSimPlugin.firestoreService.firestore(app);
      //.debugQuickLoggerWrapper();
      // One transaction lock per server
      //firestoreSimPlugin._locks[firestore] ??= Lock();
      return _FirestoreSimPluginServer(firestoreSimPlugin, firestore);
    }();

    var parameters = methodCall.arguments;
    switch (methodCall.method) {
      case methodFirestoreSet:
        var map = resultAsMap(parameters);
        return await firestoreSimPluginServer.handleFirestoreSetRequest(map);

      case methodFirestoreDelete:
        return await firestoreSimPluginServer.handleFirestoreDeleteRequest(
          resultAsMap(parameters),
        );
      case methodFirestoreAdd:
        var map = resultAsMap(parameters);
        return await firestoreSimPluginServer.handleFirestoreAddRequest(map);

      case methodFirestoreGet:
        var map = resultAsMap(parameters);

        return await firestoreSimPluginServer.handleFirestoreGetRequest(map);

      case methodFirestoreGetListen:
        var map = resultAsMap(parameters);
        return await firestoreSimPluginServer.handleFirestoreGetListen(map);

      case methodFirestoreGetStream:
        var map = resultAsMap(parameters);
        return await firestoreSimPluginServer.handleFirestoreGetStream(map);

      case methodFirestoreGetCancel:
        var map = resultAsMap(parameters);
        return await firestoreSimPluginServer.handleFirestoreGetCancel(map);

      case methodFirestoreQuery:
        var map = resultAsMap(parameters);
        return await firestoreSimPluginServer.handleFirestoreQuery(map);

      case methodFirestoreQueryListen:
        var map = resultAsMap(parameters);
        return await firestoreSimPluginServer.handleFirestoreQueryListen(map);

      case methodFirestoreQueryStream:
        var map = resultAsMap(parameters);
        return await firestoreSimPluginServer.handleFirestoreQueryStream(map);

      case methodFirestoreQueryCancel:
        var map = resultAsMap(parameters);
        return await firestoreSimPluginServer.handleFirestoreQueryCancel(map);

      case methodFirestoreUpdate:
        var map = resultAsMap(parameters);
        return await firestoreSimPluginServer.handleFirestoreUpdateRequest(map);

      case methodFirestoreBatch:
        var map = resultAsMap(parameters);
        return await firestoreSimPluginServer.handleFirestoreBatch(map);

      case methodFirestoreTransaction:
        var map = resultAsMap(parameters);
        return await firestoreSimPluginServer.handleFirestoreTransaction(map);

      case methodFirestoreTransactionCancel:
        var map = resultAsMap(parameters);
        return await firestoreSimPluginServer.handleFirestoreTransactionCancel(
          map,
        );

      case methodFirestoreTransactionCommit:
        var map = resultAsMap(parameters);
        return await firestoreSimPluginServer.handleFirestoreTransactionCommit(
          map,
        );
    }
    return super.onAppCall(projectApp, channel, methodCall);
  }
}

class SimSubscription<T> {
  late StreamPoller<T> _poller;

  Future<StreamPollerEvent<T?>> getNext() => _poller.getNext();

  SimSubscription(Stream<T> stream) {
    _poller = StreamPoller<T>(stream);
  }

  // Make sure to cancel the pending completer
  Future cancel() => _poller.cancel();
}

/// One per client/app
class _FirestoreSimPluginServer {
  final FirestoreSimPlugin firestoreSimServer;
  final Firestore firestore;
  int lastTransactionId = 0;
  int lastSubscriptionId = 0;

  //Lock? get transactionLock => firestoreSimServer.transactionLock(firestore);
  final transactionLock = Lock();
  //final rpc.Server rpcServer;
  final Map<int, SimSubscription> subscriptions = <int, SimSubscription>{};

  int get newSubscriptionId => ++lastSubscriptionId;

  DocumentReference requestDocumentReference(Map<String, Object?> params) {
    var firestorePathData = FirestorePathData()..fromMap(params);
    var ref = firestore.doc(firestorePathData.path);
    return ref;
  }

  _FirestoreSimPluginServer(this.firestoreSimServer, this.firestore) {
    // One transaction lock per server
    /*

    case methodFirestoreGet,
        (Map<String, Object?> params) async {
      return await handleFirestoreGetRequest(rpcParams(parameters)!);
    });
    case methodFirestoreGetListen,
        (Map<String, Object?> params) async {
      return await handleFirestoreGetListen(parameters);
    });
    case methodFirestoreGetStream,
        (Map<String, Object?> params) async {
      return await handleFirestoreGetStream(parameters);
    });
    case methodFirestoreGetCancel,
        (Map<String, Object?> params) async {
      return await handleFirestoreGetCancel(parameters);
    });

    case methodFirestoreQuery,
        (Map<String, Object?> params) async {
      return await handleFirestoreQuery(parameters);
    });
    case methodFirestoreQueryListen,
        (Map<String, Object?> params) async {
      return await handleFirestoreQueryListen(parameters);
    });
    case methodFirestoreQueryStream,
        (Map<String, Object?> params) async {
      return await handleFirestoreQueryStream(parameters);
    });
    case methodFirestoreQueryCancel,
        (Map<String, Object?> params) async {
      return await handleFirestoreQueryCancel(parameters);
    });

    case methodFirestoreUpdate,
        (Map<String, Object?> params) async {
      return await handleFirestoreUpdateRequest(parameters);
    });

    case methodFirestoreBatch,
        (Map<String, Object?> params) async {
      return await handleFirestoreBatch(parameters);
    });

    case methodFirestoreTransaction,
        (Map<String, Object?> params) async {
      return await handleFirestoreTransaction(rpcParams(parameters));
    });

    case methodFirestoreTransactionCancel,
        (Map<String, Object?> params) async {
      return await handleFirestoreTransactionCancel(rpcParams(parameters)!);
    });
    case methodFirestoreTransactionCommit,
        (Map<String, Object?> params) async {
      return await handleFirestoreTransactionCommit(rpcParams(parameters)!);
    });*/
  }

  Future handleFirestoreAddRequest(Map<String, Object?> params) async {
    var firestoreSetData = FirestoreSetData()..fromMap(params);
    var documentData = documentDataFromJsonMap(
      firestore,
      firestoreSetData.data,
    );

    return await transactionLock.synchronized(() async {
      var docRef = await firestore
          .collection(firestoreSetData.path)
          .add(documentData!.asMap());

      return (FirestorePathData()..path = docRef.path).toMap();
    });
  }

  Future handleFirestoreGetRequest(Map<String, Object?> params) async {
    var firestoreGetRequesthData = FirestoreGetRequestData()..fromMap(params);
    var ref = requestDocumentReference(params);
    var transactionId = firestoreGetRequesthData.transactionId;

    // Current transaction, read as is
    late DocumentSnapshot documentSnapshot;
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

  Future handleFirestoreSetRequest(Map<String, Object?> params) async {
    var firestoreSetData = FirestoreSetData()..fromMap(params);
    var documentData = documentDataFromJsonMap(
      firestore,
      firestoreSetData.data,
    );
    SetOptions? options;
    if (firestoreSetData.merge != null) {
      options = SetOptions(merge: firestoreSetData.merge);
    }

    await transactionLock.synchronized(() async {
      await firestore
          .doc(firestoreSetData.path)
          .set(documentData!.asMap(), options);
    });
  }

  Future handleFirestoreUpdateRequest(Map<String, Object?> params) async {
    var firestoreSetData = FirestoreSetData()..fromMap(params);
    var documentData = documentDataFromJsonMap(
      firestore,
      firestoreSetData.data,
    );

    await transactionLock.synchronized(() async {
      await firestore.doc(firestoreSetData.path).update(documentData!.asMap());
    });
  }

  Future handleFirestoreDeleteRequest(Map<String, Object?> params) async {
    var firestoreDeleteData = FirestorePathData()..fromMap(params);

    await transactionLock.synchronized(() async {
      await firestore.doc(firestoreDeleteData.path).delete();
    });
  }

  Future handleFirestoreGetListen(Map<String, Object?> params) async {
    var subscriptionId = newSubscriptionId;
    final path = params[paramPath] as String?;
    return await transactionLock.synchronized(() async {
      var ref = firestore.doc(path!);

      subscriptions[subscriptionId] = SimSubscription<DocumentSnapshot>(
        ref.onSnapshot(),
      );
      return {paramSubscriptionId: subscriptionId};
    });
  }

  Future handleFirestoreGetCancel(Map<String, Object?> params) async {
    var subscriptionId = params[paramSubscriptionId] as int?;
    var subscription = subscriptions[subscriptionId!]!;
    subscriptions.remove(subscriptionId);
    await subscription.cancel();
  }

  Future handleFirestoreGetStream(Map<String, Object?> params) async {
    // New stream?
    var subscriptionId = params[paramSubscriptionId] as int?;
    final subscription =
        subscriptions[subscriptionId!] as SimSubscription<DocumentSnapshot>?;
    var event = (await subscription?.getNext());
    var map = <String, Object?>{};
    if (event == null || event.done) {
      map[paramDone] = true;
    } else {
      map[paramSnapshot] = DocumentSnapshotData.fromSnapshot(
        event.data!,
      ).toMap();
    }
    return map;
  }

  Future handleFirestoreQuery(Map<String, Object?> params) async {
    var queryData = FirestoreQueryData()..firestoreFromMap(firestore, params);
    final query = await getQuery(queryData);

    return await transactionLock.synchronized(() async {
      var querySnapshot = await query.get();

      var data = FirestoreQuerySnapshotData();
      data.list = <DocumentSnapshotData>[];
      for (final doc in querySnapshot.docs) {
        data.list.add(DocumentSnapshotData.fromSnapshot(doc));
      }
      return data.toMap();
    });
  }

  Future handleFirestoreQueryListen(Map<String, Object?> params) async {
    var subscriptionId = newSubscriptionId;
    var queryData = FirestoreQueryData()..firestoreFromMap(firestore, params);
    return await transactionLock.synchronized(() async {
      final query = await getQuery(queryData);

      subscriptions[subscriptionId] = SimSubscription<QuerySnapshot>(
        query.onSnapshot(),
      );

      return {paramSubscriptionId: subscriptionId};
    });
  }

  Future handleFirestoreQueryCancel(Map<String, Object?> params) async {
    var subscriptionId = params[paramSubscriptionId] as int?;
    var subscription = subscriptions[subscriptionId!]!;
    subscriptions.remove(subscriptionId);
    await subscription.cancel();
  }

  Future handleFirestoreQueryStream(Map<String, Object?> params) async {
    // New stream?
    var subscriptionId = params[paramSubscriptionId] as int?;
    final subscription =
        subscriptions[subscriptionId!] as SimSubscription<QuerySnapshot>?;
    try {
      var event = (await subscription?.getNext());
      var map = <String, Object?>{};
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

        bool findDocByPath() {
          for (var doc in querySnapshot.docs) {
            if (doc.ref.path == path) {
              return true;
            }
          }
          return false;
        }

        if (!findDocByPath()) {
          documentChangeData.data = documentDataToJsonMap(
            documentDataFromSnapshot(change.document),
          );
        }
        data.changes!.add(documentChangeData);
      }
      map[paramSnapshot] = data.toMap();
      return map;
    } catch (_) {}
  }

  Future<Query> getQuery(FirestoreQueryData queryData) async {
    var collectionPath = queryData.path;
    // Handle param
    var queryInfo = queryData.queryInfo;
    return await applyQueryInfo(firestore, collectionPath, queryInfo);
  }

  // Batch
  Future handleFirestoreBatch(Map<String, Object?> params) async {
    var batchData = FirestoreBatchData()..firestoreFromMap(firestore, params);

    await transactionLock.synchronized(() async {
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
          item.merge != null ? SetOptions(merge: item.merge) : null,
        );
      } else if (item is BatchOperationUpdateData) {
        batch.update(
          firestore.doc(item.path!),
          documentDataFromJsonMap(firestore, item.data)!.asMap(),
        );
      } else {
        throw 'not supported $item';
      }
    }
    await batch.commit();
  }

  Completer? transactionCompleter;

  // Transaction
  Future handleFirestoreTransaction(Map<String, Object?>? params) async {
    var responseData = FirestoreTransactionResponseData()
      ..transactionId = ++lastTransactionId;

    // start locking but don't wait
    unawaited(
      transactionLock.synchronized(() async {
        transactionCompleter = Completer();
        await transactionCompleter!.future;
        transactionCompleter = null;
      }),
    );
    return responseData.toMap();
  }

  Future handleFirestoreTransactionCommit(Map<String, Object?> params) async {
    var batchData = FirestoreBatchData()..firestoreFromMap(firestore, params);

    if (batchData.transactionId == lastTransactionId) {
      try {
        await _handleFirestoreBatch(batchData);
      } finally {
        // terminate transaction
        transactionCompleter!.complete();
      }
    } else {
      await transactionLock.synchronized(() async {
        await _handleFirestoreBatch(batchData);
      });
    }
  }

  Future handleFirestoreTransactionCancel(Map<String, Object?> params) async {
    var requestData = FirestoreTransactionCancelRequestData()..fromMap(params);

    if (requestData.transactionId == lastTransactionId) {
      // terminate transaction
      transactionCompleter!.complete();
    }
  }
}
