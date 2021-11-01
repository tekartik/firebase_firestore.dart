import 'dart:math';

import 'package:path/path.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/reference_mixin.dart';
import 'package:tekartik_firebase_firestore/src/firestore.dart';
import 'package:tekartik_firebase_firestore/src/firestore_common.dart';
import 'package:tekartik_firebase_firestore/utils/firestore_mixin.dart';

export 'package:tekartik_firebase_firestore/src/common/document_snapshot_mixin.dart'
    show DocumentSnapshotMixin;
export 'package:tekartik_firebase_firestore/src/firestore_common.dart'
    show
        WriteBatchBase,
        WriteBatchOperationDelete,
        WriteBatchOperationUpdate,
        WriteBatchOperationSet,
        WriteResultBase,
        DocumentChangeBase,
        QuerySnapshotBase,
        DocumentSnapshotBase;
export 'package:tekartik_firebase_firestore/src/record_data.dart'
    show
        recordMapRev,
        revKey,
        documentDataFromRecordMap,
        documentDataToRecordMap,
        recordMapUpdateTime,
        RecordMetaData,
        valueToRecordValue,
        documentDataMap,
        recordMapCreateTime,
        FieldValueArray,
        fieldArrayValueMergeValue;

// might evolve to be always true
bool firestoreTimestampsInSnapshots(Firestore firestore) {
  /*
  if (firestore is FirestoreMixin) {
    return firestore.firestoreSettings?.timestampsInSnapshots == true;
  }
   */
  return true;
}

mixin FirestoreMixin implements Firestore {
  FirestoreSettings? firestoreSettings;

  @override
  void settings(FirestoreSettings settings) {
    if (firestoreSettings != null) {
      throw StateError(
          'firestore settings already set to $firestoreSettings cannot set to $settings');
    }
    firestoreSettings = settings;
  }

  /// Could be optimized on some implementation
  @override
  Future<List<DocumentSnapshot>> getAll(List<DocumentReference> refs) async {
    return await Future.wait(refs.map((ref) => ref.get()));
  }
}

mixin FirestoreDocumentsMixin on Firestore {
  DocumentSnapshot newSnapshot(
      DocumentReference ref, RecordMetaData? meta, DocumentData? data);

  QuerySnapshot newQuerySnapshot(
      List<DocumentSnapshot> docs, List<DocumentChange> changes);

  // Remove meta keys
  DocumentSnapshot documentFromRecordMap(
      DocumentReference ref, Map<String, Object?>? recordMap) {
    var meta =
        recordMap == null ? null : RecordMetaData.fromRecordMap(recordMap);
    return newSnapshot(
      ref,
      meta,
      documentDataFromRecordMap(this, recordMap),
    );
  }
}

class CollectionSubscription extends FirestoreSubscription<DocumentChange> {}

class DocumentSubscription extends FirestoreSubscription<DocumentSnapshot> {}

abstract class FirestoreSubscription<T> {
  String? path;
  int count = 0;
  var streamController = StreamController<T>.broadcast();
}

