//import 'package:tekartik_build_utils/cmd_run.dart';
import 'package:tekartik_build_utils/common_import.dart';

Future testFirestore() async {
  var dir = 'firestore';
  await runCmd(PubCmd(pubGetArgs())..workingDirectory = dir);
  await runCmd(DartAnalyzerCmd(['lib', 'test'])..workingDirectory = dir);
  await runCmd(PubCmd(pubRunTestArgs(platforms: ['vm', 'chrome']))
    ..workingDirectory = dir);
}

Future testFirestoreSembast() async {
  var dir = 'firestore_sembast';
  await runCmd(PubCmd(pubGetArgs())..workingDirectory = dir);
  await runCmd(DartAnalyzerCmd(['lib', 'test'])..workingDirectory = dir);
  await runCmd(
      PubCmd(pubRunTestArgs(platforms: ['vm']))..workingDirectory = dir);
}

Future testFirestoreSim() async {
  var dir = 'firestore_sim';
  await runCmd(PubCmd(pubGetArgs())..workingDirectory = dir);
  await runCmd(DartAnalyzerCmd(['lib', 'test'])..workingDirectory = dir);
  await runCmd(PubCmd(pubRunTestArgs(platforms: ['vm', 'chrome']))
    ..workingDirectory = dir);
}

Future testFirestoreSimIo() async {
  var dir = 'firestore_sim_io';
  await runCmd(PubCmd(pubGetArgs())..workingDirectory = dir);
  await runCmd(DartAnalyzerCmd(['test'])..workingDirectory = dir);
  await runCmd(
      PubCmd(pubRunTestArgs(platforms: ['vm']))..workingDirectory = dir);
}

Future testFirestoreBrowser() async {
  var dir = 'firestore_browser';
  await runCmd(PubCmd(pubGetArgs())..workingDirectory = dir);
  await runCmd(DartAnalyzerCmd(['lib', 'test'])..workingDirectory = dir);
  /*
  await runCmd(
      PubCmd(pubRunTestArgs(platforms: ['chrome']))..workingDirectory = dir);
      */
}

Future testFirestoreSimBrowser() async {
  var dir = 'firestore_sim_browser';
  await runCmd(PubCmd(pubGetArgs())..workingDirectory = dir);
  await runCmd(DartAnalyzerCmd(['test'])..workingDirectory = dir);
  /*
  await runCmd(
      PubCmd(pubRunTestArgs(platforms: ['chrome']))..workingDirectory = dir);
      */
}

Future testFirestoreNode() async {
  var dir = 'firestore_node';
  await runCmd(PubCmd(pubGetArgs())..workingDirectory = dir);
  await runCmd(DartAnalyzerCmd(['lib', 'test'])..workingDirectory = dir);
  await runCmd(
      PubCmd(pubRunTestArgs(platforms: ['node']))..workingDirectory = dir);
}

Future testFirestoreFlutter() async {
  var dir = 'firestore_flutter';
  await runCmd(FlutterCmd(['packages', 'get'])..workingDirectory = dir);
  await runCmd(DartAnalyzerCmd(['lib'])..workingDirectory = dir);
}

Future testFirestoreTest() async {
  var dir = 'firestore_test';
  await runCmd(PubCmd(pubGetArgs())..workingDirectory = dir);
  await runCmd(DartAnalyzerCmd(['lib'])..workingDirectory = dir);
}

Future main() async {
  await testFirestore();
  await testFirestoreBrowser();
  await testFirestoreSembast();

  await testFirestoreSim();
  await testFirestoreSimBrowser();
  await testFirestoreSimIo();

  //await testFirestoreNode();

  //await testFirestoreFlutter();
  await testFirestoreTest();
}
