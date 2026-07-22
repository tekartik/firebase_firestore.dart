import 'dart:math';

import 'package:path/path.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/env_utils.dart';
import 'package:tekartik_firebase_firestore/src/common/import_firestore_mixin.dart';
import 'package:tekartik_firebase_firestore/src/firestore_common.dart';

export 'package:tekartik_firebase_firestore/src/common/document_snapshot_mixin.dart'
    show DocumentSnapshotMixin;
export 'package:tekartik_firebase_firestore/src/common/time_mixin.dart';
export 'package:tekartik_firebase_firestore/src/firestore_common.dart'
    show
        WriteBatchBase,
        WriteBatchOperationDelete,
        WriteBatchOperationUpdate,
        WriteBatchOperationSet,
        WriteResultBase,
        DocumentChangeBase,
        QuerySnapshotBase,
        DocumentSnapshotBase,
        QueryInfo,
        queryInfoFromJsonMap,
        queryInfoToJsonMap,
        WhereInfo;
export 'package:tekartik_firebase_firestore/src/record_data.dart'
    show
        recordMapRev,
        revKey,
        documentDataFromRecordMap,
        // ignore: deprecated_member_use_from_same_package
        documentDataToRecordMap,
        recordMapUpdateTime,
        RecordMetaData,
        // ignore: deprecated_member_use_from_same_package
        valueToRecordValue,
        valueToJsonRecordValue,
        documentDataMap,
        recordMapCreateTime,
        FieldValueArray,
        fieldArrayValueMergeValue;

/// Compares [snapshot] against a cursor described by [limitInfo] (a
/// `startAt`/`startAfter`/`endAt`/`endBefore` value), ordered according to
/// [queryInfo]'s `orderBy` clauses.
///
/// Returns a negative number if [snapshot] sorts before the cursor, zero if
/// it sorts at the same position, and a positive number if it sorts after.
/// Used by in-memory query execution (see [FirestoreQueryMixin]) to decide
/// which documents fall within a cursor-bounded range.
int queryCompareSnapshotToLimit(
  QueryInfo queryInfo,
  DocumentSnapshot snapshot,
  LimitInfo limitInfo,
) {
  // devPrint(limitInfo);
  var orderBys = queryInfo.orderBys;
  var documentId = limitInfo.documentId;
  if (documentId != null) {
    return snapshot.ref.id.compareTo(documentId);
  } else {
    var values = limitInfo.values!;
    var cmp = 0;

    for (var i = 0; i < orderBys.length; i++) {
      var orderBy = orderBys[i];

      final keyPath = orderBy.fieldPath!;
      final ascending = orderBy.ascending;

      int firestoreCompare(
        FirestoreComparable? object1,
        FirestoreComparable? object2,
      ) {
        return _compareHandleNull(object1, object2, ascending);
      }

      DocumentDataMap? snapshotDataMap(DocumentSnapshot snapshot) {
        return ((snapshot as DocumentSnapshotBase).documentData
            as DocumentDataMap?);
      }

      int compareAtKeyPath(String keyPath) {
        if (keyPath == firestoreNameFieldPath) {
          // If not specified, ignore
          if (values.length <= i) {
            cmp = 0;
          } else {
            var limitValue = limitInfo.values![i];
            cmp = firestoreCompare(
              _getComparable(snapshot.ref.id)!,
              _getComparable(limitValue)!,
            );
          }
        } else {
          var limitValue = limitInfo.values![i];
          cmp = firestoreCompare(
            _getComparable(
              snapshotDataMap(snapshot)!.valueAtFieldPath(keyPath),
            )!,
            _getComparable(limitValue)!,
          );
        }
        return cmp;
      }

      cmp = compareAtKeyPath(keyPath);
      if (cmp != 0) {
        break;
      }
    }
    return cmp;
  }
}

