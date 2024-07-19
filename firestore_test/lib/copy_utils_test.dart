// ignore_for_file: inference_failure_on_collection_literal

import 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/copy_utils.dart';

import 'firestore_test.dart';

void runCopyUtilsTest(
    {required Firestore firestore,
    required FirestoreTestContext? testContext}) {
  var testsRefPath = FirestoreTestContext.getRootCollectionPath(testContext);
  group('copy utils collections', () {
    // firestore = firestore.debugQuickLoggerWrapper();

    test('copy/list documents with parent', () async {
      var parent = url.join(testsRefPath, 'tekartik_test_recursive_documents');
      var parentDest =
          url.join(testsRefPath, 'tekartik_test_recursive_documents_dst');
      var parentDoc = firestore.doc(parent);
      await parentDoc.recursiveDelete(firestore);
      await firestore.doc(parentDest).recursiveDelete(firestore);
      var doc1 = firestore.doc('$parent/sub/doc');
      await doc1.set({});
      var doc2 = doc1.collection('c1').doc('d2');
      await doc2.set({});
      var collection = doc1.parent;
      expect((await collection.recursiveListDocuments()).map((e) => e.path),
          [doc1.path, doc2.path]);

      var dstDocument = firestore.doc(parentDest);
      expect(await parentDoc.recursiveCopyTo(firestore, dstDocument), 2);
      expect((await parentDoc.recursiveListDocuments()).map((e) => e.path),
          [doc1.path, doc2.path]);
      expect(await parentDoc.recursiveDelete(firestore), 2);
      expect((await parentDoc.recursiveListDocuments()).map((e) => e.path),
          isEmpty);
      /*
      await doc1.delete();
      await doc2.delete();

       */
      expect((await collection.recursiveListDocuments()).map((e) => e.path),
          isEmpty);
    }, skip: !firestore.service.supportsListCollections);

    test('copy/list documents no parent (weird)', () async {
      var parent = url.join(testsRefPath, 'tekartik_test_recursive_documents');

      var doc1 = firestore.doc('$parent/sub/doc');
      await doc1.set({});
      var doc2 = doc1.collection('c1').doc('d2').collection('c3').doc('d3');
      await doc2.set({});
      var collection = doc1.parent;
      expect((await collection.recursiveListDocuments()).map((e) => e.path), [
        doc1.path,
        // Missing? bug or feature?
        //doc2.path
      ]);

      await doc1.delete();
      await doc2.delete();
      expect((await collection.recursiveListDocuments()).map((e) => e.path),
          isEmpty);
    }, skip: !firestore.service.supportsListCollections);
  });
}