mixin FirestoreSubscriptionMixin on Firestore {
  Future closeSubscriptions() async {
    for (var subscription in subscriptions.values.toList()) {
      await _clearSubscription(subscription);
    }
  }

  // key is path
  final subscriptions = <String?, FirestoreSubscription>{};

  FirestoreSubscription<T?>? findSubscription<T>(String? path) {
    return subscriptions[path] as FirestoreSubscription<T?>?;
  }

  CollectionSubscription addCollectionSubscription(String path) {
    return _addSubscription(path, () => CollectionSubscription())
        as CollectionSubscription;
  }

  DocumentSubscription addDocumentSubscription(String? path) {
    return _addSubscription(path, () => DocumentSubscription())
        as DocumentSubscription;
  }

  FirestoreSubscription<T> _addSubscription<T>(
      String? path, FirestoreSubscription<T> Function() create) {
    var subscription = findSubscription<T>(path);
    if (subscription == null) {
      subscription = create()..path = path;
      subscriptions[path] = subscription;
    }
    subscription.count++;
    return subscription as FirestoreSubscription<T>;
  }

  // ref counting
  Future removeSubscription(FirestoreSubscription subscription) async {
    if (--subscription.count == 0) {
      await _clearSubscription(subscription);
    }
  }

  Future _clearSubscription(FirestoreSubscription subscription) async {
    subscriptions.remove(subscription.path);
    await subscription.streamController.close();
  }

  // DocumentSnapshot snapshotFromReferenceRevAndData(DocumentReference documentReference, int rev, DocumentData documentData, {Timestamp updateTime, Timestamp createTime});

  DocumentSnapshot cloneSnapshot(DocumentSnapshot documentSnapshot);

  DocumentSnapshot deletedSnapshot(DocumentReference documentReference);

  DocumentChangeBase documentChange(DocumentChangeType type,
      DocumentSnapshot document, int newIndex, int oldIndex);

  void notify(WriteResultBase result) {
    var path = result.path;
    var documentSubscription = findSubscription(path);
    var newSnapshot = result.newSnapshot;
    var previousSnapshot = result.previousSnapshot;
    var added = result.added;
    var removed = result.removed;
    if (documentSubscription != null) {
      if (newSnapshot?.exists == true) {
        documentSubscription.streamController.add(cloneSnapshot(newSnapshot!));
      } else {
        // this is a delete
        documentSubscription.streamController.add(deletedSnapshot(doc(path)));
      }
    }
    // notify collection listeners
    var collectionSubscription = findSubscription(url.dirname(path));
    if (collectionSubscription != null) {
      var change = documentChange(
          added
              ? DocumentChangeType.added
              : (removed
                  ? DocumentChangeType.removed
                  : DocumentChangeType.modified),
          removed
              ? cloneSnapshot(previousSnapshot!)
              : cloneSnapshot(newSnapshot!),
          -1,
          -1);
      collectionSubscription.streamController.add(change);
    }
  }

  Stream<DocumentSnapshot> onSnapshot(DocumentReference documentRef) {
    var subscription = addDocumentSubscription(documentRef.path);
    late StreamSubscription querySubscription;
    var controller = StreamController<DocumentSnapshot>(onCancel: () {
      querySubscription.cancel();
    });

    querySubscription = subscription.streamController.stream.listen(
        (DocumentSnapshot snapshot) async {
      controller.add(snapshot);
    }, onDone: () {
      removeSubscription(subscription);
    });

    // Get the first batch
    documentRef.get().then((DocumentSnapshot snapshot) {
      controller.add(snapshot);
    });
    return controller.stream;
  }
}

bool mapWhere(DocumentData? documentData, WhereInfo where) {
  // We always use Timestamp even for DateTime
  FirestoreComparable? _makeComparableValue(dynamic value) {
    return _getComparable(value);
  }

  var rawValue =
      documentDataMap(documentData)!.valueAtFieldPath(where.fieldPath);
  var comparableFieldValue = _makeComparableValue(rawValue);

  // bool and null are not comparable
  bool isFieldValueComparable() {
    return comparableFieldValue?.isComparable ?? false;
  }

  if (where.isNull == true) {
    return rawValue == null;
  } else if (where.isNull == false) {
    return rawValue != null;
  } else if (where.isEqualTo != null) {
    // Use comparable
    if (comparableFieldValue == null) {
      return false;
    }
    var equalsToValue = _makeComparableValue(where.isEqualTo);
    return (comparableFieldValue.compareTo(equalsToValue) == 0);
  } else if (where.isGreaterThan != null) {
    if (!isFieldValueComparable()) {
      return false;
    }
    return (comparableFieldValue!
            .compareTo(_makeComparableValue(where.isGreaterThan)) >
        0);
  } else if (where.isGreaterThanOrEqualTo != null) {
    if (!isFieldValueComparable()) {
      return false;
    }
    return (comparableFieldValue!
            .compareTo(_makeComparableValue(where.isGreaterThanOrEqualTo)) >=
        0);
  } else if (where.isLessThan != null) {
    if (!isFieldValueComparable()) {
      return false;
    }
    return (comparableFieldValue!
            .compareTo(_makeComparableValue(where.isLessThan)) <
        0);
  } else if (where.isLessThanOrEqualTo != null) {
    if (!isFieldValueComparable()) {
      return false;
    }
    return (comparableFieldValue!
            .compareTo(_makeComparableValue(where.isLessThanOrEqualTo)) <=
        0);
  } else if (where.arrayContains != null) {
    // Handle liste
    if (rawValue is Iterable) {
      return rawValue.contains(where.arrayContains);
    }
  } else if (where.arrayContainsAny != null) {
    if (rawValue is Iterable) {
      for (var any in where.arrayContainsAny!) {
        if (rawValue.contains(any)) {
          return true;
        }
      }
    }
  } else if (where.whereIn != null) {
    return where.whereIn!.contains(rawValue);
  } else {
    // devWarning(throw UnsupportedError('where: $where on $documentData'));
  }
  return false;
}

