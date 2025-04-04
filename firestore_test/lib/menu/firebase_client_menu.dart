import 'dart:async';

import 'package:tekartik_app_dev_menu/dev_menu.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore/utils/collection.dart';
import 'package:tekartik_firebase_firestore/utils/track_changes_support.dart';

export 'package:tekartik_app_dev_menu/dev_menu.dart';
export 'package:tekartik_firebase_firestore/firestore.dart';

/// Top doc context
class FirestoreMainMenuContext {
  final DocumentReference doc;

  Firestore get firestore => doc.firestore;
  FirestoreMainMenuContext({required this.doc});
}

void firestoreMainMenu({required FirestoreMainMenuContext context}) {
  menu('collection', () {
    StreamSubscription? subscription;
    var coll = context.doc.collection('change');
    item('register changes', () {
      subscription?.cancel();
      subscription = coll.onSnapshotSupport().listen((event) {
        for (var item in event.docs) {
          write('onItem: $item');
        }
      });
    });
    item('cancel registration', () {
      subscription?.cancel();
    });
    item('add item', () async {
      await coll.add({'test': Timestamp.now()});
    });
    item('clear', () async {
      await deleteCollection(context.firestore, coll);
    });
    item('list', () async {
      var list = await coll.get();
      for (var item in list.docs) {
        write('item: $item');
      }
    });
  });
  menu('singleton', () {
    StreamSubscription? subscription;
    var doc = context.doc.collection('changes').doc('singleton');
    item('register changes', () {
      subscription?.cancel();
      subscription = doc.onSnapshotSupport().listen((event) {
        var now = Timestamp.now();
        var eventTimestamp = (event.data['timestamp'] as Timestamp?) ?? now;
        write(
            'diff: ${now.millisecondsSinceEpoch - eventTimestamp.millisecondsSinceEpoch} ms');
        write('onItem: ${event}');
      });
    });
    item('cancel registration', () {
      subscription?.cancel();
    });
    item('set item', () async {
      await doc.set({'timestamp': Timestamp.now()});
    });
    item('delete', () async {
      await doc.delete();
    });
    item('get', () async {
      var item = await doc.get();
      write('item: $item');
    });
  });
}
