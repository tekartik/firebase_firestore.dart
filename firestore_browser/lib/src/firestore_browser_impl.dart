import 'dart:async';

import 'package:firebase/firestore.dart' as native;
import 'package:js/js_util.dart';
import 'package:tekartik_browser_utils/browser_utils_import.dart' hide Blob;
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_browser/src/common/firebase_js_version.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_browser/src/firebase_browser.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/firestore_service_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore/src/common/reference_mixin.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore/src/firestore.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore/utils/firestore_mixin.dart'; // ignore: implementation_imports

JavascriptScriptLoader firestoreJsLoader = JavascriptScriptLoader(
    'https://www.gstatic.com/firebasejs/$firebaseJsVersion/firebase-firestore.js');

// Put js in HTML instead
@deprecated
Future loadFirebaseFirestoreJs() async {
  await firestoreJsLoader.load();
}

class FirestoreServiceBrowser
    with FirestoreServiceMixin
    implements FirestoreService {
  @override
  Firestore firestore(App app) {
    return getInstance(app, () {
      assert(app is AppBrowser, 'invalid firebase app type');
      final appBrowser = app as AppBrowser;
      return FirestoreBrowser(appBrowser.nativeApp.firestore());
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

class FirestoreBrowser implements Firestore {
  final native.Firestore nativeInstance;

  FirestoreBrowser(this.nativeInstance);

  @override
  CollectionReference collection(String path) =>
      _wrapCollectionReference(nativeInstance.collection(path));

  @override
  DocumentReference doc(String path) =>
      _wrapDocumentReference(nativeInstance.doc(path));

  @override
  WriteBatch batch() {
    var nativeBatch = nativeInstance.batch();
    return WriteBatchBrowser(nativeBatch);
  }

  @override
  Future<T> runTransaction<T>(
      FutureOr<T> Function(Transaction transaction) updateFunction) async {
    return await nativeInstance.runTransaction((nativeTransaction) {
      var transaction = TransactionBrowser(nativeTransaction);
      return updateFunction(transaction);
    }) as T;
  }

  @override
  void settings(FirestoreSettings settings) {
    nativeInstance.settings(_unwrapSettings(settings)!);
  }

  @override
  Future<List<DocumentSnapshot>> getAll(List<DocumentReference> refs) async {
    return await Future.wait(refs.map((ref) => ref.get()));
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
  final native.Transaction nativeInstance;

  TransactionBrowser(this.nativeInstance);

  @override
  void delete(DocumentReference documentRef) {
    nativeInstance.delete(_unwrapDocumentReference(documentRef)!);
  }

  @override
  Future<DocumentSnapshot> get(DocumentReference documentRef) async =>
      _wrapDocumentSnapshot(
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
    native.CollectionReference nativeCollectionReference) {
  return CollectionReferenceBrowser(nativeCollectionReference);
}

DocumentReferenceBrowser _wrapDocumentReference(
    native.DocumentReference nativeDocumentReference) {
  return DocumentReferenceBrowser(nativeDocumentReference);
}

// for both native and not
bool isCommonValue(Object? value) {
  return (value == null ||
      value is String ||
      // value is DateTime ||
      value is num ||
      value is bool);
}

Object? fromNativeValue(Object? nativeValue) {
  if (isCommonValue(nativeValue)) {
    return nativeValue;
  }
  if (nativeValue is Iterable) {
    return nativeValue
        .map((nativeValue) => fromNativeValue(nativeValue))
        .toList();
  } else if (nativeValue is Map) {
    return nativeValue.map<String, Object?>((key, nativeValue) =>
        MapEntry(key as String, fromNativeValue(nativeValue)));
  } else if (native.FieldValue.delete() == nativeValue) {
    return FieldValue.delete;
  } else if (native.FieldValue.serverTimestamp() == nativeValue) {
    return FieldValue.serverTimestamp;
  } else if (nativeValue is native.DocumentReference) {
    return DocumentReferenceBrowser(nativeValue);
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
    return hasProperty(proto, 'toBase64') == true &&
        hasProperty(proto, 'toUint8Array') == true;
  }
  return false;
}

bool _isNativeGeoPoint(Object native) {
  //  [latitude, longitude, isEqual, n]
  // devPrint('value ${objectKeys(getProperty(native, '__proto__'))}');
  var proto = getProperty(native, '__proto__') as Object?;
  if (proto != null) {
    return hasProperty(proto, 'latitude') == true &&
        hasProperty(proto, 'longitude') == true;
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

DocumentData documentDataFromNativeMap(Map<String, Object?> nativeMap) {
  var map = fromNativeValue(nativeMap) as Map<String, Object?>;
  return DocumentData(map);
}

class DocumentSnapshotBrowser implements DocumentSnapshot {
  final native.DocumentSnapshot _native;

  DocumentSnapshotBrowser(this._native);

  @override
  Map<String, Object?> get data =>
      documentDataFromNativeMap(_native.data()).asMap();

  @override
  bool get exists => _native.exists;

  @override
  DocumentReference get ref => _wrapDocumentReference(_native.ref);

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
    with PathReferenceMixin
    implements DocumentReference, PathReference {
  final native.DocumentReference nativeInstance;

  DocumentReferenceBrowser(this.nativeInstance);

  @override
  CollectionReference collection(String path) =>
      _wrapCollectionReference(nativeInstance.collection(path));

  @override
  Future delete() => nativeInstance.delete();

  @override
  Future<DocumentSnapshot> get() async =>
      _wrapDocumentSnapshot(await nativeInstance.get());

  @override
  String get id => nativeInstance.id;

  @override
  CollectionReference get parent =>
      _wrapCollectionReference(nativeInstance.parent);

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
  Stream<DocumentSnapshot> onSnapshot() {
    var transformer = StreamTransformer.fromHandlers(handleData:
        (native.DocumentSnapshot nativeDocumentSnapshot,
            EventSink<DocumentSnapshot> sink) {
      sink.add(_wrapDocumentSnapshot(nativeDocumentSnapshot));
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
        native.DocumentSnapshot _native) =>
    DocumentSnapshotBrowser(_native);

native.DocumentSnapshot? _unwrapDocumentSnapshot(
        DocumentSnapshot? documentSnapshot) =>
    documentSnapshot != null
        ? (documentSnapshot as DocumentSnapshotBrowser)._native
        : null;

class QuerySnapshotBrowser implements QuerySnapshot {
  final native.QuerySnapshot _native;

  QuerySnapshotBrowser(this._native);

  @override
  List<DocumentSnapshot> get docs {
    var docs = <DocumentSnapshot>[];
    for (var _nativeDoc in _native.docs) {
      docs.add(_wrapDocumentSnapshot(_nativeDoc));
    }
    return docs;
  }

  @override
  List<DocumentChange> get documentChanges {
    var changes = <DocumentChange>[
      for (var nativeChange in _native.docChanges())
        DocumentChangeBrowser(nativeChange)
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
  final native.DocumentChange nativeInstance;

  DocumentChangeBrowser(this.nativeInstance);

  @override
  DocumentSnapshot get document => _wrapDocumentSnapshot(nativeInstance.doc);

  @override
  int get newIndex => nativeInstance.newIndex.toInt();

  @override
  int get oldIndex => nativeInstance.oldIndex.toInt();

  @override
  DocumentChangeType get type => _wrapDocumentChangeType(nativeInstance.type)!;
}

QuerySnapshotBrowser _wrapQuerySnapshot(native.QuerySnapshot _native) =>
    QuerySnapshotBrowser(_native);

QueryBrowser _wrapQuery(native.Query native) => QueryBrowser(native);

class QueryBrowser implements Query {
  final native.Query _native;

  QueryBrowser(this._native);

  @override
  Query endAt({DocumentSnapshot? snapshot, List<Object?>? values}) =>
      _wrapQuery(_native.endAt(
          snapshot: _unwrapDocumentSnapshot(snapshot),
          fieldValues: toNativeValuesOrNull(values)));

  @override
  Query endBefore({DocumentSnapshot? snapshot, List<Object?>? values}) =>
      _wrapQuery(_native.endBefore(
          snapshot: _unwrapDocumentSnapshot(snapshot),
          fieldValues: toNativeValuesOrNull(values)));

  @override
  Future<QuerySnapshot> get() async => _wrapQuerySnapshot(await _native.get());

  @override
  Query limit(int limit) => _wrapQuery(_native.limit(limit));

  @override
  Query orderBy(String key, {bool? descending}) =>
      _wrapQuery(_native.orderBy(key, descending == true ? 'desc' : null));

  @override
  Query select(List<String> keyPaths) => this; // not supported

  @override
  Query startAfter({DocumentSnapshot? snapshot, List<Object?>? values}) =>
      _wrapQuery(_native.startAfter(
          snapshot: _unwrapDocumentSnapshot(snapshot),
          fieldValues: toNativeValuesOrNull(values)));

  @override
  Query startAt({DocumentSnapshot? snapshot, List<Object?>? values}) =>
      _wrapQuery(_native.startAt(
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
    return _wrapQuery(_native.where(fieldPath, opStr!, value));
  }

  @override
  Stream<QuerySnapshot> onSnapshot() {
    var transformer = StreamTransformer.fromHandlers(handleData:
        (native.QuerySnapshot nativeQuerySnapshot,
            EventSink<QuerySnapshot> sink) {
      sink.add(_wrapQuerySnapshot(nativeQuerySnapshot));
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
      native.CollectionReference nativeCollectionReference)
      : super(nativeCollectionReference);

  @override
  Future<DocumentReference> add(Map<String, Object?> data) async =>
      _wrapDocumentReference(await _nativeCollectionReference
          .add(documentDataToNativeMap(DocumentData(data))!));

  @override
  DocumentReference doc([String? path]) =>
      _wrapDocumentReference(_nativeCollectionReference.doc(path));

  @override
  String get id => _nativeCollectionReference.id;

  @override
  DocumentReference get parent =>
      _wrapDocumentReference(_nativeCollectionReference.parent);

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
