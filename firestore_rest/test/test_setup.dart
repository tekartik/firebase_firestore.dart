import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase/firebase_io.dart';
import 'package:googleapis_auth/auth.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:tekartik_firebase_firestore_rest/src/firebase_app_rest.dart';

class Context {
  Client client;
  AuthClient authClient;
  AccessToken accessToken;

  FirebaseClient get fbClient => options?.fbClient;
  AppOptionsRestImpl options;
}

const _firestoreScopes = [
  "https://www.googleapis.com/auth/cloud-platform",
  "https://www.googleapis.com/auth/userinfo.email"
];

class ServiceAccount {
  Map jsonData;
  AccessToken accessToken;
}

@deprecated
Future<AccessToken> getAccessToken(Client client) async {
  var serviceAccountJsonPath = join('test', 'local.service_account.json');

  var serviceAccountJsonString =
      File(serviceAccountJsonPath).readAsStringSync();

  var creds = ServiceAccountCredentials.fromJson(serviceAccountJsonString);

  var accessCreds = await obtainAccessCredentialsViaServiceAccount(
      creds, _firestoreScopes, client);

  return accessCreds.accessToken;
}

Future<Context> getContext(Client client) async {
  var serviceAccountJsonPath = join('test', 'local.service_account.json');

  var serviceAccountJsonString =
      File(serviceAccountJsonPath).readAsStringSync();

  var jsonData = jsonDecode(serviceAccountJsonString);
  var creds = ServiceAccountCredentials.fromJson(jsonData);

  var accessCreds = await obtainAccessCredentialsViaServiceAccount(
      creds, _firestoreScopes, client);
  var accessToken = accessCreds.accessToken;
  var fbClient = FirebaseClient(accessToken.data, client: client as BaseClient);

  var authClient = authenticatedClient(client, accessCreds);
  var appOptions =
      AppOptionsRestImpl(fbClient: fbClient, authClient: authClient)
        ..projectId = jsonData['project_id']?.toString();
  var context = Context()
    ..client = client
    ..accessToken = accessToken
    ..authClient = authClient
    ..options = appOptions;
  return context;
}

Future<Context> setup() async {
  var client = Client();
  // Load client info
  try {
    return await getContext(client);
  } catch (e) {
    client.close();
    print(e);
    print('Cannot find sample.local.config.yaml');
    print('Make sure to run the test using something like: ');
    print('  pub run build_runner test --fail-on-severe -- -p chrome');
  }
  return null;
}
