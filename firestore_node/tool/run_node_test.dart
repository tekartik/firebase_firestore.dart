import 'dart:async';

import 'package:tekartik_build_utils/cmd_run.dart';

Future main() async {
  await runCmd(PubCmd(['run', 'test', '-p', 'node', '-r', 'expanded']),
      verbose: true);
}
