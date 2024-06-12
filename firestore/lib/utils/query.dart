// Delete entire collection
// <https://firebase.google.com/docs/firestore/manage-data/delete-data#collections>

import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';

/// Delete all item in a query, return the count deleted
/// Batch size default to 10
Future<int> deleteQuery(Firestore firestore, Query query,
    {int? batchSize}) async {
  batchSize ??= 10;
  var count = 0;
  var deletedPaths = <String>{};
  int snapshotSize;
  do {
    var snapshot = await query.limit(batchSize).get();
    snapshotSize = snapshot.docs.length;

    // When there are no documents left, we are done
    if (snapshotSize == 0) {
      break;
    }

    // Delete documents in a batch
    var batch = firestore.batch();
    for (var doc in snapshot.docs) {
      var ref = doc.ref;
      var path = ref.path;
      if (deletedPaths.contains(path)) {
        //devPrint('already deleted $path');
        continue;
      }
      deletedPaths.add(path);
      //devPrint('deleting $path');
      batch.delete(ref);
    }

    await batch.commit();
    count += snapshot.docs.length;
  } while (snapshotSize >= batchSize);

  return count;
}
