import 'package:googleapis/firestore/v1.dart';
import 'package:tekartik_firebase_firestore/firestore.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore/v1beta1.dart';
import 'package:tekartik_firebase_firestore_rest/src/firestore_rest_impl.dart'; // ignore: implementation_imports

abstract class FirestoreServiceRest extends FirestoreService {}

FirestoreServiceRest firestoreServiceRest = FirestoreServiceRestImpl();

/// Needed for firestore database access
const String firestoreGoogleApisAuthDatastoreScope =
    FirestoreApi.datastoreScope;

@deprecated
const String googleApisAuthDatastoreScopre =
    firestoreGoogleApisAuthDatastoreScope;
@deprecated
const String googleApisAuthCloudPlatformScope = FirestoreApi.cloudPlatformScope;
