import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';

const _defaultDelay = Duration(seconds: 10);

/// Track changes simulation.
abstract class TrackChangesPullOptions {
  /// Refresh delay.
  factory TrackChangesPullOptions({Duration refreshDelay = _defaultDelay}) =>
      _TrackChangesPullOptionsWithDelay(refreshDelay: refreshDelay);

  /// Get first change only.
  factory TrackChangesPullOptions.first() => _TrackChangesPullOptionsFirst();
}

class _TrackChangesPullOptionsFirst implements TrackChangesPullOptions {}

class _TrackChangesPullOptionsWithDelay implements TrackChangesPullOptions {
  final Duration refreshDelay;

  _TrackChangesPullOptionsWithDelay(
      {this.refreshDelay = const Duration(seconds: 10)});
}

extension DocumentReferenceExtension on DocumentReference {
  Stream<DocumentSnapshot> onSnapshotSupport(
      {bool includeMetadataChanges = false, TrackChangesPullOptions? options}) {
    Future<DocumentSnapshot> getSnapshot() async {
      return get();
    }

    if (firestore.service.supportsTrackChanges) {
      return onSnapshot(includeMetadataChanges: includeMetadataChanges);
    } else {
      options ??= TrackChangesPullOptions();
      late StreamController<DocumentSnapshot> controller;
      controller = StreamController<DocumentSnapshot>(onListen: () async {
        while (true) {
          if (controller.isClosed) {
            return;
          }
          var snapshot = await getSnapshot();
          if (controller.isClosed) {
            return;
          }
          controller.add(snapshot);

          if (options is _TrackChangesPullOptionsWithDelay) {
            await Future<void>.delayed(options.refreshDelay);
          } else if (options is _TrackChangesPullOptionsFirst) {
            // Do nothing
            controller.close().unawait();
            break;
          } else {
            throw UnsupportedError('options $options');
          }
        }
      }, onCancel: () {
        controller.close();
      });
      return controller.stream;
    }
  }

  /// Get a child collection.
  CollectionReference operator [](String path) => collection(path);
}
