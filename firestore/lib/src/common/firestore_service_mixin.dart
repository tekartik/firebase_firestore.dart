import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';

mixin FirestoreServiceDefaultMixin implements FirestoreService {
  @override
  bool get supportsListCollections => false;
  @override
  bool get supportsDocumentSnapshotTime => false;

  @override
  bool get supportsFieldValueArray => false;

  @override
  bool get supportsQuerySelect => false;

  @override
  bool get supportsQuerySnapshotCursor => false;

  @override
  bool get supportsTimestamps => false;

  @override
  bool get supportsTimestampsInSnapshots => false;

  @override
  bool get supportsTrackChanges => false;

  @override
  bool get supportsAggregateQueries => false;
}
mixin FirestoreServiceMixin implements FirestoreService {
  /// Most implementation need a single instance, keep it in memory!
  final _instances = <App, Firestore?>{};

  T getInstance<T extends Firestore?>(App app, T Function() createIfNotFound) {
    var instance = _instances[app] as T?;
    if (instance == null) {
      instance = createIfNotFound();
      _instances[app] = instance;
    }
    return instance!;
  }
}
