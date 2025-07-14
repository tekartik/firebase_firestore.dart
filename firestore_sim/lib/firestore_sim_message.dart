import 'package:cv/cv.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/firestore_mixin.dart';
import 'package:tekartik_firebase_firestore/utils/json_utils.dart';
import 'package:tekartik_firebase_sim/firebase_sim_message.dart';

const paramPath = 'path';
const paramSnapshot = 'snapshot'; // map

const methodFirestoreSet = 'firestore/set';
const methodFirestoreUpdate = 'firestore/update';
const methodFirestoreAdd = 'firestore/add';
const methodFirestoreGet = 'firestore/get';
const methodFirestoreGetListen =
    'firestore/get/listen'; // first query then next
const methodFirestoreGetStream =
    'firestore/get/stream'; // first query then next
const methodFirestoreGetCancel =
    'firestore/get/cancel'; // query and notification
const methodFirestoreDelete = 'firestore/delete';
const methodFirestoreQuery = 'firestore/query';
const methodFirestoreBatch = 'firestore/batch';
const methodFirestoreTransaction = 'firestore/transaction';
const methodFirestoreTransactionCommit =
    'firestore/transaction/commit'; // batch data
const methodFirestoreTransactionCancel =
    'firestore/transaction/cancel'; // transactionId
const methodFirestoreQueryListen =
    'firestore/query/listen'; // query from client and notification from server
const methodFirestoreQueryStream =
    'firestore/query/stream'; // query from client and notification from server
const methodFirestoreQueryCancel = 'firestore/query/cancel';

class FirestorePathData extends BaseData {
  late String path;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    path = map[paramPath] as String;
  }

  @override
  Model toMap() {
    var map = super.toMap();
    map[paramPath] = path;
    return map;
  }
}

// get/getStream
class FirestoreGetData extends FirestorePathData {}

class FirestoreDocumentSnapshotDataImpl extends FirestoreSetData
    implements FirestoreDocumentSnapshotData {
  @override
  Timestamp? createTime;
  @override
  Timestamp? updateTime;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    createTime = Timestamp.tryAnyAsTimestamp(map['createTime']);
    updateTime = Timestamp.tryAnyAsTimestamp(map['updateTime']);
  }
}

abstract class FirestoreDocumentSnapshotData {
  String get path;

  Map<String, Object?>? get data;

  Timestamp? get createTime;

  Timestamp? get updateTime;
}

class DocumentGetSnapshotData extends DocumentSnapshotData {
  DocumentGetSnapshotData.fromSnapshot(super.snapshot) : super.fromSnapshot();

  // optional for stream only
  int? streamId;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    streamId = map['streamId'] as int?;
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    if (streamId != null) {
      map['streamId'] = streamId;
    }
    return map;
  }
}

// sub date
class DocumentSnapshotData extends FirestorePathData
    implements FirestoreDocumentSnapshotData {
  @override
  Map<String, Object?>? data;

  @override
  Timestamp? createTime;
  @override
  Timestamp? updateTime;

  DocumentSnapshotData.fromSnapshot(DocumentSnapshot snapshot) {
    path = snapshot.ref.path;
    data = snapshotDataToJsonMap(snapshot);
    createTime = snapshot.createTime;
    updateTime = snapshot.updateTime;
  }

  DocumentSnapshotData.fromMessageMap(Map<String, Object?> map) {
    fromMap(map);
  }

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    data = (map['data'] as Map?)?.cast<String, dynamic>();
    createTime = Timestamp.tryAnyAsTimestamp(map['createTime']);
    updateTime = Timestamp.tryAnyAsTimestamp(map['updateTime']);
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    map['data'] = data;
    map['createTime'] = createTime?.toIso8601String();
    map['updateTime'] = updateTime?.toIso8601String();
    return map;
  }
}

class DocumentChangeData extends BaseData {
  String? id;
  String? type; // added/modified/removed
  int? newIndex;
  int? oldIndex;
  Map<String, Object?>? data; // only present for deleted

  @override
  void fromMap(Map map) {
    id = map['id'] as String?;
    type = map['type'] as String?;
    newIndex = map['newIndex'] as int?;
    newIndex = map['oldIndex'] as int?;
    data = (map['data'] as Map?)?.cast<String, dynamic>();
  }

  @override
  Map<String, Object?> toMap() {
    var map = <String, dynamic>{
      'id': id,
      'type': type,
      'newIndex': newIndex,
      'oldIndex': oldIndex,
    };
    if (data != null) {
      map['data'] = data;
    }
    return map;
  }
}

class FirestoreQuerySnapshotData extends BaseData {
  late List<DocumentSnapshotData> list;
  List<DocumentChangeData>? changes;

  // optional for stream only
  int? streamId;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    list = [];
    for (var item in map['list'] as List) {
      list.add(
        DocumentSnapshotData.fromMessageMap(
          (item as Map).cast<String, dynamic>(),
        ),
      );
    }
    changes = [];
    for (var item in map['changes'] as List) {
      changes!.add(
        DocumentChangeData()..fromMap((item as Map).cast<String, dynamic>()),
      );
    }
    streamId = map['streamId'] as int?;
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    var rawList = <Map<String, Object?>>[];
    for (var snapshot in list) {
      rawList.add(snapshot.toMap());
    }
    map['list'] = rawList;

    var rawChanges = <Map<String, Object?>>[];
    if (changes?.isNotEmpty == true) {
      for (var change in changes!) {
        rawChanges.add(change.toMap());
      }
    }
    map['changes'] = rawChanges;