T? safeGetItem<T>(List<T>? list, int index) {
  if (list != null && list.length > index) {
    return list[index];
  }
  return null;
}

class FirestoreComparable {
  final Comparable? comparable;
  final dynamic nonComparable;

  FirestoreComparable(this.comparable, [this.nonComparable]);

  bool get isComparable => comparable != null;

  int compareTo(FirestoreComparable? other) {
    try {
      if (other == null) {
        return -1;
      }
      if (comparable != null) {
        return comparable!.compareTo(other.comparable);
      } else if (other.comparable != null) {
        return -1;
      } else {
        return (nonComparable == other.nonComparable) ? 0 : -1;
      }
    } catch (_) {
      // Dummy for easy spotting
      return -9999;
    }
  }

  static int compare(FirestoreComparable? a, FirestoreComparable? b) =>
      a?.compareTo(b) ?? -1;
}

/// Null is not comparable
FirestoreComparable? _getComparable(dynamic value) {
  if (value is FirestoreComparable) {
    return value;
  }
  if (value is DateTime) {
    return FirestoreComparable(Timestamp.fromDateTime(value));
  }
  if (value is Comparable) {
    return FirestoreComparable(value);
  } else if (value is List) {
    return FirestoreComparable(ComparableList(value));
  } else if (value is Map) {
    return FirestoreComparable(ComparableMap(value));
  }
  if (value == null) {
    return null;
  }
  return FirestoreComparable(null, value);
}

class ComparableList<E> with ListMixin<E> implements Comparable<List<E>?> {
  final List<E> _list;

  ComparableList(this._list);

  @override
  int get length => _list.length;

  @override
  E operator [](int index) => _list[index];

  @override
  void operator []=(int index, E value) {
    throw StateError('read-only');
  }

  @override
  int compareTo(List? other) {
    for (var i = 0; i < min(other!.length, length); i++) {
      var item1 = _getComparable(this[i])!;
      var item2 = _getComparable(other[i]);
      final result = item1.compareTo(item2);
      if (result != 0) {
        return result;
      }
    }
    // compare length
    return length - other.length;
  }

  @override
  set length(int newLength) {
    throw StateError('read-only');
  }
}

