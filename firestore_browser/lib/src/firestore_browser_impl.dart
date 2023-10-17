import 'package:js/js_util.dart';
import 'package:tekartik_browser_utils/browser_utils_import.dart' hide Blob;

import 'import_browser.dart';
import 'import_native.dart' as native;

JavascriptScriptLoader firestoreJsLoader = JavascriptScriptLoader(
    'https://www.gstatic.com/firebasejs/$firebaseJsVersion/firebase-firestore.js');

// Put js in HTML instead
@Deprecated('Put js in HTML instead')
Future loadFirebaseFirestoreJs() async {
  await firestoreJsLoader.load();
}

class FirestoreServiceBrowser
    with FirestoreServiceDefaultMixin, FirestoreServiceMixin
    implements FirestoreService {
  @override
  Firestore firestore(App app) {
    return getInstance(app, () {
      assert(app is AppBrowser, 'invalid firebase app type');
      final appBrowser = app as AppBrowser;
      return FirestoreBrowser(this, appBrowser.nativeApp.firestore());
    });
  }

  @override
  bool get supportsQuerySelect => false;

  @override
  bool get supportsDocumentSnapshotTime => false;

  @override
  bool get supportsTimestampsInSnapshots => true; // new as of 2020/11/20

  @override
  bool get supportsTimestamps =>
      false; // Not this precision yet, maybe in the future

  @override
  bool get supportsQuerySnapshotCursor => true;

  @override
  bool get supportsFieldValueArray => true;

  @override
  bool get supportsTrackChanges => true;
}

FirestoreServiceBrowser? _firebaseFirestoreServiceBrowser;

FirestoreService get firestoreService =>
    _firebaseFirestoreServiceBrowser ??= FirestoreServiceBrowser();

class FirestoreBrowser
    with FirestoreDefaultMixin, FirestoreMixin
    implements Firestore {
  @override
  final FirestoreServiceBrowser service;
  final native.Firestore nativeInstance;

  FirestoreBrowser(this.service, this.nativeInstance);

  @override
  CollectionReference collection(String path) =>
      _wrapCollectionReference(this, nativeInstance.collection(path));

  @override
  DocumentReference doc(String path) =>
      _wrapDocumentReference(this, nativeInstance.doc(path));

  @override
  WriteBatch batch() {
    var nativeBatch = nativeInstance.batch();
    return WriteBatchBrowser(nativeBatch);
  }

  @override
  Future<T> runTransaction<T>(
      FutureOr<T> Function(Transaction transaction) updateFunction) async {
    return await nativeInstance.runTransaction((nativeTransaction) {
      var transaction = TransactionBrowser(this, nativeTransaction);
      return updateFunction(transaction);
    }) as T;
  }

  @override
  void settings(FirestoreSettings settings) {
    nativeInstance.settings(_unwrapSettings(settings)!);
  }
}

native.Settings? _unwrapSettings(FirestoreSettings settings) {
  return native.Settings();
}

class WriteBatchBrowser implements WriteBatch {
  final native.WriteBatch nativeInstance;

  WriteBatchBrowser(this.nativeInstance);

  @override
  Future commit() => nativeInstance.commit();

  @override
  void delete(DocumentReference? ref) =>
      nativeInstance.delete(_unwrapDocumentReference(ref)!);

  @override
  void set(DocumentReference ref, Map<String, Object?> data,
      [SetOptions? options]) {
    nativeInstance.set(_unwrapDocumentReference(ref)!,
        documentDataToNativeMap(DocumentData(data))!, _unwrapOptions(options));
  }

  @override
  void update(DocumentReference ref, Map<String, Object?> data) {
    nativeInstance.update(_unwrapDocumentReference(ref)!,
        data: documentDataToNativeMap(DocumentData(data)));
  }
}

class TransactionBrowser implements Transaction {
  final Firestore firestore;
  final native.Transaction nativeInstance;

  TransactionBrowser(this.firestore, this.nativeInstance);

  @override
  void delete(DocumentReference documentRef) {
    nativeInstance.delete(_unwrapDocumentReference(documentRef)!);
  }