    if (streamId != null) {
      map['streamId'] = streamId;
    }
    return map;
  }
}

class FirestoreSetData extends FirestorePathData {
  Map<String, Object?>? data;
  bool? merge;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    data = (map['data'] as Map?)?.cast<String, dynamic>();
    merge = map['merge'] as bool?;
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    map['data'] = data;
    if (merge != null) {
      map['merge'] = merge;
    }
    return map;
  }
}

class FirestoreGetRequestData extends FirestorePathData {
  int? transactionId;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    transactionId = map['transactionId'] as int?;
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    if (transactionId != null) {
      map['transactionId'] = transactionId;
    }
    return map;
  }
}

class AdminInitializeAppData extends BaseData {
  String? projectId;
  String? name;

  @override
  void fromMap(Map map) {
    projectId = map['projectId'] as String?;
    name = map['name'] as String?;
  }

  @override
  Map<String, Object?> toMap() {
    var map = {'projectId': projectId, 'name': name};
    return map;
  }
}

class FirebaseInitializeAppResponseData extends BaseData {
  int? appId;

  @override
  void fromMap(Map map) {
    appId = map['appId'] as int?;
  }

  @override
  Map<String, Object?> toMap() {
    var map = {'appId': appId};
    return map;
  }
}

class FirestoreTransactionResponseData extends BaseData {
  int? transactionId;

  @override
  void fromMap(Map map) {
    transactionId = map['transactionId'] as int?;
  }

  @override
  Map<String, Object?> toMap() {
    var map = {'transactionId': transactionId};
    return map;
  }
}

class FirestoreQueryData extends FirestorePathData {
  QueryInfo? queryInfo;

  void firestoreFromMap(Firestore firestore, Map<String, Object?> map) {
    super.fromMap(map);
    queryInfo = queryInfoFromJsonMap(
      firestore,
      map['query'] as Map<String, Object?>,
    );
  }

  @override
  @Deprecated('Use firestoreFromMap')
  void fromMap(Map map) {
    throw 'need firestore';
    /*
    super.fromMap(map);
    queryInfo = queryInfoFromJsonMap(map['query'] as Map<String, Object?>);
    */
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    map['query'] = queryInfoToJsonMap(queryInfo!);
    return map;
  }
}

class BatchOperationDeleteData extends BatchOperationData {}

class BatchOperationUpdateData extends BatchOperationData {
  Map<String, Object?>? data;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    data = (map['data'] as Map?)?.cast<String, dynamic>();
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    map['data'] = data;
    return map;
  }
}

class BatchOperationSetData extends BatchOperationData {
  Map<String, Object?>? data;
  bool? merge;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    data = (map['data'] as Map?)?.cast<String, dynamic>();
    merge = map['merge'] as bool?;
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    map['data'] = data;
    if (merge != null) {
      map['merge'] = merge;
    }
    return map;
  }
}

abstract class BatchOperationData extends BaseData {
  String? method;
  String? path;

  @override
  void fromMap(Map map) {
    super.fromMap(map);
    method = map['method'] as String?;
    path = map['path'] as String?;
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    map['method'] = method;
    map['path'] = path;
    return map;
  }
}

// for batch and transaction commit
class FirestoreBatchData extends BaseData {
  int? transactionId;
  List<BatchOperationData> operations = [];

  void firestoreFromMap(Firestore firestore, Map<String, Object?> map) {
    super.fromMap(map);
    var list = map['list'] as List;
    transactionId = map['transactionId'] as int?;

    for (var item in list) {
      var itemMap = (item as Map).cast<String, dynamic>();
      var method = itemMap['method'] as String?;
      switch (method) {
        case methodFirestoreDelete:
          operations.add(BatchOperationDeleteData()..fromMap(itemMap));
          break;
        case methodFirestoreSet:
          operations.add(BatchOperationSetData()..fromMap(itemMap));
          break;
        case methodFirestoreUpdate:
          operations.add(BatchOperationUpdateData()..fromMap(itemMap));
          break;
        default:
          throw 'method $method not supported';
      }
    }
  }

  @override
  @Deprecated('Use firestoreFromMap')
  void fromMap(Map map) {
    throw 'need firestore';
    /*
    super.fromMap(map);
    queryInfo = queryInfoFromJsonMap(map['query'] as Map<String, Object?>);
    */
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    var list = <Map<String, Object?>>[];
    for (var operation in operations) {
      list.add(operation.toMap());
    }
    map['list'] = list;
    if (transactionId != null) {
      map['transactionId'] = transactionId;
    }
    return map;
  }
}

// for batch and transaction commit
class FirestoreTransactionCancelRequestData extends BaseData {
  int? transactionId;

  void firestoreFromMap(Map<String, Object?> map) {
    super.fromMap(map);
    transactionId = map['transactionId'] as int?;
  }

  @override
  Map<String, Object?> toMap() {
    var map = super.toMap();
    if (transactionId != null) {
      map['transactionId'] = transactionId;
    }
    return map;
  }
}

abstract class FirestoreQueryStreamIdBase extends BaseData {
  int? streamId;

  @override
  void fromMap(Map map) {
    streamId = map['streamId'] as int?;
  }

  @override
  Map<String, Object?> toMap() {
    var map = {'streamId': streamId};
    return map;
  }
}

class FirestoreQueryStreamCancelData extends FirestoreQueryStreamIdBase {}

class FirestoreQueryStreamResponse extends FirestoreQueryStreamIdBase {}

class FirestoreGetStreamResponse extends FirestoreQueryStreamResponse {}
