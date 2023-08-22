import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';

abstract class DocumentSnapshots {
  /// The input references
  List<DocumentReference> get refs;

  /// The snapshots reference in the same order
  List<DocumentSnapshot> get docs;

  DocumentSnapshot? getDocument(DocumentReference reference);
}

class _DocumentSnapshots implements DocumentSnapshots {
  Map<DocumentReference, DocumentSnapshot?>? _map;

  _DocumentSnapshots(this.refs, this.docs);

  @override
  DocumentSnapshot? getDocument(DocumentReference reference) {
    _map ??= () {
      var map = <DocumentReference, DocumentSnapshot?>{};
      for (var i = 0; i < refs.length; i++) {
        map[refs[i]] = docs[i];
      }
      return map;
    }();
    return _map![reference];
  }

  @override
  final List<DocumentReference> refs;

  @override
  final List<DocumentSnapshot> docs;
}

/// Retrieve a list of documents by references
Stream<DocumentSnapshots> onDocumentSnapshots(
    List<DocumentReference> references) {
  List<StreamSubscription?>? subscriptions;
  late StreamController<DocumentSnapshots> controller;
  controller = StreamController<DocumentSnapshots>(onListen: () {
    var count = references.length;
    final docs = List<DocumentSnapshot?>.generate(count, (index) => null);
    subscriptions = List<StreamSubscription?>.generate(count, (index) => null);
    // remainings before the first full get
    var remainings = Set<DocumentReference>.from(references);

    void notify() {
      if (remainings.isEmpty && !controller.isClosed && !controller.isPaused) {
        /// We know the array has no nullable snapshot at this point
        controller
            .add(_DocumentSnapshots(references, docs.cast<DocumentSnapshot>()));
      }
    }

    for (var i = 0; i < references.length; i++) {
      final index = i;
      final reference = references[index];
      // ignore: cancel_subscriptions
      var subscription = reference.onSnapshot().listen((snapshot) {
        docs[index] = snapshot;
        remainings.remove(reference);
        notify();
      });
      subscriptions![index] = subscription;
    }
  }, onCancel: () {
    if (subscriptions != null) {
      for (var subscription in subscriptions!) {
        subscription!.cancel();
      }
    }
  });

  return controller.stream;
}
