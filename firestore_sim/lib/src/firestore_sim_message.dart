import 'package:cv/cv.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/firestore_mixin.dart';
import 'package:tekartik_firebase_firestore/utils/json_utils.dart';
import 'package:tekartik_firebase_sim/firebase_sim_server_mixin.dart';

/// Path parameter.
const paramPath = 'path';

/// Snapshot parameter.
const paramSnapshot = 'snapshot'; // map

/// Set method.
const methodFirestoreSet = 'firestore/set';

/// Update method.
const methodFirestoreUpdate = 'firestore/update';

/// Add method.
const methodFirestoreAdd = 'firestore/add';

/// Get method.
const methodFirestoreGet = 'firestore/get';

/// Get listen method.
const methodFirestoreGetListen =
    'firestore/get/listen'; // first query then next
/// Get stream method.
const methodFirestoreGetStream =
    'firestore/get/stream'; // first query then next
/// Get cancel method.
const methodFirestoreGetCancel =
    'firestore/get/cancel'; // query and notification
/// Delete method.
const methodFirestoreDelete = 'firestore/delete';

/// Query method.
const methodFirestoreQuery = 'firestore/query';

/// Batch method.
const methodFirestoreBatch = 'firestore/batch';

/// Transaction method.
const methodFirestoreTransaction = 'firestore/transaction';

/// Transaction commit method.
const methodFirestoreTransactionCommit =
    'firestore/transaction/commit'; // batch data
/// Transaction cancel method.
const methodFirestoreTransactionCancel =
    'firestore/transaction/cancel'; // transactionId
/// Query listen method.
const methodFirestoreQueryListen =
    'firestore/query/listen'; // query from client and notification from server
/// Query stream method.
const methodFirestoreQueryStream =
    'firestore/query/stream'; // query from client and notification from server
/// Query cancel method.
const methodFirestoreQueryCancel = 'firestore/query/cancel';

/// Init CV builders.
void firebaseSimFirestoreInitCvBuilders() {
  cvAddConstructors([CvFirestoreAppBaseData.new]);
}

/// App data for CV.
class CvFirestoreAppBaseData extends CvFirebaseSimAppBaseData {}

/// App data base.
class FirestoreAppBaseData extends BaseData {}

/// Path data.
class FirestorePathData extends FirestoreAppBaseData {
  /// Path.
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

/// Path data for CV.
class CvFirestorePathData extends CvFirestoreAppBaseData {
  /// Path.
  final path = CvField<String>('path');

  @override
  CvFields get fields => [path, ...super.fields];
}

// get/getStream
/// Get data.
class FirestoreGetData extends FirestorePathData {}

/// Document snapshot data implementation.
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

/// Document snapshot data.
abstract class FirestoreDocumentSnapshotData {
  /// Path.
  String get path;

  /// Data.
  Map<String, Object?>? get data;

  /// Create time.
  Timestamp? get createTime;

  /// Update time.
  Timestamp? get updateTime;
}

/// Document get snapshot data.
class DocumentGetSnapshotData extends DocumentSnapshotData {
  /// Constructor from snapshot.
  DocumentGetSnapshotData.fromSnapshot(super.snapshot) : super.fromSnapshot();

  // optional for stream only
  /// Stream id.
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
/// Document snapshot data.
class DocumentSnapshotData extends FirestorePathData
    implements FirestoreDocumentSnapshotData {
  @override
  Map<String, Object?>? data;

  @override
  Timestamp? createTime;
  @override
  Timestamp? updateTime;

  /// Constructor from snapshot.
  DocumentSnapshotData.fromSnapshot(DocumentSnapshot snapshot) {
    path = snapshot.ref.path;
    data = snapshotDataToJsonMap(snapshot);
    createTime = snapshot.createTime;
    updateTime = snapshot.updateTime;
  }

  /// Constructor from message map.
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

/// Document change data.
class DocumentChangeData extends FirestoreAppBaseData {
  /// Id.
  String? id;

  /// Type.
  String? type; // added/modified/removed
  /// New index.
  int? newIndex;

  /// Old index.
  int? oldIndex;

  /// Data.
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

/// Firestore query snapshot data.
class FirestoreQuerySnapshotData extends FirestoreAppBaseData {
  /// List of snapshots.
  late List<DocumentSnapshotData> list;

  /// List of changes.
  List<DocumentChangeData>? changes;

  // optional for stream only
  /// Stream id.
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

/// Firestore set data.
class FirestoreSetData extends FirestorePathData {
  /// Data.
  Map<String, Object?>? data;

  /// Merge.
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

/// Firestore set data for CV.
class CvFirestoreSetData extends CvFirestorePathData {
  /// Data.
  final data = CvField<Model>('data');

  /// Merge.
  final merge = CvField<bool>('merge');
  @override
  CvFields get fields => [data, merge, ...super.fields];
}

/// Firestore get request data.
class FirestoreGetRequestData extends FirestorePathData {
  /// Transaction id.
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

/// Firestore get request data for CV.
class CvFirestoreGetRequestData extends CvFirestorePathData {
  /// Transaction id.
  final transactionId = CvField<int>('transactionId');

  @override
  CvFields get fields => [transactionId, ...super.fields];
}

/// Firestore transaction response data.
class FirestoreTransactionResponseData extends FirestoreAppBaseData {
  /// Transaction id.
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

/// Firestore query data.
class FirestoreQueryData extends FirestorePathData {
  /// Query info.
  QueryInfo? queryInfo;

  /// Internal from map.
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

/// Batch operation delete data.
class BatchOperationDeleteData extends BatchOperationData {}

/// Batch operation update data.
class BatchOperationUpdateData extends BatchOperationData {
  /// Data.
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

/// Batch operation set data.
class BatchOperationSetData extends BatchOperationData {
  /// Data.
  Map<String, Object?>? data;

  /// Merge.
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

/// Batch operation data.
abstract class BatchOperationData extends FirestoreAppBaseData {
  /// Method.
  String? method;

  /// Path.
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
/// Firestore batch data.
class FirestoreBatchData extends FirestoreAppBaseData {
  /// Transaction id.
  int? transactionId;

  /// Operations.
  List<BatchOperationData> operations = [];

  /// Internal from map.
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
/// Firestore transaction cancel request data.
class FirestoreTransactionCancelRequestData extends FirestoreAppBaseData {
  /// Transaction id.
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

/// Firestore query stream id base.
abstract class FirestoreQueryStreamIdBase extends FirestoreAppBaseData {
  /// Stream id.
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

/// Firestore query stream cancel data.
class FirestoreQueryStreamCancelData extends FirestoreQueryStreamIdBase {}

/// Firestore query stream response.
class FirestoreQueryStreamResponse extends FirestoreQueryStreamIdBase {}

/// Firestore get stream response.
class FirestoreGetStreamResponse extends FirestoreQueryStreamResponse {}
