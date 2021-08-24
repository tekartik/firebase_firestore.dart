// Delete entire collection
// <https://firebase.google.com/docs/firestore/manage-data/delete-data#collections>
import 'dart:async';

import 'package:tekartik_firebase_firestore/firestore.dart';

/// Delete all item in a query, return the count deleted
Future<int> deleteQuery(Firestore firestore, Query query,
    {int? batchSize}) async {
  batchSize ??= 4;
  var count = 0;

  int snapshotSize;
  do {
    var snapshot = await query.get();
    snapshotSize = snapshot.docs.length;

    // When there are no documents left, we are done
    if (snapshotSize == 0) {
      break;
    }

    // Delete documents in a batch
    var batch = firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.ref);
    }

    await batch.commit();
    count += snapshot.docs.length;
  } while (snapshotSize > batchSize);

  return count;
}
