import 'package:tekartik_firebase_firestore/firestore.dart';

/// Base [FirestoreService] mixin defaulting every `supportsXxx` capability
/// flag to `false`.
///
/// Concrete backends mix this in and override only the flags for features
/// they actually support, so that adding a new capability flag later
/// defaults to "unsupported" for existing implementations instead of
/// breaking them.
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
  bool get supportsRecordTrackChanges => supportsTrackChanges;

  @override
  bool get supportsAggregateQueries => false;

  @override
  /// false to start, should become true soon
  bool get supportsVectorValue => false;

  @override
  /// Mostly always true
  bool get supportsBlobs => false;
}

/// Marker mixin for [FirestoreService] implementations that do not need any
/// shared bookkeeping beyond what [FirestoreServiceDefaultMixin] and the
/// interface itself provide.
mixin FirestoreServiceMixin implements FirestoreService {}
