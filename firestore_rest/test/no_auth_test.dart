import 'package:process_run/shell.dart';
import 'package:test/test.dart';
import 'package:path/path.dart';
import 'no_auth_firestore.dart';

void main() {
  var env = ShellEnvironment();
  var projectId = env['TEKARTIK_FIRESTORE_REST_NO_AUTH_PROJECT_ID'];
  var rootPath = env['TEKARTIK_FIRESTORE_REST_NO_AUTH_ROOT_PATH'];
  print('projectId: $projectId');
  print('rootPath: $rootPath');
  group('firestore', () {
    /// For this test specify both env variable and create a new document at rootPath
    test('rootPath', () async {
      var firestore = noAuthFirestoreRest(projectId: projectId);
      var snapshot = await firestore.doc(rootPath).get();
      expect(snapshot.data, isNotNull,
          reason: 'Missing test data in $projectId at $rootPath');

      var querySnapshot =
          await firestore.collection(url.dirname(rootPath)).get();
      expect(querySnapshot.docs.isNotEmpty, isTrue);
    });
  }, skip: (projectId == null || rootPath == null));
}
