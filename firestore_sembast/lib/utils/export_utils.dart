import 'package:sembast/utils/sembast_import_export.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_firestore_sembast/src/firestore_sembast.dart';
import 'package:tekartik_firebase_firestore_sembast/src/import_firestore.dart';

export 'package:sembast/utils/sembast_import_export.dart'
    show
        exportDatabase,
        exportDatabaseLines,
        importDatabase,
        importDatabaseLines;

extension TekartikSembastUtils on Firestore {
  /// Export the database as a list of json encodable lines
  Future<List<Object>> exportLines(
      {List<CollectionReference>? collections}) async {
    if (this is FirestoreSembast) {
      if (service.supportsListCollections) {
        throw UnsupportedError('Cannot list collections');
      }
      //firestore.list
    }
    return exportDatabaseLines(await sembastDatabase);
  }
}
