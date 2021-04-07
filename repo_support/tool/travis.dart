import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:process_run/which.dart';

Future main() async {
  var shell = Shell();

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
    shell = shell.pushd(join('..', dir));
    await shell.run('''
    
    pub get
    dart tool/travis.dart
    
''');
    shell = shell.popd();
  }

  if ((await which('flutter')) != null) {
    for (var dir in [
      'firestore_flutter',
    ]) {
      shell = shell.pushd(join('..', dir));
      await shell.run('''
    
  flutter pub get
  dart tool/travis.dart
  
''');
      shell = shell.popd();
    }
  }
}
