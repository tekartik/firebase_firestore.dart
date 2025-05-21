import 'package:tekartik_firebase_firestore/firestore.dart';

/// Base implementation for compatible evolution
mixin SnapshotMetadataMixin implements SnapshotMetadata {
  @override
  bool get hasPendingWrites => false;

  @override
  bool get isFromCache => false;

  @override
  String toString() =>
      {
        'hasPendingWrites': hasPendingWrites,
        'isFromCache': isFromCache,
      }.toString();
}

/// Test of mixin
// ignore: unused_element
class _SnapshotMetadataMixinTest with SnapshotMetadataMixin {
  _SnapshotMetadataMixinTest();
}

/// Default implementation for SnapshotMetadata
class SnapshotMetadataDefaultImpl
    with SnapshotMetadataMixin
    implements SnapshotMetadata {
  @override
  bool get hasPendingWrites => false;

  @override
  bool get isFromCache => false;
}
