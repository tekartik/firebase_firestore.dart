import 'package:path/path.dart';
import 'package:process_run/shell.dart';

var topDir = '..';

Future<void> main() async {
  var shell = Shell(workingDirectory: join(topDir, 'firestore_idb'));
  await shell.run('dart test -p vm test/firestore_idb_test.dart');
  shell = Shell(workingDirectory: join(topDir, 'firestore_sembast'));
  await shell.run('dart test -p vm test/firestore_sembast_test.dart');
  shell = Shell(workingDirectory: join(topDir, 'firestore'));
  await shell.run('dart test -p vm');
}
