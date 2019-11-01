import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_rest/src/document_rest_impl.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart';
import 'package:tekartik_firebase_firestore_rest/src/import.dart';
import 'package:tekartik_firebase_firestore_rest/src/patch_document_rest_impl.dart';
import 'package:tekartik_firebase_firestore_rest/src/read_document_rest_impl.dart';
import 'package:test/test.dart';

class FirestoreDocumentContextMock implements FirestoreDocumentContext {
  @override
  String getDocumentName(String path) => path;

  @override
  String getDocumentPath(String name) => name;

  @override
  FirestoreRestImpl get impl => null;
}

final FirestoreDocumentContextMock firestoreMock =
    FirestoreDocumentContextMock();

Future main() async {
  group('document', () {
    test('patch', () {
      var patchDocument = PatchDocument(firestoreMock, null);
      expect(patchDocument.fields, null);
      patchDocument = PatchDocument(firestoreMock, {});
      expect(patchDocument.fields, {});
      var data = {'test': 1};
      patchDocument = PatchDocument(firestoreMock, {'test': 1});
      var readDocument = ReadDocument(firestoreMock, patchDocument.document);
      expect(patchDocument.fields['test'].integerValue, "1");
      expect(readDocument.data, data);
    });
    test('patchDelete', () {
      var patchDocument =
          PatchDocument(firestoreMock, {'test': FieldValue.delete});
      expect(patchDocument.fields, {});
      expect(patchDocument.fieldPaths, ['test']);

      patchDocument = PatchDocument(firestoreMock, {'test2': 1});
      expect(patchDocument.fields['test2'].integerValue, "1");
      expect(patchDocument.fields.keys, ['test2']);
      expect(patchDocument.fieldPaths, isNull);

      patchDocument =
          PatchDocument(firestoreMock, {'test': FieldValue.delete, 'test2': 1});
      expect(patchDocument.fields['test2'].integerValue, "1");
      expect(patchDocument.fieldPaths, ['test', 'test2']);
    });

    test('subField', () {
      var patchDocument = PatchDocument(firestoreMock, {'test.sub': 1});
      expect(patchDocument.fields['test.sub'].integerValue, "1");
      expect(patchDocument.fieldPaths, ['test.sub']);
    });
  });
}
