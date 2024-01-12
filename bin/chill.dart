#!/usr/bin/env dart

import 'dart:io';

import 'package:chill/src/commands/chill_command_runner.dart';
import 'package:chill/src/exceptions.dart';
import 'package:file/local.dart';

Future<void> main(List<String> arguments) async {
  try {
    await ChillCommandRunner(fileSystem: LocalFileSystem()).run(arguments);
  } on ExitError catch (e) {
    stderr.writeln(e.message);
    exit(e.exitCode);
  }
}
