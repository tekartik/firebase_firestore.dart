import 'package:tekartik_firebase_firestore/firestore.dart';

/// Firestore service mixin
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

/// Firestore service mixin
mixin FirestoreServiceMixin implements FirestoreService {}
