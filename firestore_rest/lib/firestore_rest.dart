import 'package:firebase/firebase_io.dart';
import 'package:googleapis_auth/auth.dart';
import 'package:tekartik_firebase/firebase.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_rest/src/firebase_app_rest.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart'; // ignore: implementation_imports
import 'package:tekartik_firebase_firestore_rest/src/import.dart';

abstract class AppOptionsRest extends AppOptions {
  factory AppOptionsRest(
          {@required AuthClient authClient, FirebaseClient firebaseClient}) =>
      AppOptionsRestImpl(fbClient: firebaseClient, authClient: authClient);
}

abstract class FirestoreServiceRest extends FirestoreService {}

FirestoreServiceRest firestoreServiceRest = FirestoreServiceRestImpl();

Firebase firebaseRest = FirebaseRestImpl();

const String googleApisAuthDatastoreScopre =
    'https://www.googleapis.com/auth/datastore';
const String googleApisAuthCloudPlatformScope =
    'https://www.googleapis.com/auth/cloud-platform';