  @override
  Future<DocumentSnapshot> get(DocumentReference documentRef) async =>
      _wrapDocumentSnapshot(firestore,
          await nativeInstance.get(_unwrapDocumentReference(documentRef)!));

  @override
  void set(DocumentReference documentRef, Map<String, Object?> data,
      [SetOptions? options]) {
    nativeInstance.set(_unwrapDocumentReference(documentRef)!,
        documentDataToNativeMap(DocumentData(data))!, _unwrapOptions(options));
  }

  @override
  void update(DocumentReference documentRef, Map<String, Object?> data) {
    nativeInstance.update(_unwrapDocumentReference(documentRef)!,
        data: documentDataToNativeMap(DocumentData(data)));
  }
}

CollectionReferenceBrowser _wrapCollectionReference(
    Firestore firestore, native.CollectionReference nativeCollectionReference) {
  return CollectionReferenceBrowser(firestore, nativeCollectionReference);
}

DocumentReferenceBrowser _wrapDocumentReference(
    Firestore firestore, native.DocumentReference nativeDocumentReference) {
  return DocumentReferenceBrowser(firestore, nativeDocumentReference);
}

// for both native and not
bool isCommonValue(Object? value) {
  return (value == null ||
      value is String ||
      // value is DateTime ||
      value is num ||
      value is bool);
}

Object? fromNativeValue(Firestore firestore, Object? nativeValue) {
  if (isCommonValue(nativeValue)) {
    return nativeValue;
  }
  if (nativeValue is Iterable) {
    return nativeValue
        .map((nativeValue) => fromNativeValue(firestore, nativeValue))
        .toList();
  } else if (nativeValue is Map) {
    return nativeValue.map<String, Object?>((key, nativeValue) =>
        MapEntry(key as String, fromNativeValue(firestore, nativeValue)));
  } else if (native.FieldValue.delete() == nativeValue) {
    return FieldValue.delete;
  } else if (native.FieldValue.serverTimestamp() == nativeValue) {
    return FieldValue.serverTimestamp;
  } else if (nativeValue is native.DocumentReference) {
    return DocumentReferenceBrowser(firestore, nativeValue);
  } else if (_isNativeBlob(nativeValue!)) {
    var nativeBlob = nativeValue as native.Blob;
    return Blob(nativeBlob.toUint8Array());
  } else if (_isNativeGeoPoint(nativeValue)) {
    var nativeGeoPoint = nativeValue as native.GeoPoint;
    return GeoPoint(nativeGeoPoint.latitude, nativeGeoPoint.longitude);
  } else if (nativeValue is DateTime) {
    // Supporting only timestamp
    return Timestamp.fromDateTime(nativeValue);
  } else {
    throw 'not supported $nativeValue type ${nativeValue.runtimeType}';
  }
}

bool _isNativeBlob(Object native) {
  // value [toBase64, toUint8Array, toString, isEqual, n]
  // devPrint('value ${objectKeys(getProperty(native, '__proto__'))}');
  var proto = getProperty(native, '__proto__') as Object?;
  if (proto != null) {
    return hasProperty(proto, 'toBase64') && hasProperty(proto, 'toUint8Array');
  }
  return false;
}

bool _isNativeGeoPoint(Object native) {
  //  [latitude, longitude, isEqual, n]
  // devPrint('value ${objectKeys(getProperty(native, '__proto__'))}');
  var proto = getProperty(native, '__proto__') as Object?;
  if (proto != null) {
    return hasProperty(proto, 'latitude') && hasProperty(proto, 'longitude');
  }
  return false;
}

List<Object?>? toNativeValuesOrNull(Iterable<Object?>? values) =>
    values == null ? null : toNativeValues(values);

List<Object?> toNativeValues(Iterable<Object?> values) =>
    values.map((value) => toNativeValue(value)).toList(growable: false);

