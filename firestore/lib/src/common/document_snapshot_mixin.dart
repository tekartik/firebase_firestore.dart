import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/firestore_common.dart';

import 'snapshot_meta_data_mixin.dart';

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
  SnapshotMetadata get metadata =>
      exists ? snapshotMetadataDefaultImpl : throw UnimplementedError();
}

/// Test of mixin
// ignore: unused_element
class _DocumentSnapshotMixinTest extends DocumentSnapshotBase {
  _DocumentSnapshotMixinTest(super.ref, super.meta, super.documentData);
}