class ComparableMap<K, V>
    with MapMixin<K, V>
    implements Comparable<Map<K, V>?> {
  final Map<K, V> _map;

  ComparableMap(this._map);

  @override
  V? operator [](Object? key) => _map[key as K];

  @override
  void operator []=(key, value) {
    throw StateError('read-only');
  }

  @override
  void clear() {
    throw StateError('read-only');
  }

  @override
  Iterable<K> get keys => _map.keys;

  @override
  V remove(Object? key) {
    throw StateError('read-only');
  }

  @override
  int compareTo(Map<K, V>? other) {
    var keys1 = keys.toList(growable: false)..sort();
    var keys2 = other!.keys.toList(growable: false)..sort();
    for (var i = 0; i < min(length, other.length); i++) {
      final key1 = keys1[i];
      final key2 = keys2[i];
      var result = _getComparable(key1)!.compareTo(_getComparable(key2));
      if (result != 0) {
        return result;
      }
      final value1 = this[key1];
      final value2 = other[key2];
      result = _getComparable(value1)!.compareTo(_getComparable(value2));
      if (result != 0) {
        return result;
      }
    }
    return length - other.length;
  }
}

int _compare(FirestoreComparable value1, FirestoreComparable value2,
    [bool ascending = true]) {
  final compareValue = FirestoreComparable.compare(value1, value2);
  if (ascending != false) {
    return compareValue;
  } else {
    return -compareValue;
  }
}

int _rawCompareHandleNull(
    FirestoreComparable? object1, FirestoreComparable? object2) {
  if (object2 == null) {
    if (object1 == null) {
      return 0;
    }
    return -1;
    // put object2 at the end
  } else if (object1 == null) {
    // put object1 at the end
    return 1;
  }
  return object1.compareTo(object2);
}

int _compareHandleNull(
    FirestoreComparable? object1, FirestoreComparable? object2,
    [bool ascending = true]) {
  final compareValue = _rawCompareHandleNull(object1, object2);
  if (ascending != false) {
    return compareValue;
  } else {
    return -compareValue;
  }
}

bool snapshotMapQueryInfo(DocumentSnapshotBase snapshot, QueryInfo queryInfo) {
  var data = snapshot.documentData as DocumentDataMap?;

  FirestoreComparable? getComparableValue(String? fieldPath) {
    dynamic value;
    if (fieldPath != firestoreNameFieldPath) {
      value = data!.valueAtFieldPath(fieldPath!);

      // Convert DateTime to Timestamp
      return _getComparable(value);

      //return null;
    } else {
      return _getComparable(snapshot.ref.id);
    }
  }
  //var data = documentData.map;
  // if (data != null) {
  //bool add = true;

  // Ignore if one sorted field is null
  if (queryInfo.orderBys.isNotEmpty) {
    for (var i = 0; i < queryInfo.orderBys.length; i++) {
      var fieldPath = queryInfo.orderBys[i].fieldPath;
      // Must be non null and comparable
      if (getComparableValue(fieldPath) == null) {
        return false;
      }
    }
  }

  if (queryInfo.wheres.isNotEmpty) {
    for (var where in queryInfo.wheres) {
      if (!mapWhere(data, where)) {
        return false;
      }
    }
  }

  if (((queryInfo.startLimit?.values != null ||
              queryInfo.endLimit?.values != null) &&
          queryInfo.orderBys.isNotEmpty) ||
      queryInfo.wheres.isNotEmpty) {
    var startCompare = 0;
    var endCompare = 0;
    for (var i = 0; i < queryInfo.orderBys.length; i++) {
      var orderBy = queryInfo.orderBys[i];
      var fieldPath = orderBy.fieldPath;
      final value = getComparableValue(fieldPath);

      // Start
      dynamic rawLimitValue = safeGetItem(queryInfo.startLimit?.values, i);
      if (rawLimitValue != null) {
        final limitValue = _getComparable(rawLimitValue)!;

        startCompare = _compare(value!, limitValue, orderBy.ascending);

        if (startCompare > 0) {
          return true;
        } else if (startCompare < 0) {
          return false;
        }
      }

      // End
      rawLimitValue = safeGetItem(queryInfo.endLimit?.values, i);
      if (rawLimitValue != null) {
        final limitValue = _getComparable(rawLimitValue)!;

        endCompare = _compare(value!, limitValue, orderBy.ascending);

        if (endCompare < 0) {
          return true;
        } else if (endCompare > 0) {
          return false;
        }
      }
    }
    // So we know we are equals
    if (queryInfo.startLimit != null &&
        queryInfo.startLimit!.inclusive != true) {
      return false;
    }
    if (queryInfo.endLimit != null && queryInfo.endLimit!.inclusive != true) {
      return false;
    }
  }

  return true;
}

