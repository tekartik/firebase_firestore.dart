import 'package:process_run/shell.dart';
import 'package:tekartik_app_node_build/app_build.dart';

Future main() async {
  var shell = Shell();

  await shell.run('''
dartanalyzer --fatal-warnings --fatal-infos .
dartfmt -n --set-exit-if-changed .
pub run test -p vm
''');
  await nodeRunTest();
}
