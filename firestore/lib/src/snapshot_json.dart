import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/firestore_common.dart';

const _pathKey = 'path';
const _dataKey = 'data';

/// Basic document info
class FirestoreDocumentInfo {
  /// The document path
  final String path;

  /// The document data
  final DocumentData data;

  /// Constructor
  FirestoreDocumentInfo({required this.path, required this.data});

  /// Convert to a JSON-serializable map
  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      _pathKey: path,
      _dataKey: documentDataToJsonMap(data),
    };
  }

  FirestoreDocumentInfo.fromJsonMap(Map<String, Object?> map)
    : path = map[_pathKey] as String,
      data = DocumentData(
        jsonToDocumentDataValueNoFirestore(map[_dataKey] as Map)!,
      );

  FirestoreDocumentInfo.fromDocumentSnapshot(DocumentSnapshot snapshot)
    : path = snapshot.ref.path,
      data = DocumentData(snapshot.data);
}
