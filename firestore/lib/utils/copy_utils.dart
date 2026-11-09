import 'package:tekartik_firebase_firestore/src/common/import_firestore_mixin.dart';
import 'package:tekartik_firebase_firestore/src/firestore_common.dart';

/// Copy utils extension.
extension TekartikFirestoreCopyUtils on DocumentReference {
  /// Copy documents nested too.
  Future<int> recursiveCopyTo(
    Firestore dstFirestore,
    DocumentReference dstRef, {
    int? batchSize,
  }) async {
    return await _recursiveCopyDocument(
      this,
      dstFirestore,
      dstRef,
      batchSize: batchSize,
    );
  }

  /// Nested deleted
  Future<int> recursiveDelete(Firestore firestore, {int? batchSize}) async {
    return await _recursiveDocDelete(firestore, this, batchSize: batchSize);
  }

  /// Recursive list documents.
  Future<List<DocumentReference>> recursiveListDocuments({
    int? pageSize,
  }) async {
    var list = <DocumentReference>[];
    if ((await get()).exists) {
      list.add(this);
    }
    return list
      ..addAll(await _recursiveDocListDocuments(this, pageSize: pageSize));
  }
}

/// Collection copy utils extension.
extension TekartikFirestoreCollectionReferenceCopyUtils on CollectionReference {
  /// Copy a document to another document
  Future<int> recursiveCopyTo(
    Firestore dstFirestore,
    CollectionReference dstRef, {
    int? batchSize,
  }) async {
    return await _recursiveCopyCollection(
      this,
      dstFirestore,
      dstRef,
      batchSize: batchSize,
    );
  }

  /// Recursive list documents.
  Future<List<DocumentReference>> recursiveListDocuments() async {
    return await _recursiveCollListDocuments(this);
  }

  /// Nested deleted
  Future<int> recursiveDelete(Firestore firestore, {int? batchSize}) async {
    return await _recursiveCollDelete(firestore, this, batchSize: batchSize);
  }
}

/// Ouch!
/// Recursive copy path.
Future<int> recursiveCopyPath(
  Firestore srcFirestore,
  String srcPath,
  Firestore dstFirestore,
  String dstPath, {
  int? batchSize,
}) async {
  var count = 0;
  var isSrcDocument = isDocumentReferencePath(srcPath);
  if (isSrcDocument) {
    checkDocumentReferencePath(dstPath);
  } else {
    checkCollectionReferencePath(dstPath);
  }
  return count;
}

/// The "missing" documents of [collection] (no data, but sub-collections:
/// a query does not return them) not in [visitedIds], when the service can
/// list them, so that their sub-collections are visited too.
Future<List<DocumentReference>> _collectionMissingDocuments(
  CollectionReference collection,
  Set<String> visitedIds, {
  required int pageSize,
}) async {
  if (!collection.firestore.service.supportsListMissingDocuments) {
    return const [];
  }
  var refs = <DocumentReference>[];
  var pageTokens = <String>{};
  String? pageToken;
  do {
    var result = await collection.listDocuments(
      options: FirestoreListDocumentsOptions(
        pageSize: pageSize,
        pageToken: pageToken,
      ),
    );
    refs.addAll(result.refs.where((ref) => !visitedIds.contains(ref.id)));
    pageToken = result.nextPageToken;
    // Never loop on a page token already used.
  } while (pageToken != null && pageTokens.add(pageToken));
  return refs;
}

Future<int> _recursiveCopyCollection(
  CollectionReference srcRef,
  Firestore dstFirestore,
  CollectionReference dstRef, {
  int? batchSize,
}) async {
  var count = 0;
  var query = srcRef.orderBy(firestoreNameFieldPath);
  batchSize ??= 10;
  var visitedIds = <String>{};

  int snapshotSize;
  do {
    var snapshot = await query.limit(batchSize).get();
    snapshotSize = snapshot.docs.length;

    // When there are no documents left, we are done
    if (snapshotSize == 0) {
      break;
    }

    // Delete documents in a batch
    for (var doc in snapshot.docs) {
      visitedIds.add(doc.ref.id);
      count += await _recursiveCopyDocument(
        doc.ref,
        dstFirestore,
        dstRef.doc(doc.ref.id),
        batchSize: batchSize,
      );
    }

    query = query.startAfter(values: [snapshot.docs.last.ref.id]);
  } while (snapshotSize >= batchSize);
  for (var missingRef in await _collectionMissingDocuments(
    srcRef,
    visitedIds,
    pageSize: batchSize,
  )) {
    count += await _recursiveCopyDocument(
      missingRef,
      dstFirestore,
      dstRef.doc(missingRef.id),
      batchSize: batchSize,
    );
  }
  return count;
}

