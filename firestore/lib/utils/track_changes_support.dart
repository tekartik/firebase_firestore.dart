import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/lazy_runner/lazy_runner.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';

// const _defaultShortDelay = Duration(seconds: 10);
const _defaultLongDelay = Duration(minutes: 60);

/// Track changes controller.
abstract class TrackChangesSupportOptionsController
    implements TrackChangesSupportOptions {
  /// Trigger a refresh (if track changes is not supported).
  void trigger();

  /// Optional delay
  factory TrackChangesSupportOptionsController({Duration? refreshDelay}) =>
      _TrackChangesSupportOptionsController(refreshDelay: refreshDelay);

  /// Dispose the controller
  void dispose();
}

extension on TrackChangesSupportOptions {
  TrackChangesSupportOptionsController wrapInController() {
    if (this is TrackChangesSupportOptionsController) {
      return this as TrackChangesSupportOptionsController;
    }
    var self = this;
    var refreshDelay = self is _TrackChangesPullOptionsWithDelay
        ? self.refreshDelay
        : null;

    return TrackChangesSupportOptionsController(refreshDelay: refreshDelay);
  }
}

/// Set by onSnapshotSupport
class _TrackChangesSupportOptionsController
    implements TrackChangesSupportOptionsController {
  LazyRunner get lazyRunner => lazyRunnerOrNull!;
  LazyRunner? lazyRunnerOrNull;
  final Duration? refreshDelay;

  /// Create and trigger
  _TrackChangesSupportOptionsController({required this.refreshDelay});

  @override
  void trigger() {
    lazyRunnerOrNull?.trigger();
  }

  @override
  void dispose() {
    lazyRunnerOrNull?.dispose();
  }
}

/// Compatibility
typedef TrackChangesPullOptions = TrackChangesSupportOptions;

/// Track changes simulation.
abstract class TrackChangesSupportOptions {
  /// Refresh delay.
  factory TrackChangesSupportOptions({
    Duration refreshDelay = _defaultLongDelay,
  }) => _TrackChangesPullOptionsWithDelay(refreshDelay: refreshDelay);

  /// Get first change only.
  factory TrackChangesSupportOptions.first() => _TrackChangesPullOptionsFirst();
}

class _TrackChangesPullOptionsFirst implements TrackChangesSupportOptions {}

class _TrackChangesPullOptionsWithDelay implements TrackChangesSupportOptions {
  final Duration refreshDelay;

  _TrackChangesPullOptionsWithDelay({required this.refreshDelay});
}

/// Helper for document snapshot support
extension DocumentReferenceSnapshotSupportExtension on DocumentReference {
  /// Add on snapshot support for services without track changes support.
  /// ignored otherwise
  Stream<DocumentSnapshot> onSnapshotSupport({
    bool includeMetadataChanges = false,
    TrackChangesSupportOptions? options,
  }) {
    Future<DocumentSnapshot> getSnapshot() async {
      return get();
    }

    if (firestore.service.supportsTrackChanges) {
      return onSnapshot(includeMetadataChanges: includeMetadataChanges);
    } else {
      TrackChangesSupportOptionsController? createdController;
      options ??= TrackChangesSupportOptions(refreshDelay: _defaultLongDelay);
      if (options is! TrackChangesSupportOptionsController) {
        createdController = options.wrapInController();
      }
      late StreamController<DocumentSnapshot> snapshotController;
      snapshotController = StreamController<DocumentSnapshot>(
        onListen: () async {
          var controller = createdController;
          if (options is _TrackChangesSupportOptionsController) {
            controller = options;
          }
          if (controller is _TrackChangesSupportOptionsController) {
            var refreshDelay = controller.refreshDelay;
            Future<void> read(int count) async {
              if (snapshotController.isClosed) {
                return Future.value();
              }
              var snapshot = await getSnapshot();
              if (snapshotController.isClosed) {
                return;
              }
              snapshotController.add(snapshot);
            }

            /// Once only
            if (options is _TrackChangesPullOptionsFirst) {
              await read(0);
              // Do nothing
              snapshotController.close().unawait();
              return;
            }

            var lazyRunner = refreshDelay == null
                ? LazyRunner(action: read)
                : LazyRunner.periodic(duration: refreshDelay, action: read);
            controller.lazyRunnerOrNull = lazyRunner;
            lazyRunner.trigger();
            return;
          }
          while (true) {
            if (snapshotController.isClosed) {
              return;
            }

            var snapshot = await getSnapshot();
            if (snapshotController.isClosed) {
              return;
            }
            snapshotController.add(snapshot);

            if (options is _TrackChangesPullOptionsWithDelay) {
              await Future<void>.delayed(options.refreshDelay);
            } else if (options is _TrackChangesPullOptionsFirst) {
              // Do nothing
              snapshotController.close().unawait();
              break;
            } else {
              throw UnsupportedError('options $options');
            }
          }
        },
        onCancel: () {
          snapshotController.close();
          createdController?.dispose();
        },
      );
      return snapshotController.stream;
    }
  }

  @Deprecated('to move')
  /// Get a child collection.
  CollectionReference operator [](String path) => collection(path);
}

/// Helper for query snapshot support
extension QuerySnapshotSupportExtension on Query {
  /// Default is to delay to 1h when onSnapshot is not supported
  Stream<QuerySnapshot> onSnapshotSupport({
    bool includeMetadataChanges = false,
    TrackChangesSupportOptions? options,
  }) {
    Future<QuerySnapshot> getSnapshot() async {
      return get();
    }

    if (firestore.service.supportsTrackChanges) {
      return onSnapshot(includeMetadataChanges: includeMetadataChanges);
    } else {
      TrackChangesSupportOptionsController? createdController;
      options ??= TrackChangesSupportOptions(refreshDelay: _defaultLongDelay);
      if (options is! TrackChangesSupportOptionsController) {
        createdController = options.wrapInController();
      }
      late StreamController<QuerySnapshot> snapshotController;
      snapshotController = StreamController<QuerySnapshot>(
        onListen: () async {
          var controller = createdController;
          if (options is _TrackChangesSupportOptionsController) {
            controller = options;
          }
          if (controller is _TrackChangesSupportOptionsController) {
            var refreshDelay = controller.refreshDelay;
            Future<void> read(int count) async {
              if (snapshotController.isClosed) {
                return Future.value();
              }
              var snapshot = await getSnapshot();
              if (snapshotController.isClosed) {
                return;
              }
              snapshotController.add(snapshot);
            }

            /// Once only
            if (options is _TrackChangesPullOptionsFirst) {
              await read(0);
              // Do nothing
              snapshotController.close().unawait();
              return;
            }

            var lazyRunner = refreshDelay == null
                ? LazyRunner(action: read)
                : LazyRunner.periodic(duration: refreshDelay, action: read);
            controller.lazyRunnerOrNull = lazyRunner;
            lazyRunner.trigger();
            return;
          }
        },
        onCancel: () {
          createdController?.dispose();
          snapshotController.close();
        },
      );
      return snapshotController.stream;
    }
  }
}
