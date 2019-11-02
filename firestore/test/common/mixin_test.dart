import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/document_reference_mixin.dart';
import 'package:tekartik_firebase_firestore/src/common/value_key_mixin.dart';
import 'package:tekartik_firebase_firestore/src/firestore_common.dart';
import 'package:tekartik_firebase_firestore/utils/firestore_mixin.dart';
import 'package:test/test.dart';

class FirestoreMock with FirestoreMixin {
  @override
  WriteBatch batch() {
    // TODO: implement batch
    return null;
  }

  @override
  CollectionReference collection(String path) {
    return CollectionReferenceMock(this, path);
  }

  @override
  DocumentReference doc(String path) {
    return DocumentReferenceMock(this, path);
  }

  @override
  Future<List<DocumentSnapshot>> getAll(List<DocumentReference> refs) {
    // TODO: implement getAll
    return null;
  }

  @override
  Future runTransaction(Function(Transaction transaction) updateFunction) {
    // TODO: implement runTransaction
    return null;
  }
}

class CollectionReferenceMock
    with CollectionReferenceMixin, PathReferenceMixin, FirestoreQueryMixin {
  CollectionReferenceMock(FirestoreMock firestoreMock, String path) {
    init(firestoreMock, path);
  }
  @override
  Future<DocumentReference> add(Map<String, dynamic> data) {
    // TODO: implement add
    return null;
  }

  @override
  FirestoreQueryMixin clone() {
    // TODO: implement clone
    return null;
  }

  @override
  Future<List<DocumentSnapshot>> getCollectionDocuments() {
    // TODO: implement getCollectionDocuments
    return null;
  }

  @override
  // TODO: implement parent
  DocumentReference get parent => null;

  @override
  // TODO: implement queryInfo
  QueryInfo get queryInfo => null;
}

class DocumentReferenceMock with DocumentReferenceMixin, PathReferenceMixin {
  DocumentReferenceMock(FirestoreMock firestoreMock, String path) {
    init(firestoreMock, path);
  }

  @override
  Future delete() {
    // TODO: implement delete
    return null;
  }

  @override
  Future<DocumentSnapshot> get() {
    // TODO: implement get
    return null;
  }

  @override
  Stream<DocumentSnapshot> onSnapshot() {
    // TODO: implement onSnapshot
    return null;
  }

  @override
  Future set(Map<String, dynamic> data, [SetOptions options]) {
    // TODO: implement set
    return null;
  }

  @override
  Future update(Map<String, dynamic> data) {
    // TODO: implement update
    return null;
  }
}

void main() {
  group('mixin_mock', () {
    var mock = FirestoreMock();
    test('path', () {
      var doc = mock.doc('my/path');
      expect('my/path', doc.path);
      expect('my', doc.parent.path);
    });
  });
  group('value_key_mixin', () {
    test('backtick', () {
      expect(backtickChrCode, 96);
      expect(isBacktickEnclosed('``'), isTrue);
      expect(isBacktickEnclosed('`é`'), isTrue);
      expect(isBacktickEnclosed('```'), isTrue);
      expect(isBacktickEnclosed(''), isFalse);
      expect(isBacktickEnclosed('`'), isFalse);
      expect(isBacktickEnclosed('`_'), isFalse);
      expect(isBacktickEnclosed('_`'), isFalse);
    });

    test('expandUpdateData', () {
      expect(expandUpdateData({'some.data': 1}), {
        'some': {'data': 1}
      });
      expect(expandUpdateData({'some.sub.data': 1}), {
        'some': {
          'sub': {'data': 1}
        }
      });
    });
  });
}
