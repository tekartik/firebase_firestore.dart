import 'package:tekartik_firebase_firestore/src/common/import_firestore_mixin.dart';

export 'package:tekartik_firebase_firestore/src/common/reference_mixin.dart'
    show getParentPathOrNull;

/// Get parent path
String? firestorePathGetParentOrNull(String path) => getParentPathOrNull(path);

/// Get parent path (doc parent are never null)
String firestorePathGetParent(String path) =>
    firestorePathGetParentOrNull(path)!;
