import 'package:sembast/utils/sembast_import_export.dart';
import 'package:tekartik_firebase_firestore/utils/copy_utils.dart';
import 'package:tekartik_firebase_firestore_sembast/firestore_sembast.dart';
import 'package:tekartik_firebase_firestore_sembast/src/firestore_sembast.dart';

export 'package:sembast/utils/sembast_import_export.dart'
    show
        exportDatabase,
        exportDatabaseLines,
        importDatabase,
        importDatabaseLines;

extension TekartikSembastUtils on Firestore {
  /// Export the database as a list of json encodable lines
  Future<List<Object>> exportLines(
      {List<CollectionReference>? collections,
      List<DocumentReference>? documents}) async {
    if (this is! FirestoreSembast) {
      if (!service.supportsListCollections) {
        throw UnsupportedError('Cannot list collections');
      }
      var firestore = newFirestoreMemory();
      if (collections != null || documents == null) {
        collections ??= await firestore.listCollections();
        for (var collection in collections) {
          await collection.recursiveCopyTo(
              firestore, firestore.collection(collection.path));
        }
      }
      if (documents != null) {
        for (var doc in documents) {
          await doc.recursiveCopyTo(firestore, firestore.doc(doc.path));
        }
      }
      return firestore.exportLines(
          collections:
              collections?.map((e) => firestore.collection(e.path)).toList(),
          documents: documents?.map((e) => firestore.doc(e.path)).toList());
    }
    return exportDatabaseLines(await sembastDatabase);
  }
}
