import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/firestore_common.dart';

/// Base [DocumentSnapshot] mixin providing `UnimplementedError` defaults for
/// every member.
///
/// Concrete backends mix this in and override only the members they support,
/// so that adding a new member to [DocumentSnapshot] later does not break
/// existing implementations at compile time.
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