// might evolve to be always true
/// Returns whether date/time fields read from [firestore] snapshots should
/// be represented as [Timestamp] (`true`) rather than [DateTime].
///
/// Currently always returns `true` regardless of [firestore]; kept as a
/// function (rather than a constant) in case this becomes configurable
/// again in the future.
bool firestoreTimestampsInSnapshots(Firestore firestore) {
  /*
  if (firestore is FirestoreMixin) {
    return firestore.firestoreSettings?.timestampsInSnapshots == true;
  }
   */
  return true;
}

/// [Firestore] mixin providing [listCollections] and [collectionGroup]
/// implementations that always throw [UnimplementedError], for backends
/// that don't support them.
mixin FirestoreDefaultMixin implements Firestore {
  @override
  Future<List<CollectionReference>> listCollections() {
    throw UnimplementedError('listCollections not implemented');
  }

  @override
  Query collectionGroup(String collectionId) {
    throw UnimplementedError('collectionGroup not implemented');
  }
}

/// [Firestore] mixin providing [settings] (storing them in
/// [firestoreSettings] and rejecting a second call) and a naive [getAll]
/// implementation (parallel [DocumentReference.get] calls).
mixin FirestoreMixin implements Firestore {
  /// The settings passed to [settings], or `null` if [settings] has not been
  /// called yet.
  FirestoreSettings? firestoreSettings;

  @override
  void settings(FirestoreSettings settings) {
    if (firestoreSettings != null) {
      throw StateError(
        'firestore settings already set to $firestoreSettings cannot set to $settings',
      );
    }
    firestoreSettings = settings;
  }

  /// Could be optimized on some implementation
  @override
  Future<List<DocumentSnapshot>> getAll(List<DocumentReference> refs) async {
    return await Future.wait(refs.map((ref) => ref.get()));
  }
}

/// Mixin defining the factory methods a [Firestore] implementation needs to
/// build snapshots from raw storage/backend data.
///
/// Implementations that use this mixin can rely on
/// [documentFromRecordMap] to convert a raw record map into a
/// [DocumentSnapshot] via [newSnapshot].
mixin FirestoreDocumentsMixin on Firestore {
  /// Creates a new [DocumentSnapshot] for [ref], with the given [meta]
  /// (revision/timestamps) and [data] (`null` if the document does not
  /// exist).
  DocumentSnapshot newSnapshot(
    DocumentReference ref,
    RecordMetaData? meta,
    DocumentData? data,
  );

  /// Creates a new [QuerySnapshot] with the given matching [docs] and
  /// [changes] since the previous snapshot.
  QuerySnapshot newQuerySnapshot(
    List<DocumentSnapshot> docs,
    List<DocumentChange> changes,
  );

  /// Builds a [DocumentSnapshot] for [ref] from a raw backend [recordMap].
  ///
  /// [recordMap] is `null` when the document does not exist, in which case
  /// the returned snapshot has no data and no metadata. Metadata (revision,
  /// create/update time) is extracted from [recordMap] via
  /// [RecordMetaData.fromRecordMap].
  DocumentSnapshot documentFromRecordMap(
    DocumentReference ref,
    Map<String, Object?>? recordMap,
  ) {
    var meta = recordMap == null
        ? null
        : RecordMetaData.fromRecordMap(recordMap);
    return newSnapshot(ref, meta, documentDataFromRecordMap(this, recordMap));
  }
}

/// A [FirestoreSubscription] backing the listeners of a collection query
/// (`Query.onSnapshot`), delivering [DocumentChange] events.
class CollectionSubscription extends FirestoreSubscription<DocumentChange> {}

/// A [FirestoreSubscription] backing the listeners of a single document
/// (`DocumentReference.onSnapshot`), delivering [DocumentSnapshot] events.
class DocumentSubscription extends FirestoreSubscription<DocumentSnapshot> {}

/// Bookkeeping for a single active `onSnapshot` listener registration on a
/// given [path], shared by every subscriber to that path so events are
/// broadcast once and reference-counted via [count].
abstract class FirestoreSubscription<T> {
  /// The document or collection path this subscription listens to, or
  /// `null` if not yet assigned.
  String? path;

  /// The number of active listeners sharing this subscription.
  int count = 0;

