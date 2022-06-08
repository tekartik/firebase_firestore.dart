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
/*
public class DocumentIdsRegistration {
  final FirebaseFirestore firestore;
  final String path;
  final List<String> ids;
  final Listener listener;

  final List<DocumentSnapshot> snapshots;
  final List<ListenerRegistration> registrations;
  int size;
  int remaining;
  final Object registrationLock = new Object();
  final Handler handler;
  /// When removed, do not call the listeners
  boolean removed = false;


  public DocumentIdsRegistration(FirebaseFirestore firestore, String path, List<String> ids, Listener listener) {
    this.firestore = firestore;
    this.path = path;
    this.ids = ids;
    this.listener = listener;
    this.handler = new Handler();
    if (ids != null) {
      size = ids.size();
    } else {
      size = 0;
    }
    registrations = new ArrayList<>(size);
    snapshots = new ArrayList<>(size);
    for (int i = 0; i < size; i++) {
      registrations.add(null);
      snapshots.add(null);
    }
    remaining = size;
  }

  private void notifySnashots() {
    if (!removed) {
      final List<DocumentSnapshot> list = new ArrayList<>(snapshots);
      handler.post(() -> {
      if (!removed) {
      listener.onDocuments(list);
      }
      });
    }
  }

  private void notifySnashot(final String id, final DocumentSnapshot snapshot) {
    if (!removed) {
      handler.post(() -> {
      if (!removed) {
      listener.onDocument(id, snapshot);
      }
      });
    }
  }

  public void run() {
    synchronized (registrationLock) {
      if (size > 0) {

        for (int i = 0; i < size; i++) {
          String id = ids.get(i);
          final int index = i;
          ListenerRegistration listenerRegistration = firestore.collection(path).document(id).addSnapshotListener((DocumentSnapshot snapshot, FirebaseFirestoreException e)
              -> {
              if (!removed) {
              synchronized (registrationLock) {
              notifySnashot(id, snapshot);
              // 1 more found
              if (snapshots.get(index) == null) {
              remaining--;
              }
              snapshots.set(index, snapshot);

              // Notify once all of them read
              if (remaining == 0) {
              notifySnashots();
              }
              }
              }
              });
          registrations.set(index, listenerRegistration);
        }

      } else {
        handler.post(() -> {

        notifySnashots();

        });
      }
    }


  }

  public void remove() {
    removed = true;
    synchronized (registrationLock) {
      for (int i = 0; i < size; i++) {
        ListenerRegistration registration = registrations.get(i);
        if (registration != null) {
          registration.remove();
          registrations.set(i, null);
        }
      }
    }
  }

  public interface Listener {
  void onDocuments(List<DocumentSnapshot> snapshots);

  default void onDocument(String id, DocumentSnapshot snapshot) {}

}
}*/
