import 'dart:async';

import 'package:tekartik_firebase_firestore/firestore.dart';

/// Track changes simulation.
class TrackChangesPullOptions {
  final Duration refreshDelay;

  TrackChangesPullOptions({this.refreshDelay = const Duration(seconds: 10)});
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
          await Future<void>.delayed(options!.refreshDelay);
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
