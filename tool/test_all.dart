//import 'package:tekartik_build_utils/cmd_run.dart';
import 'package:tekartik_build_utils/common_import.dart';

Future testFirestore() async {
  var dir = 'firestore';
  await runCmd(PubCmd(pubRunTestArgs(platforms: ['vm', 'chrome']))
    ..workingDirectory = dir);
}

Future testFirestoreSembast() async {
  var dir = 'firestore_sembast';
  await runCmd(
      PubCmd(pubRunTestArgs(platforms: ['vm']))..workingDirectory = dir);
}

Future testFirestoreSim() async {
  var dir = 'firestore_sim';
  await runCmd(PubCmd(pubRunTestArgs(platforms: ['vm', 'chrome']))
    ..workingDirectory = dir);
}

Future testFirestoreSimIo() async {
  var dir = 'firestore_sim_io';
  await runCmd(
      PubCmd(pubRunTestArgs(platforms: ['vm']))..workingDirectory = dir);
}

Future testFirestoreBrowser() async {
  var dir = 'firestore_browser';
  await runCmd(
      PubCmd(pubRunTestArgs(platforms: ['chrome']))..workingDirectory = dir);
}

Future testFirestoreSimBrowser() async {
  // var dir = 'firestore_sim_browser';
}

Future testFirestoreNode() async {
  var dir = 'firestore_node';
  await runCmd(
      PubCmd(pubRunTestArgs(platforms: ['node']))..workingDirectory = dir);
}

Future testFirestoreFlutter() async {
  // var dir = 'firestore_flutter';
}

Future testFirestoreTest() async {
  // var dir = 'firestore_test';
}

Future main() async {
  await Future.wait([
    testFirestore(), testFirestoreBrowser(), testFirestoreSembast(),
    testFirestoreSim(), testFirestoreSimBrowser(), testFirestoreSimIo(),

    //await testFirestoreNode();

    //await testFirestoreFlutter();
    testFirestoreTest()
  ]);
}
