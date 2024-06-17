import 'package:dev_build/package.dart';
import 'package:path/path.dart';

var topDir = '..';

Future<void> main() async {
  for (var dir in [
    'firestore',
    'firestore_sembast',
    'firestore',
    'firestore_browser',
    'firestore_idb',
    'firestore_sim',
    'firestore_sim_browser',
    'firestore_sim_io',
    'firestore_test',
    // Run last
    'firestore_rest',
  ]) {
    await packageRunCi(join(topDir, dir));
  }
}
