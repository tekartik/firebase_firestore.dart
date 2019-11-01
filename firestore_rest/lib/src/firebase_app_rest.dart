import 'package:firebase/firebase_io.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore/v1beta1.dart';
import 'package:googleapis_auth/auth.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase/src/firebase_mixin.dart'; // ignore: implementation_imports
import 'package:meta/meta.dart';
import 'package:tekartik_firebase_firestore_rest/firestore_rest.dart';

class AppOptionsRestImpl extends AppOptions implements AppOptionsRest {
  final FirebaseClient fbClient;
  final AuthClient authClient;

  AppOptionsRestImpl({@required this.authClient, @required this.fbClient});
}

class FirebaseRestImpl with FirebaseMixin {
  @override
  App initializeApp({AppOptions options, String name}) {
    var impl = AppRestImpl(
        firestoreApi: FirestoreApi((options as AppOptionsRestImpl).authClient),
        firebaseRest: this,
        options: options,
        fbClient: (options as AppOptionsRestImpl).fbClient);
    return impl;
  }
}

class AppRestImpl with FirebaseAppMixin {
  final FirebaseRestImpl firebaseRest;
  final FirestoreApi firestoreApi;
  final FirebaseClient fbClient;

  @override
  final AppOptions options;

  bool deleted = false;
  @override
  String name;

  AppRestImpl(
      {@required this.firestoreApi,
      @required this.fbClient,
      @required this.firebaseRest,
      @required this.options,
      this.name});

  @override
  Future<void> delete() async {
    deleted = true;
    await closeServices();
  }
}