Future<List<DocumentReference>> _recursiveCollListDocuments(
  CollectionReference srcRef, {
  int? pageSize,
}) async {
  var list = <DocumentReference>[];

  var query = srcRef.orderBy(firestoreNameFieldPath);
  pageSize ??= 10;
  var visitedIds = <String>{};

  int snapshotSize;
  do {
    var snapshot = await query.limit(pageSize).get();
    snapshotSize = snapshot.docs.length;

    // When there are no documents left, we are done
    if (snapshotSize == 0) {
      break;
    }

    // Delete documents in a batch
    for (var doc in snapshot.docs) {
      list.add(doc.ref);
      visitedIds.add(doc.ref.id);
      list.addAll(
        await _recursiveDocListDocuments(doc.ref, pageSize: pageSize),
      );
    }

    query = query.startAfter(values: [snapshot.docs.last.ref.id]);
  } while (snapshotSize >= pageSize);
  for (var missingRef in await _collectionMissingDocuments(
    srcRef,
    visitedIds,
    pageSize: pageSize,
  )) {
    list.addAll(
      await _recursiveDocListDocuments(missingRef, pageSize: pageSize),
    );
  }
  return list;
}

Future<int> _recursiveCollDelete(
  Firestore firestore,
  CollectionReference ref, {
  int? batchSize,
}) async {
  var count = 0;
  var query = ref.orderBy(firestoreNameFieldPath);
  batchSize ??= 10;
  var visitedIds = <String>{};

  int snapshotSize;
  do {
    var snapshot = await query.limit(batchSize).get();
    snapshotSize = snapshot.docs.length;

    // When there are no documents left, we are done
    if (snapshotSize == 0) {
      break;
    }

    // Delete documents in a batch
    for (var doc in snapshot.docs) {
      visitedIds.add(doc.ref.id);
      count += await _recursiveDocDelete(
        firestore,
        doc.ref,
        batchSize: batchSize,
      );
    }

    query = query.startAfter(values: [snapshot.docs.last.ref.id]);
  } while (snapshotSize >= batchSize);
  for (var missingRef in await _collectionMissingDocuments(
    ref,
    visitedIds,
    pageSize: batchSize,
  )) {
    count += await _recursiveDocDelete(
      firestore,
      missingRef,
      batchSize: batchSize,
    );
  }
  return count;
}

Future<int> _recursiveCopyDocument(
  DocumentReference srcRef,
  Firestore dstFirestore,
  DocumentReference dstRef, {
  int? batchSize,
}) async {
  var count = 0;
  var collections = await srcRef.listCollections();
  for (var collection in collections) {
    count += await _recursiveCopyCollection(
      collection,
      dstFirestore,
      dstRef.collection(collection.id),
      batchSize: batchSize,
    );
  }
  count += await _copyDocument(
    srcRef,
    dstFirestore,
    dstRef,
    batchSize: batchSize,
  );
  return count;
}

Future<int> _recursiveDocDelete(
  Firestore firestore,
  DocumentReference ref, {
  int? batchSize,
}) async {
  var count = 0;
  var collections = await ref.listCollections();
  for (var collection in collections) {
    count += await _recursiveCollDelete(
      firestore,
      collection,
      batchSize: batchSize,
    );
  }

  count += await _deleteDocument(firestore, ref, batchSize: batchSize);
  return count;
}

Future<List<DocumentReference>> _recursiveDocListDocuments(
  DocumentReference srcRef, {
  int? pageSize,
}) async {
  var collections = await srcRef.listCollections();
  var list = <DocumentReference>[];
  for (var collection in collections) {
    list.addAll(
      await _recursiveCollListDocuments(collection, pageSize: pageSize),
    );
  }

  return list;
}

Future<int> _copyDocument(
  DocumentReference srcRef,
  Firestore dstFirestore,
  DocumentReference dstRef, {
  int? batchSize,
}) async {
  var count = 0;
  var snapshot = await srcRef.get();
  if (snapshot.exists) {
    await dstRef.set(snapshot.data);
    count++;
  }
  return count;
}

Future<int> _deleteDocument(
  Firestore firestore,
  DocumentReference ref, {
  int? batchSize,
}) async {
  var count = 0;
  var snapshot = await ref.get();
  if (snapshot.exists) {
    await ref.delete();
    count++;
  }
  return count;
}
