import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';

const _defaultShortDelay = Duration(seconds: 10);
const _defaultLongDelay = Duration(minutes: 60);

/// Track changes simulation.
abstract class TrackChangesPullOptions {
  /// Refresh delay.
  factory TrackChangesPullOptions(
          {Duration refreshDelay = _defaultShortDelay}) =>
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

extension DocumentReferenceSnapshotSupportExtension on DocumentReference {
  Stream<DocumentSnapshot> onSnapshotSupport(
      {bool includeMetadataChanges = false, TrackChangesPullOptions? options}) {
    Future<DocumentSnapshot> getSnapshot() async {
      return get();
    }

    if (firestore.service.supportsTrackChanges) {
      return onSnapshot(includeMetadataChanges: includeMetadataChanges);
    } else {
      options ??= TrackChangesPullOptions(refreshDelay: _defaultShortDelay);
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

  @Deprecated('to move')

  /// Get a child collection.
  CollectionReference operator [](String path) => collection(path);
}

/// Helper for query snapshot support
extension QuerySnapshotSupportExtension on Query {
  /// Default is to delay to 1h when onSnapshot is not supported
  Stream<QuerySnapshot> onSnapshotSupport(
      {bool includeMetadataChanges = false, TrackChangesPullOptions? options}) {
    Future<QuerySnapshot> getSnapshot() async {
      return get();
    }

    if (firestore.service.supportsTrackChanges) {
      return onSnapshot(includeMetadataChanges: includeMetadataChanges);
    } else {
      options ??= TrackChangesPullOptions(refreshDelay: _defaultLongDelay);
      late StreamController<QuerySnapshot> controller;
      controller = StreamController<QuerySnapshot>(onListen: () async {
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
}
