// Delete entire collection
// <https://firebase.google.com/docs/firestore/manage-data/delete-data#collections>
import 'dart:async';

import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/query.dart';

/// Delete all item in a collection, return the count deleted
Future<int> deleteCollection(
    Firestore firestore, CollectionReference collectionRef,
    {int? batchSize}) async {
  var query = collectionRef.orderBy(firestoreNameFieldPath);
  return await deleteQuery(firestore, query, batchSize: batchSize);
}
