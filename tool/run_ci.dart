//@dart=2.9

import 'package:dev_test/package.dart';

Future<void> main() async {
  for (var dir in [
    'firestore_rest',
    'firestore',
    'firestore_sembast',
    'firestore',
    'firestore_browser',
    // 'firestore_flutter ',
    'firestore_idb',
    'firestore_node',
    'firestore_sim',
    'firestore_sim_browser',
    'firestore_sim_io',
    'firestore_test'
  ]) {
    await packageRunCi(dir);
  }
}