Object? toNativeValue(Object? value) {
  if (isCommonValue(value)) {
    return value;
  } else if (value is Timestamp) {
    // Currently only DateTime are supported
    return value.toDateTime();
  } else if (value is Iterable) {
    return value.map((nativeValue) => toNativeValue(nativeValue)).toList();
  } else if (value is Map) {
    return value.map<String, Object?>(
        (key, value) => MapEntry(key as String, toNativeValue(value)));
  } else if (value is FieldValue) {
    if (FieldValue.delete == value) {
      return native.FieldValue.delete();
    } else if (FieldValue.serverTimestamp == value) {
      return native.FieldValue.serverTimestamp();
      // } else if (value.type == FieldValueType.arrayUnion) {
      //  return native.FieldValue.arrayUnion(value.data as List);
      // } else if (value.type == FieldValueType.arrayRemove) {
      //  return native.FieldValue.arrayRemove(value.data as List);
    } else if (value is FieldValueArray) {
      var type = value.type;
      if (type == FieldValueType.arrayUnion) {
        return native.FieldValue.arrayUnion(toNativeValues(value.data));
      } else if (type == FieldValueType.arrayRemove) {
        return native.FieldValue.arrayRemove(toNativeValues(value.data));
      }
    }
  } else if (value is DocumentReferenceBrowser) {
    return value.nativeInstance;
  } else if (value is Blob) {
    return native.Blob.fromUint8Array(value.data);
  } else if (value is GeoPoint) {
    return native.GeoPoint(value.latitude, value.longitude);
  } else if (value is DateTime) {
    // Currently rounded to date time
    return value;
  }

  throw 'not supported $value type ${value.runtimeType}';
}

Map<String, Object?>? documentDataToNativeMap(DocumentData documentData) {
  var map = (documentData as DocumentDataMap).map;
  return toNativeValue(map) as Map<String, Object?>?;
}

DocumentData documentDataFromNativeMap(
    Firestore firestore, Map<String, Object?> nativeMap) {
  var map = fromNativeValue(firestore, nativeMap) as Map<String, Object?>;
  return DocumentData(map);
}

class DocumentSnapshotBrowser
    with DocumentSnapshotMixin
    implements DocumentSnapshot {
  final native.DocumentSnapshot _native;

  final Firestore firestore;
  DocumentSnapshotBrowser(this.firestore, this._native);

  @override
  Map<String, Object?> get data =>
      documentDataFromNativeMap(firestore, _native.data()).asMap();

  @override
  bool get exists => _native.exists;

  @override
  DocumentReference get ref => _wrapDocumentReference(firestore, _native.ref);

  // Not supported for browser
  @override
  Timestamp? get updateTime => null;

  // Not supported for browser
  @override
  Timestamp? get createTime => null;

  dynamic get(String fieldPath) => _native.get(fieldPath);
}

native.SetOptions? _unwrapOptions(SetOptions? options) {
  native.SetOptions? nativeOptions;
  if (options != null) {
    nativeOptions = native.SetOptions(merge: options.merge == true);
  }
  return nativeOptions;
}

native.DocumentReference? _unwrapDocumentReference(DocumentReference? ref) {
  return (ref as DocumentReferenceBrowser?)?.nativeInstance;
}

class DocumentReferenceBrowser
    with DocumentReferenceDefaultMixin, PathReferenceMixin
    implements DocumentReference, PathReference {
  @override
  final Firestore firestore;
  final native.DocumentReference nativeInstance;

  DocumentReferenceBrowser(this.firestore, this.nativeInstance);

  @override
  CollectionReference collection(String path) =>
      _wrapCollectionReference(firestore, nativeInstance.collection(path));

  @override
  Future delete() => nativeInstance.delete();

  @override
  Future<DocumentSnapshot> get() async =>
      _wrapDocumentSnapshot(firestore, await nativeInstance.get());

  @override
  String get id => nativeInstance.id;

  @override
  CollectionReference get parent =>
      _wrapCollectionReference(firestore, nativeInstance.parent);

  @override
  String get path => nativeInstance.path;

  @override
  Future set(Map<String, Object?> data, [SetOptions? options]) async {
    await nativeInstance.set(
        documentDataToNativeMap(DocumentData(data))!, _unwrapOptions(options));
  }

  @override
  Future update(Map<String, Object?> data) =>
      nativeInstance.update(data: documentDataToNativeMap(DocumentData(data)));

  @override
  Stream<DocumentSnapshot> onSnapshot({bool includeMetadataChanges = false}) {
    var transformer = StreamTransformer.fromHandlers(handleData:
        (native.DocumentSnapshot nativeDocumentSnapshot,
            EventSink<DocumentSnapshot> sink) {
      sink.add(_wrapDocumentSnapshot(firestore, nativeDocumentSnapshot));
    });
    return nativeInstance.onSnapshot.transform(transformer);
  }

  @override
  int get hashCode => path.hashCode;

  @override
  bool operator ==(other) {
    if (other is DocumentReferenceBrowser) {
      if (nativeInstance.firestore != (other).nativeInstance.firestore) {
        return false;
      }
      if (path != (other).path) {
        return false;
      }
      return true;
    }
    return false;
  }
}