  /// The broadcast stream controller events are published on.
  var streamController = StreamController<T>.broadcast();
}

/// [Firestore] mixin implementing in-memory fan-out of document/query change
/// notifications, used by backends without native push notifications.
///
/// Implementers register interest through [addDocumentSubscription] /
/// [addCollectionSubscription] (typically from a [DocumentReference] or
/// [Query] `onSnapshot` implementation) and call [notify] after every write
/// to broadcast the resulting change to matching subscriptions.
mixin FirestoreSubscriptionMixin on Firestore {
  /// Closes every active subscription and its stream, for example when
  /// tearing down the [Firestore] instance in tests.
  Future closeSubscriptions() async {
    for (var subscription in subscriptions.values.toList()) {
      await _clearSubscription(subscription);
    }
  }

  /// The active subscriptions, keyed by document/collection path.
  final subscriptions = <String?, FirestoreSubscription>{};

  /// Returns the existing subscription registered for [path], or `null` if
  /// none is active.
  FirestoreSubscription<T?>? findSubscription<T>(String? path) {
    return subscriptions[path] as FirestoreSubscription<T?>?;
  }

  /// Registers interest in changes to the collection at [path], creating a
  /// new [CollectionSubscription] on first call and incrementing its
  /// reference count on subsequent calls.
  ///
  /// Pair every call with [removeSubscription] once the listener is done.
  CollectionSubscription addCollectionSubscription(String path) {
    return _addSubscription(path, () => CollectionSubscription())
        as CollectionSubscription;
  }

  /// Registers interest in changes to the document at [path], creating a
  /// new [DocumentSubscription] on first call and incrementing its
  /// reference count on subsequent calls.
  ///
  /// Pair every call with [removeSubscription] once the listener is done.
  DocumentSubscription addDocumentSubscription(String? path) {
    return _addSubscription(path, () => DocumentSubscription())
        as DocumentSubscription;
  }

  FirestoreSubscription<T> _addSubscription<T>(
    String? path,
    FirestoreSubscription<T> Function() create,
  ) {
    var subscription = findSubscription<T>(path);
    if (subscription == null) {
      subscription = create()..path = path;
      subscriptions[path] = subscription;
    }
    subscription.count++;
    return subscription as FirestoreSubscription<T>;
  }

  /// Decrements [subscription]'s reference count, closing and removing it
  /// once the count reaches zero (no listener left).
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

  /// Returns a defensive copy of [documentSnapshot], safe to hand out to a
  /// listener independently from the copy retained internally.
  DocumentSnapshot cloneSnapshot(DocumentSnapshot documentSnapshot);

  /// Builds a non-existent [DocumentSnapshot] for [documentReference], used
  /// to notify listeners that the document was deleted.
  DocumentSnapshot deletedSnapshot(DocumentReference documentReference);

  /// Builds a [DocumentChangeBase] of the given [type] for [document], with
  /// [newIndex]/[oldIndex] set as per [DocumentChange.newIndex]/
  /// [DocumentChange.oldIndex].
  DocumentChangeBase documentChange(
    DocumentChangeType type,
    DocumentSnapshot document,
    int newIndex,
    int oldIndex,
  );

  /// Broadcasts [result] (the outcome of a write) to any document
  /// subscription on the affected path and any collection subscription on
  /// its parent path.
  ///
  /// Does nothing if [WriteResultBase.shouldNotify] is `false` (write had no
  /// visible effect, e.g. deleting an already-absent document).
  void notify(WriteResultBase result) {
    if (!result.shouldNotify) {
      return;
    }
    var path = result.path;
    var documentSubscription = findSubscription<Object?>(path);
    var newSnapshot = result.newSnapshot;
    var previousSnapshot = result.previousSnapshot;
    var added = result.added;
    var removed = result.removed;
    var modified = result.modified;
    assert(added || removed || modified);
    if (documentSubscription != null) {
      if (added || modified) {
        documentSubscription.streamController.add(cloneSnapshot(newSnapshot!));
      } else {
        // this is a delete
        documentSubscription.streamController.add(deletedSnapshot(doc(path)));
      }
    }
    // notify collection listeners
    var collectionSubscription = findSubscription<Object?>(url.dirname(path));
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
        -1,
      );
      collectionSubscription.streamController.add(change);
    }
  }

  /// Returns a stream of [DocumentSnapshot]s for [documentRef], suitable
  /// for implementing [DocumentReference.onSnapshot].
  ///
  /// An initial event with the document's current content is fetched and
  /// sent immediately, and further events are sent whenever [notify] is
  /// called for a write to [documentRef]. Closing the returned stream's
  /// subscription automatically releases the underlying subscription.
  Stream<DocumentSnapshot> onSnapshot(DocumentReference documentRef) {
    var subscription = addDocumentSubscription(documentRef.path);
    late StreamSubscription querySubscription;
    var controller = StreamController<DocumentSnapshot>(
      onCancel: () {
        querySubscription.cancel();
      },
    );

    querySubscription = subscription.streamController.stream.listen(
      (DocumentSnapshot snapshot) async {
        controller.add(snapshot);
      },
      onDone: () {
        removeSubscription(subscription);
      },
    );

    // Get the first batch
    documentRef.get().then((DocumentSnapshot snapshot) {
      controller.add(snapshot);
    });
    return controller.stream;
  }
}

