import 'package:googleapis/firestore/v1.dart' as api;
import 'package:tekartik_firebase_firestore_rest/src/import.dart';
import 'package:test/test.dart';

import 'test_setup.dart';

Future main() async {
  Context context = await setup();
  print(context);
  group('rest', () {
    test('basic', () async {
      var data = await context.fbClient.get(
          'https://firestore.googleapis.com/v1beta1/projects/tekartik-free-dev/databases/(default)/documents/tests/data-types');
      print(data);
    });
    test('basic_googleapis', () async {
      var firestoreApi = api.FirestoreApi(context.authClient);
      var data = await firestoreApi.projects.databases.documents.get(
          'projects/tekartik-free-dev/databases/(default)/documents/tests/data-types');
      print(jsonPretty(data.toJson()));
    });
  }, skip: context == null);

  tearDownAll(() {
    context?.authClient?.close();
  });
}
