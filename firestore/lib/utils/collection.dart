// Delete entire collection
// <https://firebase.google.com/docs/firestore/manage-data/delete-data#collections>
import 'dart:async';

import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/query.dart';

/// Delete all items in a collection, return the count deleted
/// Keep ids in keepIds
Future<int> deleteCollection(
    Firestore firestore, CollectionReference collectionRef,
    {int? batchSize, Iterable<String>? keepIds}) async {
  var query = collectionRef.orderBy(firestoreNameFieldPath);
  return await deleteQuery(firestore, query,
      batchSize: batchSize,
      keepPaths: keepIds?.map((id) => collectionRef.doc(id).path));
}

/// Copy all items to a collection, return the count copied
Future<int> copyCollection(
    Firestore firestore,
    CollectionReference collectionRef,
    Firestore dstFirestore,
    CollectionReference dstCollectionRef,
    {int? batchSize}) async {
  var query = collectionRef.orderBy(firestoreNameFieldPath);
  batchSize ??= 10;
  var count = 0;

  int snapshotSize;
  do {
    var snapshot = await query.limit(batchSize).get();
    snapshotSize = snapshot.docs.length;

    // When there are no documents left, we are done
    if (snapshotSize == 0) {
      break;
    }

    // Delete documents in a batch
    var batch = dstFirestore.batch();
    for (var doc in snapshot.docs) {
      batch.set(dstCollectionRef.doc(doc.ref.id), doc.data);
    }

    await batch.commit();
    count += snapshot.docs.length;

    query = query.startAfter(values: [snapshot.docs.last.ref.id]);
  } while (snapshotSize >= batchSize);

  return count;
}
