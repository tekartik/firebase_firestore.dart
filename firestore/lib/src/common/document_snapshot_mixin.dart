import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/firestore_common.dart';

/// Base implementation for compatible evolution
mixin DocumentSnapshotMixin implements DocumentSnapshot {
  @override
  Timestamp? get createTime => throw UnimplementedError();

  @override
  Map<String, Object?> get data => throw UnimplementedError();

  @override
  bool get exists => throw UnimplementedError();

  @override
  DocumentReference get ref => throw UnimplementedError();

  @override
  Timestamp? get updateTime => throw UnimplementedError();

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  String toString() {
    return 'DocumentSnapshot(ref: $ref, exists: $exists)';
  }
}

/// Test of mixin
// ignore: unused_element
class _DocumentSnapshotMixinTest extends DocumentSnapshotBase {
  _DocumentSnapshotMixinTest(super.ref, super.meta, super.documentData);
}