abstract class FirestoreReferenceBase
    with PathReferenceImplMixin, PathReferenceMixin {
  FirestoreReferenceBase(Firestore firestore, String path) {
    init(firestore, path);
  }
}

mixin FirestoreQueryMixin implements Query {
  Firestore get firestore;

  String get path;

  FirestoreDocumentsMixin get documentsMixin =>
      firestore as FirestoreDocumentsMixin;

  FirestoreSubscriptionMixin get subscriptionMixin =>
      firestore as FirestoreSubscriptionMixin;

  QueryInfo? get queryInfo;

  Future<List<DocumentSnapshot>> getCollectionDocuments();

  @override
  Future<QuerySnapshot> get() async {
    var queryInfo = this.queryInfo!;
    // Get and filter
    var docs = <DocumentSnapshot>[];
    var allDocs = await getCollectionDocuments();
    for (var doc in allDocs) {
      if (snapshotMapQueryInfo(doc as DocumentSnapshotBase, queryInfo)) {
        docs.add(doc);
      }
    }

    // if firestoreNameFieldPath (__name__) is not specified, add it
    var fieldPathFound = false;

    var orderBys = List<OrderByInfo>.from(queryInfo.orderBys);
    for (var orderBy in orderBys) {
      if (orderBy.fieldPath == firestoreNameFieldPath) {
        fieldPathFound = true;
        break;
      }
    }

    docs.sort((DocumentSnapshot snapshot1, DocumentSnapshot snapshot2) {
      var cmp = 0;

      if (!fieldPathFound) {
        orderBys.add(
            OrderByInfo(fieldPath: firestoreNameFieldPath, ascending: true));
      }

      for (var orderBy in orderBys) {
        final keyPath = orderBy.fieldPath;
        final ascending = orderBy.ascending;

        int _compare(
            FirestoreComparable? object1, FirestoreComparable? object2) {
          return _compareHandleNull(object1, object2, ascending);
        }

        DocumentDataMap? snapshotDataMap(DocumentSnapshot snapshot) {
          return ((snapshot as DocumentSnapshotBase).documentData
              as DocumentDataMap?);
        }

        if (keyPath == firestoreNameFieldPath) {
          cmp = _compare(_getComparable(snapshot1.ref.path)!,
              _getComparable(snapshot2.ref.path)!);
        } else {
          cmp = _compare(
            _getComparable(
                snapshotDataMap(snapshot1)!.valueAtFieldPath(keyPath!))!,
            _getComparable(
                snapshotDataMap(snapshot2)!.valueAtFieldPath(keyPath))!,
          );
        }
        if (cmp != 0) {
          break;
        }
      }
      return cmp;
    });

    // Handle snapshot filtering (after ordering)
    final filteredDocs = <DocumentSnapshot>[];
    if (queryInfo.startLimit?.documentId != null ||
        queryInfo.endLimit?.documentId != null) {
      var add = true;
      if (queryInfo.startLimit?.documentId != null) {
        add = false;
      }
      for (var snapshot in docs) {
        if (!add && queryInfo.startLimit?.documentId != null) {
          if (snapshot.ref.id == queryInfo.startLimit!.documentId) {
            add = true;
            if (!queryInfo.startLimit!.inclusive) {
              // skip this one
              continue;
            }
          }
        }
        // stop now?
        if (add && queryInfo.endLimit?.documentId != null) {
          if (snapshot.ref.id == queryInfo.endLimit!.documentId) {
            if (queryInfo.endLimit!.inclusive) {
              filteredDocs.add(snapshot);
            }
            break;
          }
        }

        if (add) {
          filteredDocs.add(snapshot);
        }
      }

      docs = filteredDocs;
    }

    // offset && limit
    if (queryInfo.limit != null || queryInfo.offset != null) {
      final limitedDocs = <DocumentSnapshot>[];
      var index = 0;
      for (var snapshot in docs) {
        if (queryInfo.offset != null) {
          if (index < queryInfo.offset!) {
            index++;
            continue;
          }
        }
        if (queryInfo.limit != null) {
          if (limitedDocs.length >= queryInfo.limit!) {
            break;
          }
        }
        index++;
        limitedDocs.add(snapshot);
      }
      docs = limitedDocs;
    }

    // Apply select
    if (queryInfo.selectKeyPaths != null) {
      final selectedDocs = <DocumentSnapshot>[];
      for (var snapshot in docs) {
        var meta = (snapshot as DocumentSnapshotBase).meta;
        var data = snapshot.documentData as DocumentDataMap;
        selectedDocs.add(documentsMixin.newSnapshot(
            snapshot.ref,
            meta,
            DocumentData(
                toSelectedMap(data.asMap(), queryInfo.selectKeyPaths!))));
      }
      docs = selectedDocs;
    }
    return documentsMixin.newQuerySnapshot(docs, []);
  }

  @override
  Query select(List<String> list) {
    return clone()..queryInfo!.selectKeyPaths = list;
  }

  @override
  Query limit(int limit) => clone()..queryInfo!.limit = limit;

  @override
  Query orderBy(String key, {bool? descending}) => clone()
    ..addOrderBy(
        key, descending == true ? orderByDescending : orderByAscending);

  FirestoreQueryMixin clone();

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
  }) =>
      clone()
        ..queryInfo!.addWhere(WhereInfo(fieldPath,
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
  Stream<QuerySnapshot> onSnapshot() {
    var collectionSubscription =
        subscriptionMixin.addCollectionSubscription(path);
    late StreamSubscription querySubscription;
    var controller = StreamController<QuerySnapshot>(onCancel: () {
      querySubscription.cancel();
    });

    querySubscription = collectionSubscription.streamController.stream.listen(
        (DocumentChange collectionDocumentChange) async {
      final documentChange = collectionDocumentChange as DocumentChangeBase;
      // get the base data
      var querySnapshot = await get() as QuerySnapshotBase;
      if (snapshotMapQueryInfo(
          documentChange.document as DocumentSnapshotBase, queryInfo!)) {
        querySnapshot.documentChanges.add(documentChange);
      } else if (documentChange.type == DocumentChangeType.removed) {
        if (querySnapshot.contains(documentChange.documentBase)) {
          querySnapshot.documentChanges.add(documentChange);
        }
      }
      controller.add(querySnapshot);
    }, onDone: () {
      subscriptionMixin.removeSubscription(collectionSubscription);
    });

    // Get the first batch
    get().then((QuerySnapshot querySnaphost) {
      var querySnapshotBase = querySnaphost as QuerySnapshotBase;
      // set index
      var index = 0;
      for (var doc in querySnaphost.docs) {
        querySnapshotBase.documentChanges.add(subscriptionMixin.documentChange(
            DocumentChangeType.added, doc, index++, -1));
      }
      controller.add(querySnapshotBase);
    });
    return controller.stream;
  }
}

abstract class ReferenceAttributes {
  String? get parentPath;

  String get id;

  String getChildPath(String path);
}

abstract class AttributesMixin implements ReferenceAttributes {
  // FirestoreReferenceBase get baseRef;

  String get path;

  @override
  String? get parentPath {
    final dirPath = url.dirname(path);
    if (dirPath.isEmpty == true) {
      return null;
    } else if (dirPath == '.') {
      // Mimic firestore behavior where the top document has a '' path
      return '';
    } else if (dirPath == '/') {
      // Mimic firestore behavior where the top document has a '' path
      return '';
    }
    return dirPath;
  }

  @override
  String get id => url.basename(path);

  @override
  String getChildPath(String path) => url.join(this.path, path);
}