/// Returns `true` if [documentData] satisfies the single filter [where],
/// used by in-memory query execution (see [FirestoreQueryMixin]) to decide
/// whether a document matches a `where` clause.
bool mapWhere(DocumentData? documentData, WhereInfo where) {
  // We always use Timestamp even for DateTime
  FirestoreComparable? makeComparableValue(dynamic value) {
    return _getComparable(value);
  }

  var rawValue = documentDataMap(
    documentData,
  )!.valueAtFieldPath(where.fieldPath);
  var comparableFieldValue = makeComparableValue(rawValue);

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
    var equalsToValue = makeComparableValue(where.isEqualTo);
    return (comparableFieldValue.compareTo(equalsToValue) == 0);
  } else if (where.isGreaterThan != null) {
    if (!isFieldValueComparable()) {
      return false;
    }
    return (comparableFieldValue!.compareTo(
          makeComparableValue(where.isGreaterThan),
        ) >
        0);
  } else if (where.isGreaterThanOrEqualTo != null) {
    if (!isFieldValueComparable()) {
      return false;
    }
    return (comparableFieldValue!.compareTo(
          makeComparableValue(where.isGreaterThanOrEqualTo),
        ) >=
        0);
  } else if (where.isLessThan != null) {
    if (!isFieldValueComparable()) {
      return false;
    }
    return (comparableFieldValue!.compareTo(
          makeComparableValue(where.isLessThan),
        ) <
        0);
  } else if (where.isLessThanOrEqualTo != null) {
    if (!isFieldValueComparable()) {
      return false;
    }
    return (comparableFieldValue!.compareTo(
          makeComparableValue(where.isLessThanOrEqualTo),
        ) <=
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

/// Returns the element of [list] at [index], or `null` if [list] is `null`
/// or too short to contain that index (does not throw a range error).
T? safeGetItem<T>(List<T>? list, int index) {
  if (list != null && list.length > index) {
    return list[index];
  }
  return null;
}

int _typeOrderIndex(Object object) {
  var index = 0;
  if (object is bool) {
    return index;
  }
  index++;
  if (object is num) {
    return index;
  }
  index++;
  if (object is Timestamp) {
    return index;
  }
  index++;
  if (object is String) {
    return index;
  }
  index++;
  if (object is Blob) {
    return index;
  }
  index++;
  if (object is DocumentReference) {
    return index;
  }
  index++;
  if (object is GeoPoint) {
    return index;
  }
  index++;
  if (object is List) {
    return index;
  }
  index++;
  if (object is Map) {
    return index;
  }
  index++;

  return index;
}

int _rawCompareType(Object object1, Object object2) {
  var typeOrderIndex1 = _typeOrderIndex(object1);
  var typeOrderIndex2 = _typeOrderIndex(object2);
  return typeOrderIndex1.compareTo(typeOrderIndex2);
}

/// Wraps a document field value for ordering/comparison purposes, following
/// Firestore's cross-type value ordering (booleans, then numbers, then
/// timestamps, then strings, then blobs, then references, then geo points,
/// then arrays, then maps).
///
/// Values that don't implement [Comparable] (currently only [bool]) are
/// stored in [nonComparable] instead and compared for equality only. Build
/// one through the private `_getComparable` helper used throughout this
/// library rather than directly.
class FirestoreComparable {
  /// The value wrapped as a [Comparable], or `null` if the wrapped value
  /// does not implement [Comparable] (see [nonComparable]).
  final Comparable? comparable;

  /// The wrapped value when it does not implement [Comparable] (currently
  /// only [bool] values), or `null` when [comparable] is set instead.
  final Object? nonComparable;

  int get _boolComparable =>
      (nonComparable as bool) ? 1 : 0; // if nonComparable is bool only
  /// The wrapped value regardless of whether it is [comparable] or
  /// [nonComparable].
  Object? get anyComparable => comparable ?? nonComparable;

  /// Creates a [FirestoreComparable] wrapping either [comparable] or, if
  /// the value doesn't implement [Comparable], [nonComparable].
  FirestoreComparable(this.comparable, [this.nonComparable]);

  /// `true` if this value implements [Comparable] (i.e. [comparable] is
  /// non-`null`) and thus supports ordering (not just equality) comparisons.
  bool get isComparable => comparable != null;

  /// Compares this value to [other] following Firestore's cross-type value
  /// ordering. Returns a negative number, zero or a positive number as per
  /// [Comparable.compareTo]; a `null` [other] sorts after this value.
  /// Returns `-9999` (a deliberately recognizable sentinel) if comparison
  /// fails unexpectedly, so it can be easily spotted while debugging.
  int compareTo(FirestoreComparable? other) {
    try {
      if (other == null) {
        return -1;
      }
      // Handle types first
      var anyComparable1 = anyComparable;
      var anyComparable2 = other.anyComparable;
      if (anyComparable1 != null && anyComparable2 != null) {
        var cmp = _rawCompareType(anyComparable1, anyComparable2);
        if (cmp != 0) {
          return cmp;
        }
      }
      if (comparable != null) {
        return comparable!.compareTo(other.comparable);
      } else if (other.comparable != null) {
        return -1;
      } else {
        if (nonComparable is bool && other.nonComparable is bool) {
          return _boolComparable.compareTo(other._boolComparable);
        }
        return (nonComparable == other.nonComparable) ? 0 : -1;
      }
    } catch (_) {
      // Dummy for easy spotting
      return -9999;
    }
  }

  /// Compares [a] to [b] via [compareTo]; a `null` [a] sorts before [b]
  /// (returns `-1`), regardless of whether [b] is `null`.
  static int compare(FirestoreComparable? a, FirestoreComparable? b) =>
      a?.compareTo(b) ?? -1;

  @override
  String toString() => 'FirestoreComparable($comparable, $nonComparable)';
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

/// A read-only [List] view that also implements [Comparable], comparing
/// element by element (via [FirestoreComparable]) and, if all shared
/// elements are equal, by length. Used to order document array fields.
class ComparableList<E> with ListMixin<E> implements Comparable<List<E>?> {
  final List<E> _list;

  /// Creates a [ComparableList] wrapping [_list].
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

/// A read-only [Map] view that also implements [Comparable], comparing by
/// sorted keys and then values (via [FirestoreComparable]), and finally by
/// size. Used to order document map fields.
class ComparableMap<K, V>
    with MapMixin<K, V>
    implements Comparable<Map<K, V>?> {
  final Map<K, V> _map;

  /// Creates a [ComparableMap] wrapping [_map].
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

  /// Keys.
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

int _rawCompareHandleNull(
  FirestoreComparable? object1,
  FirestoreComparable? object2,
) {
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
  FirestoreComparable? object1,
  FirestoreComparable? object2, [
  bool ascending = true,
]) {
  final compareValue = _rawCompareHandleNull(object1, object2);
  if (ascending) {
    return compareValue;
  } else {
    return -compareValue;
  }
}

/// Returns `true` if [snapshot] matches every aspect of [queryInfo]: all
/// `where` filters (via [mapWhere]), non-null `orderBy` fields, and any
/// `startAt`/`startAfter`/`endAt`/`endBefore` cursor bound.
///
/// Used by in-memory query execution (see [FirestoreQueryMixin]) to filter
/// the full set of documents down to those actually matching the query.
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

  // Map end/start
  var startLimit = queryInfo.startLimit;
  if (startLimit != null) {
    var cmp = queryCompareSnapshotToLimit(queryInfo, snapshot, startLimit);
    if (cmp < 0) {
      return false;
    } else if (cmp == 0 && !startLimit.inclusive) {
      return false;
    }
  }

  var endLimit = queryInfo.endLimit;
  if (endLimit != null) {
    var cmp = queryCompareSnapshotToLimit(queryInfo, snapshot, endLimit);
    if (cmp > 0) {
      return false;
    } else if (cmp == 0 && !endLimit.inclusive) {
      return false;
    }
  }
  return true;
}

/// Convenience base class for a [FirestorePathReference] implementation,
/// initializing its `firestore`/`path` pair at construction time.
abstract class FirestoreReferenceBase
    with PathReferenceImplMixin, PathReferenceMixin {
  /// Creates a [FirestoreReferenceBase] bound to [firestore] at [path].
  FirestoreReferenceBase(Firestore firestore, String path) {
    init(firestore, path);
  }
}

/// [Query] mixin that executes queries entirely in memory: it filters,
/// sorts, paginates and projects the documents returned by
/// [getCollectionDocuments] according to [queryInfo], instead of delegating
/// to a native/remote query engine.
///
/// Used by backends (such as in-memory or local-database-backed mocks) that
/// have no query engine of their own. The [firestore] instance must also mix
/// in [FirestoreDocumentsMixin] and [FirestoreSubscriptionMixin].
mixin FirestoreQueryMixin implements Query {
  @override
  Firestore get firestore;

  /// The collection path this query runs against.
  String get path;

  /// [firestore] cast to [FirestoreDocumentsMixin], used to build result
  /// snapshots.
  FirestoreDocumentsMixin get documentsMixin =>
      firestore as FirestoreDocumentsMixin;

  /// [firestore] cast to [FirestoreSubscriptionMixin], used to implement
  /// [onSnapshot].
  FirestoreSubscriptionMixin get subscriptionMixin =>
      firestore as FirestoreSubscriptionMixin;

  /// The filters, ordering, limits and cursors to apply, or `null` for an
  /// unfiltered query over the whole collection.
  QueryInfo? get queryInfo;

  /// Returns every document currently in the collection at [path], before
  /// any [queryInfo] filtering/sorting/pagination is applied.
  Future<List<DocumentSnapshot>> getCollectionDocuments();

  /*
  // Super slow implementation
  @override
  Future<int> count() async {
    return (await get()).docs.length;
  }*/

  @override
  Future<QuerySnapshot> get() async {
    var queryInfo = this.queryInfo!;
    if (isDebug) {
      queryInfo.debugCheck();
    }
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
          OrderByInfo(fieldPath: firestoreNameFieldPath, ascending: true),
        );
      }

      for (var orderBy in orderBys) {
        final keyPath = orderBy.fieldPath!;
        final ascending = orderBy.ascending;

        int firestoreCompare(
          FirestoreComparable? object1,
          FirestoreComparable? object2,
        ) {
          return _compareHandleNull(object1, object2, ascending);
        }

        DocumentDataMap? snapshotDataMap(DocumentSnapshot snapshot) {
          return ((snapshot as DocumentSnapshotBase).documentData
              as DocumentDataMap?);
        }

        int compareAtKeyPath(String keyPath) {
          if (keyPath == firestoreNameFieldPath) {
            cmp = firestoreCompare(
              _getComparable(snapshot1.ref.path)!,
              _getComparable(snapshot2.ref.path)!,
            );
          } else {
            cmp = firestoreCompare(
              _getComparable(
                snapshotDataMap(snapshot1)!.valueAtFieldPath(keyPath),
              )!,
              _getComparable(
                snapshotDataMap(snapshot2)!.valueAtFieldPath(keyPath),
              )!,
            );
          }
          return cmp;
        }

        cmp = compareAtKeyPath(keyPath);
        if (cmp != 0) {
          break;
        }
      }
      return cmp;
    });

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
        selectedDocs.add(
          documentsMixin.newSnapshot(
            snapshot.ref,
            meta,
            DocumentData(
              toSelectedMap(data.asMap(), queryInfo.selectKeyPaths!),
            ),
          ),
        );
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
      key,
      descending == true ? orderByDescending : orderByAscending,
    );

  /// Returns a copy of this query, including a copy of [queryInfo], so that
  /// refinement methods can return a new [Query] without mutating this one.
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

  /// Appends an order-by clause on field [key] to [queryInfo], sorted
  /// ascending unless [directionStr] equals [orderByDescending].
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
  Stream<QuerySnapshot> onSnapshot({bool includeMetadataChanges = false}) {
    var collectionSubscription = subscriptionMixin.addCollectionSubscription(
      path,
    );
    late StreamSubscription querySubscription;
    var controller = StreamController<QuerySnapshot>(
      onCancel: () {
        querySubscription.cancel();
      },
    );

    querySubscription = collectionSubscription.streamController.stream.listen(
      (DocumentChange collectionDocumentChange) async {
        final documentChange = collectionDocumentChange as DocumentChangeBase;
        // get the base data
        var querySnapshot = await get() as QuerySnapshotBase;
        if (snapshotMapQueryInfo(
          documentChange.document as DocumentSnapshotBase,
          queryInfo!,
        )) {
          querySnapshot.documentChanges.add(documentChange);
        } else if (documentChange.type == DocumentChangeType.removed) {
          if (querySnapshot.contains(documentChange.documentBase)) {
            querySnapshot.documentChanges.add(documentChange);
          }
        }
        controller.add(querySnapshot);
      },
      onDone: () {
        subscriptionMixin.removeSubscription(collectionSubscription);
      },
    );

    // Get the first batch
    get().then((QuerySnapshot querySnaphost) {
      var querySnapshotBase = querySnaphost as QuerySnapshotBase;
      // set index
      var index = 0;
      for (var doc in querySnaphost.docs) {
        querySnapshotBase.documentChanges.add(
          subscriptionMixin.documentChange(
            DocumentChangeType.added,
            doc,
            index++,
            -1,
          ),
        );
      }
      controller.add(querySnapshotBase);
    });
    return controller.stream;
  }
}

/// Path-derived attributes shared by document and collection references,
/// independent of any particular [PathReference]/[FirestorePathReference]
/// interface.
abstract class ReferenceAttributes {
  /// The path of the parent location, or `null` if there is no parent (a
  /// single, root-level path segment).
  String? get parentPath;

  /// The last segment of the path.
  String get id;

  /// Joins the path with [path] into a single child path.
  String getChildPath(String path);
}

/// [ReferenceAttributes] mixin deriving [parentPath], [id] and
/// [getChildPath] from [path] alone, using `/`-based path semantics (via
/// `package:path`'s `url` style).
abstract mixin class AttributesMixin implements ReferenceAttributes {
  // FirestoreReferenceBase get baseRef;

  /// The full, slash-separated path this instance represents.
  String get path;

  @override
  String? get parentPath {
    return getParentPathOrNull(path);
  }

  @override
  String get id => url.basename(path);

  @override
  String getChildPath(String path) => url.join(this.path, path);
}
