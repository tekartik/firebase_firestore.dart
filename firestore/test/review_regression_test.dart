import 'dart:async';

import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/src/common/firestore_mock.dart';
import 'package:tekartik_firebase_firestore/utils/document.dart';
import 'package:tekartik_firebase_firestore/utils/firestore_mixin.dart';
import 'package:tekartik_firebase_firestore/utils/track_changes_support.dart';
import 'package:test/test.dart';

/// A document whose listener fails (permission denied...).
class _FailingDocumentReference extends DocumentReferenceMock {
  _FailingDocumentReference(super.firestoreMock, super.path);

  @override
  Stream<DocumentSnapshot> onSnapshot({bool includeMetadataChanges = false}) =>
      Stream.error(StateError('denied'));
}

/// A snapshot holding [data].
class _Snapshot extends DocumentSnapshotBase {
  _Snapshot(DocumentReference ref, Map<String, Object?> data)
    : super(ref, null, DocumentData(data));
}

/// Listen to [stream] until done or [timeout], the errors and the done event
/// recorded as 'error' and 'done'.
Future<List<String>> _events(
  Stream<Object?> stream, {
  Duration timeout = const Duration(milliseconds: 300),
}) async {
  var events = <String>[];
  var done = Completer<void>();
  var subscription = stream.listen(
    (_) => events.add('data'),
    onError: (Object _) => events.add('error'),
    onDone: () {
      events.add('done');
      done.complete();
    },
  );
  await done.future.timeout(timeout, onTimeout: () {});
  await subscription.cancel();
  return events;
}

void main() {
  group('review regression', () {
    test('onSnapshotSupport first() sends a read error then closes', () async {
      // The mock get throws, its service does not track changes.
      var docRef = FirestoreMock().doc('test/doc');
      expect(
        await _events(
          docRef.onSnapshotSupport(options: TrackChangesSupportOptions.first()),
        ),
        ['error', 'done'],
      );
      var collRef = FirestoreMock().collection('test');
      expect(
        await _events(
          collRef.onSnapshotSupport(
            options: TrackChangesSupportOptions.first(),
          ),
        ),
        ['error', 'done'],
      );
    });

    test('onSnapshotSupport periodic sends the read errors', () async {
      var docRef = FirestoreMock().doc('test/doc');
      var events = await _events(
        docRef.onSnapshotSupport(
          options: TrackChangesSupportOptions(
            refreshDelay: const Duration(milliseconds: 20),
          ),
        ),
      );
      expect(events, isNotEmpty);
      expect(events.toSet(), {'error'});
    });

    test('onDocumentSnapshots sends a document listener error', () async {
      var mock = FirestoreMock();
      var errors = <Object>[];
      Object? uncaught;
      await runZonedGuarded(
        () async {
          var subscription = onDocumentSnapshots([
            _FailingDocumentReference(mock, 'test/doc'),
          ]).listen((_) {}, onError: (Object error) => errors.add(error));
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await subscription.cancel();
        },
        (error, _) {
          uncaught = error;
        },
      );
      expect(uncaught, isNull);
      expect(errors, [isA<StateError>()]);
    });

    test('cursor with fewer values than two order by fields', () {
      var mock = FirestoreMock();
      // Only the first value is given, like Firestore only it is compared.
      var queryInfo = QueryInfo()
        ..orderBys = [
          OrderByInfo(fieldPath: 'a', ascending: true),
          OrderByInfo(fieldPath: 'b', ascending: true),
        ]
        ..startAt(values: [2]);
      bool matches(String id, Map<String, Object?> data) =>
          snapshotMapQueryInfo(
            _Snapshot(mock.doc('test/$id'), data),
            queryInfo,
          );
      expect(matches('one', {'a': 1, 'b': 2}), isFalse);
      expect(matches('two', {'a': 2, 'b': 1}), isTrue);
      expect(matches('three', {'a': 3, 'b': 0}), isTrue);
    });

    test('DocumentData.setProperty converts lists and typed values', () {
      var data = DocumentData();
      data.setProperty('list', [
        1,
        [2],
        {'a': 3},
      ]);
      expect(data.getProperty('list'), [
        1,
        [2],
        {'a': 3},
      ]);
      var timestamp = Timestamp(1, 2);
      var ref = FirestoreMock().doc('test/doc');
      data.setProperty('typed', {
        'timestamp': timestamp,
        'ref': ref,
        'geo': const GeoPoint(1, 2),
        'vector': const VectorValue([1.0]),
      });
      expect(data.getProperty('typed'), {
        'timestamp': timestamp,
        'ref': ref,
        'geo': const GeoPoint(1, 2),
        'vector': const VectorValue([1.0]),
      });
    });
  });
}