DocumentSnapshotBrowser _wrapDocumentSnapshot(
        final Firestore firestore, native.DocumentSnapshot snapshot) =>
    DocumentSnapshotBrowser(firestore, snapshot);

native.DocumentSnapshot? _unwrapDocumentSnapshot(
        DocumentSnapshot? documentSnapshot) =>
    documentSnapshot != null
        ? (documentSnapshot as DocumentSnapshotBrowser)._native
        : null;

class QuerySnapshotBrowser implements QuerySnapshot {
  final Firestore firestore;
  final native.QuerySnapshot _native;

  QuerySnapshotBrowser(this.firestore, this._native);

  @override
  List<DocumentSnapshot> get docs {
    var docs = <DocumentSnapshot>[];
    for (var nativeDoc in _native.docs) {
      docs.add(_wrapDocumentSnapshot(firestore, nativeDoc));
    }
    return docs;
  }

  @override
  List<DocumentChange> get documentChanges {
    var changes = <DocumentChange>[
      for (var nativeChange in _native.docChanges())
        DocumentChangeBrowser(firestore, nativeChange)
    ];
    return changes;
  }
}

DocumentChangeType? _wrapDocumentChangeType(String type) {
  // [:added:], [:removed:] or [:modified:]
  if (type == 'added') {
    return DocumentChangeType.added;
  } else if (type == 'removed') {
    return DocumentChangeType.removed;
  } else if (type == 'modified') {
    return DocumentChangeType.modified;
  }
  return null;
}

class DocumentChangeBrowser implements DocumentChange {
  final Firestore firestore;
  final native.DocumentChange nativeInstance;

  DocumentChangeBrowser(this.firestore, this.nativeInstance);

  @override
  DocumentSnapshot get document =>
      _wrapDocumentSnapshot(firestore, nativeInstance.doc);

  @override
  int get newIndex => nativeInstance.newIndex.toInt();

  @override
  int get oldIndex => nativeInstance.oldIndex.toInt();

  @override
  DocumentChangeType get type => _wrapDocumentChangeType(nativeInstance.type)!;
}

QuerySnapshotBrowser _wrapQuerySnapshot(
        Firestore firestore, native.QuerySnapshot querySnapshot) =>
    QuerySnapshotBrowser(firestore, querySnapshot);

QueryBrowser _wrapQuery(Firestore firestore, native.Query native) =>
    QueryBrowser(firestore, native);

class QueryBrowser with FirestoreQueryExecutorMixin implements Query {
  @override
  final Firestore firestore;
  final native.Query _native;

  QueryBrowser(this.firestore, this._native);

  @override
  Query endAt({DocumentSnapshot? snapshot, List<Object?>? values}) =>
      _wrapQuery(
          firestore,
          _native.endAt(
              snapshot: _unwrapDocumentSnapshot(snapshot),
              fieldValues: toNativeValuesOrNull(values)));

  @override
  Query endBefore({DocumentSnapshot? snapshot, List<Object?>? values}) =>
      _wrapQuery(
          firestore,
          _native.endBefore(
              snapshot: _unwrapDocumentSnapshot(snapshot),
              fieldValues: toNativeValuesOrNull(values)));

  @override
  Future<QuerySnapshot> get() async =>
      _wrapQuerySnapshot(firestore, await _native.get());

  @override
  Query limit(int limit) => _wrapQuery(firestore, _native.limit(limit));

  @override
  Query orderBy(String key, {bool? descending}) => _wrapQuery(
      firestore, _native.orderBy(key, descending == true ? 'desc' : null));

  @override
  Query select(List<String> keyPaths) => this; // not supported

