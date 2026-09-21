import 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/collection.dart';
import 'package:tekartik_firebase_firestore/utils/query_iterate.dart';
import 'package:tekartik_firebase_firestore/utils/query_join.dart';
import 'package:tekartik_firebase_firestore_test/firestore_test_runner.dart';

/// Run query iterate and query join tests.
void runUtilsQueryIterateTest({
  required FirestoreService firestoreService,
  required Firestore firestore,
  required FirestoreTestContext? testContext,
}) {
  var testsRefPath = url.join(
    FirestoreTestContext.getRootCollectionPath(testContext),
  );

  group('utils_query_iterate', () {
    late CollectionReference authorsRef;
    late CollectionReference booksRef;

    setUp(() async {
      var rootPath = url.join(testsRefPath, 'query_iterate');
      authorsRef = firestore.collection(url.join(rootPath, 'authors'));
      booksRef = firestore.collection(url.join(rootPath, 'books'));
      await authorsRef.delete();
      await booksRef.delete();
      for (var i = 1; i <= 3; i++) {
        await authorsRef.doc('a$i').set({'name': 'author$i'});
      }
      // 2 books on author 1, 1 on author 2, 1 without an author id, 1 on an
      // author that does not exist, 1 on author 3.
      var books = <String, Map<String, Object?>>{
        'b1': {'title': 't1', 'authorId': 'a1'},
        'b2': {'title': 't2', 'authorId': 'a1'},
        'b3': {'title': 't3', 'authorId': 'a2'},
        'b4': {'title': 't4'},
        'b5': {'title': 't5', 'authorId': 'a9'},
        'b6': {'title': 't6', 'authorId': 'a3'},
      };
      for (var entry in books.entries) {
        await booksRef.doc(entry.key).set(entry.value);
      }
    });

    test('queryIterate all', () async {
      var ids = <String>[];
      await booksRef.queryIterate(
        onRow: (doc) {
          ids.add(doc.ref.id);
          return true;
        },
      );
      expect(ids, ['b1', 'b2', 'b3', 'b4', 'b5', 'b6']);
    });

    test('queryIterate page by page', () async {
      // Forces several pages, the result must not change.
      var ids = <String>[];
      await booksRef.queryIterate(
        options: QueryFindOptions(pageSize: 2),
        onRow: (doc) {
          ids.add(doc.ref.id);
          return true;
        },
      );
      expect(ids, ['b1', 'b2', 'b3', 'b4', 'b5', 'b6']);
    });

    test('queryIterate limit', () async {
      var query = booksRef.limit(3);
      expect(query.queryLimit, 3);

      var ids = <String>[];
      await query.queryIterate(
        options: QueryFindOptions(pageSize: 2),
        onRow: (doc) {
          ids.add(doc.ref.id);
          return true;
        },
      );
      expect(ids, ['b1', 'b2', 'b3']);
    });

    test('queryIterate stop', () async {
      var ids = <String>[];
      await booksRef.queryIterate(
        options: QueryFindOptions(pageSize: 2),
        onRow: (doc) {
          ids.add(doc.ref.id);
          return ids.length < 3;
        },
      );
      expect(ids, ['b1', 'b2', 'b3']);
    });

    test('queryIterate ordered by a field', () async {
      var query = booksRef.orderBy('title', descending: true);
      expect(query.orderByFields, ['title']);

      var ids = <String>[];
      await query.queryIterate(
        options: QueryFindOptions(pageSize: 2),
        onRow: (doc) {
          ids.add(doc.ref.id);
          return true;
        },
      );
      expect(ids, ['b6', 'b5', 'b4', 'b3', 'b2', 'b1']);
    });

    test('queryStream', () async {
      var ids = await booksRef
          .limit(3)
          .queryStream(options: QueryFindOptions(pageSize: 2))
          .map((doc) => doc.ref.id)
          .toList();
      expect(ids, ['b1', 'b2', 'b3']);
    });

    test('queryStream stop', () async {
      var ids = <String>[];
      await for (var doc in booksRef.queryStream(
        options: QueryFindOptions(pageSize: 2),
      )) {
        ids.add(doc.ref.id);
        if (ids.length == 2) {
          break;
        }
      }
      expect(ids, ['b1', 'b2']);
    });

    test('findDocs', () async {
      var docs = await booksRef
          .limit(3)
          .findDocs(options: QueryFindOptions(pageSize: 2));
      expect(docs.map((doc) => doc.ref.id).toList(), ['b1', 'b2', 'b3']);
    });

    /// '<book id>-><author id>' for each row, so that a failure reads well.
    Future<List<String>> join({
      Query? query,
      bool? withSource,
      bool? withTarget,
      bool? distinct,
      bool? inner,
      int? pageSize,
    }) async {
      var rows = <String>[];
      await (query ?? booksRef).queryJoinIterate(
        options: QueryJoinFindOptions(
          joinField: 'authorId',
          targetCollection: authorsRef,
          withSource: withSource,
          withTarget: withTarget,
          distinct: distinct,
          inner: inner,
          pageSize: pageSize,
        ),
        onRow: (row) {
          expect(row.sourceDoc, row.doc);
          rows.add('${row.doc?.ref.id}->${row.targetDoc?.ref.id}');
          return true;
        },
      );
      return rows;
    }

    test('queryJoinIterate left join', () async {
      expect(await join(), [
        'b1->a1',
        'b2->a1',
        'b3->a2',
        'b4->null',
        'b5->null',
        'b6->a3',
      ]);
      // Same result page by page.
      expect(await join(pageSize: 2), [
        'b1->a1',
        'b2->a1',
        'b3->a2',
        'b4->null',
        'b5->null',
        'b6->a3',
      ]);
    });

    test('queryJoinIterate inner join', () async {
      expect(await join(inner: true), ['b1->a1', 'b2->a1', 'b3->a2', 'b6->a3']);
    });

    test('queryJoinIterate distinct', () async {
      expect(await join(distinct: true), [
        'b1->a1',
        'b3->a2',
        'b4->null',
        'b5->null',
        'b6->a3',
      ]);
    });

    test('queryJoinIterate distinct inner', () async {
      expect(await join(distinct: true, inner: true), [
        'b1->a1',
        'b3->a2',
        'b6->a3',
      ]);
    });

    test('queryJoinIterate source hidden', () async {
      expect(await join(withSource: false, distinct: true, inner: true), [
        'null->a1',
        'null->a2',
        'null->a3',
      ]);
    });

    test('queryJoinIterate target hidden', () async {
      expect(await join(withTarget: false), [
        'b1->null',
        'b2->null',
        'b3->null',
        'b4->null',
        'b5->null',
        'b6->null',
      ]);
      // `inner` still drops the rows without a target document.
      expect(await join(withTarget: false, inner: true), [
        'b1->null',
        'b2->null',
        'b3->null',
        'b6->null',
      ]);
    });

    test('queryJoinIterate sourceDoc', () async {
      await booksRef
          .limit(1)
          .queryJoinIterate(
            options: QueryJoinFindOptions(
              joinField: 'authorId',
              targetCollection: authorsRef,
            ),
            onRow: (row) {
              expect(row.sourceDoc, row.doc);
              return false;
            },
          );
    });

    test('queryJoinIterate query limit', () async {
      expect(await join(query: booksRef.limit(3)), [
        'b1->a1',
        'b2->a1',
        'b3->a2',
      ]);
      expect(await join(query: booksRef.limit(3), inner: true), [
        'b1->a1',
        'b2->a1',
        'b3->a2',
      ]);
      expect(await join(query: booksRef.limit(4), inner: true), [
        'b1->a1',
        'b2->a1',
        'b3->a2',
      ]);
      expect(await join(query: booksRef.limit(4), distinct: true), [
        'b1->a1',
        'b3->a2',
        'b4->null',
      ]);
    });

    test('queryJoinIterate stop', () async {
      var rows = <String>[];
      await booksRef.queryJoinIterate(
        options: QueryJoinFindOptions(
          joinField: 'authorId',
          targetCollection: authorsRef,
        ),
        onRow: (row) {
          rows.add('${row.doc?.ref.id}->${row.targetDoc?.ref.id}');
          return rows.length < 2;
        },
      );
      expect(rows, ['b1->a1', 'b2->a1']);
    });

    test('queryJoinIterate target data', () async {
      var names = <String?>[];
      await booksRef.queryJoinIterate(
        options: QueryJoinFindOptions(
          joinField: 'authorId',
          targetCollection: authorsRef,
        ),
        onRow: (row) {
          names.add(row.targetDoc?.data['name'] as String?);
          return true;
        },
      );
      expect(names, ['author1', 'author1', 'author2', null, null, 'author3']);
    });

    test('queryJoinIterate join key and ref', () async {
      var keys = <Object?>[];
      var refs = <String?>[];
      await booksRef.queryJoinIterate(
        options: QueryJoinFindOptions(
          joinField: 'authorId',
          targetCollection: authorsRef,
        ),
        onRow: (row) {
          keys.add(row.joinKey);
          refs.add(row.targetRef?.id);
          return true;
        },
      );
      expect(keys, ['a1', 'a1', 'a2', null, 'a9', 'a3']);
      expect(refs, ['a1', 'a1', 'a2', null, 'a9', 'a3']);
    });

    test('queryJoinIterate on a document path', () async {
      // No targetCollection: the field holds the full path of the document.
      var pathBooksRef = firestore.collection(
        url.join(testsRefPath, 'query_iterate', 'path_books'),
      );
      await pathBooksRef.delete();
      await pathBooksRef.doc('p1').set({
        'authorPath': authorsRef.doc('a1').path,
      });
      await pathBooksRef.doc('p2').set({'authorPath': 'not-a-doc-path'});

      var rows = <String>[];
      await pathBooksRef.queryJoinIterate(
        options: QueryJoinFindOptions(joinField: 'authorPath'),
        onRow: (row) {
          rows.add('${row.doc?.ref.id}->${row.targetDoc?.ref.id}');
          return true;
        },
      );
      expect(rows, ['p1->a1', 'p2->null']);
    });

    test('queryJoinIterate on a nested field', () async {
      var nestedBooksRef = firestore.collection(
        url.join(testsRefPath, 'query_iterate', 'nested_books'),
      );
      await nestedBooksRef.delete();
      await nestedBooksRef.doc('n1').set({
        'ref': {'authorId': 'a2'},
      });
      await nestedBooksRef.doc('n2').set({'other': 1});

      var rows = <String>[];
      await nestedBooksRef.queryJoinIterate(
        options: QueryJoinFindOptions(
          joinField: 'ref.authorId',
          targetCollection: authorsRef,
        ),
        onRow: (row) {
          rows.add('${row.doc?.ref.id}->${row.targetDoc?.ref.id}');
          return true;
        },
      );
      expect(rows, ['n1->a2', 'n2->null']);
    });

    test('findJoinRows', () async {
      var rows = await booksRef.findJoinRows(
        options: QueryJoinFindOptions(
          joinField: 'authorId',
          targetCollection: authorsRef,
          inner: true,
        ),
      );
      expect(rows.map((row) => row.doc!.ref.id).toList(), [
        'b1',
        'b2',
        'b3',
        'b6',
      ]);
      expect(rows.map((row) => row.targetDoc!.ref.id).toList(), [
        'a1',
        'a1',
        'a2',
        'a3',
      ]);
    });
  });
}
