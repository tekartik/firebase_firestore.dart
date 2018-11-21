// Delete entire collection
// <https://firebase.google.com/docs/firestore/manage-data/delete-data#collections>
import 'package:tekartik_firebase_firestore/firestore.dart';

Future deleteCollection(Firestore firestore, CollectionReference collectionRef,
    {int batchSize}) async {
  batchSize ??= 4;
  var query = collectionRef.orderBy(firestoreNameFieldPath).limit(batchSize);

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
  } while (snapshotSize > batchSize);
}
