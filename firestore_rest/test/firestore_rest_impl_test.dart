import 'package:tekartik_firebase_firestore_rest/src/firestore/v1beta1.dart'
    as api;
import 'package:tekartik_firebase_firestore_rest/src/import.dart';
import 'package:test/test.dart';

import 'test_setup.dart';

Future main() async {
  final context = await setup();
  print(context);
  group('rest', () {
    test('basic_googleapis', () async {
      var firestoreApi = api.FirestoreApi(context.authClient);

      // curl "https://firestore.googleapis.com/v1beta1/projects/tekartik-free-dev/databases/(default)/documents/tests/data-types"
      // curl "https://firestore.googleapis.com/projects/tekartik-free-dev/databases/(default)/documents/tests/data-types"
      // ignore: unused_local_variable
      var data = await firestoreApi.projects.databases.documents.get(
          'projects/tekartik-free-dev/databases/(default)/documents/tests/data-types');
      print(jsonPretty(data.toJson()));
    });
  }, skip: context == null);

  tearDownAll(() {
    context?.authClient?.close();
  });
}
