import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';

mixin FirestoreServiceMixin implements FirestoreService {
  /// Most implementation need a single instance, keep it in memory!
  final _instances = <App, Firestore>{};

  T getInstance<T extends Firestore>(App app, T Function() createIfNotFound) {
    var instance = _instances[app] as T;
    if (instance == null) {
      instance = createIfNotFound();
      _instances[app] = instance;
    }
    return instance;
  }
}
