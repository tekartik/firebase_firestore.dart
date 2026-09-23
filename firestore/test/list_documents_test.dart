import 'package:tekartik_firebase_firestore/src/common/firestore_mock.dart';
import 'package:tekartik_firebase_firestore/src/common/import_firestore_mixin.dart';
import 'package:test/test.dart';

void main() {
  var firestore = FirestoreMock();
  group('list_documents', () {
    test('firestoreListDocumentsResultFromAllRefs', () {
      var collection = firestore.collection('test');
      var refs = ['c', 'a', 'b'].map((id) => collection.doc(id)).toList();

      FirestoreListDocumentsResult list({int? pageSize, String? pageToken}) =>
          firestoreListDocumentsResultFromAllRefs(
            refs,
            FirestoreListDocumentsOptions(
              pageSize: pageSize,
              pageToken: pageToken,
            ),
          );

      // No paging, as is
      var result = firestoreListDocumentsResultFromAllRefs(refs, null);
      expect(result.refs.ids, ['c', 'a', 'b']);
      expect(result.nextPageToken, isNull);

      result = list(pageSize: 2);
      expect(result.refs.ids, ['a', 'b']);
      expect(result.nextPageToken, 'b');
      result = list(pageSize: 2, pageToken: 'b');
      expect(result.refs.ids, ['c']);
      expect(result.nextPageToken, isNull);

      result = list(pageSize: 3);
      expect(result.refs.ids, ['a', 'b', 'c']);
      expect(result.nextPageToken, isNull);

      result = list(pageToken: 'a');
      expect(result.refs.ids, ['b', 'c']);
      expect(result.nextPageToken, isNull);
    });
  });
}