  @override
  Query startAfter({DocumentSnapshot? snapshot, List<Object?>? values}) =>
      _wrapQuery(
          firestore,
          _native.startAfter(
              snapshot: _unwrapDocumentSnapshot(snapshot),
              fieldValues: toNativeValuesOrNull(values)));

  @override
  Query startAt({DocumentSnapshot? snapshot, List<Object?>? values}) =>
      _wrapQuery(
          firestore,
          _native.startAt(
              snapshot: _unwrapDocumentSnapshot(snapshot),
              fieldValues: toNativeValuesOrNull(values)));

  @override
  Query where(String fieldPath,
      {dynamic isEqualTo,
      dynamic isLessThan,
      dynamic isLessThanOrEqualTo,
      dynamic isGreaterThan,
      dynamic isGreaterThanOrEqualTo,
      dynamic arrayContains,
      List<Object?>? arrayContainsAny,
      List<Object?>? whereIn,
      bool? isNull}) {
    String? opStr;
    dynamic value;
    if (isEqualTo != null) {
      opStr = '==';
      value = toNativeValue(isEqualTo);
    }
    if (isLessThan != null) {
      assert(opStr == null);
      opStr = '<';
      value = toNativeValue(isLessThan);
    }
    if (isLessThanOrEqualTo != null) {
      assert(opStr == null);
      opStr = '<=';
      value = toNativeValue(isLessThanOrEqualTo);
    }
    if (isGreaterThan != null) {
      assert(opStr == null);
      opStr = '>';
      value = toNativeValue(isGreaterThan);
    }
    if (isGreaterThanOrEqualTo != null) {
      assert(opStr == null);
      opStr = '>=';
      value = toNativeValue(isGreaterThanOrEqualTo);
    }
    if (isNull != null) {
      assert(opStr == null);
      opStr = '==';
      value = null;
    }
    if (arrayContains != null) {
      assert(opStr == null);
      opStr = 'array-contains';
      value = toNativeValue(arrayContains);
    }
    if (arrayContainsAny != null) {
      assert(opStr == null);
      opStr = 'array-contains-any';
      value = toNativeValues(arrayContainsAny);
    }
    if (whereIn != null) {
      assert(opStr == null);
      opStr = 'in';
      value = toNativeValues(whereIn);
    }
    return _wrapQuery(firestore, _native.where(fieldPath, opStr!, value));
  }

  @override
  Stream<QuerySnapshot> onSnapshot({bool includeMetadataChanges = false}) {
    var transformer = StreamTransformer.fromHandlers(handleData:
        (native.QuerySnapshot nativeQuerySnapshot,
            EventSink<QuerySnapshot> sink) {
      sink.add(_wrapQuerySnapshot(firestore, nativeQuerySnapshot));
    });
    //new StreamController<QuerySnapshot>();
    return _native.onSnapshot.transform(transformer);
  }
}

class CollectionReferenceBrowser extends QueryBrowser
    implements CollectionReference {
  native.CollectionReference get _nativeCollectionReference =>
      _native as native.CollectionReference;

  CollectionReferenceBrowser(
      Firestore firestore, native.CollectionReference nativeCollectionReference)
      : super(firestore, nativeCollectionReference);

  @override
  Future<DocumentReference> add(Map<String, Object?> data) async =>
      _wrapDocumentReference(
          firestore,
          await _nativeCollectionReference
              .add(documentDataToNativeMap(DocumentData(data))!));

  @override
  DocumentReference doc([String? path]) =>
      _wrapDocumentReference(firestore, _nativeCollectionReference.doc(path));

  @override
  String get id => _nativeCollectionReference.id;

  @override
  DocumentReference get parent =>
      _wrapDocumentReference(firestore, _nativeCollectionReference.parent);

  @override
  String get path => _nativeCollectionReference.path;

  @override
  int get hashCode => path.hashCode;

  @override
  bool operator ==(other) {
    if (other is CollectionReferenceBrowser) {
      if (_nativeCollectionReference.firestore !=
          (other)._nativeCollectionReference.firestore) {
        return false;
      }
      if (path != (other).path) {
        return false;
      }
      return true;
    }
    return false;
  }
}
