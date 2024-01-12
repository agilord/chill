import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:chill/src/repository/repository.dart';
import 'package:chill/src/repository/repository_restore.dart';
import 'package:file/file.dart';

class RestoreCommand extends Command {
  final FileSystem fileSystem;

  @override
  String get name => 'restore';

  @override
  String get description => 'Restores the original files from an archive.';

  RestoreCommand({
    required this.fileSystem,
  }) {
    argParser
      ..addOption(
        'repository',
        help: 'The repository path to use for keeping the state.',
        mandatory: true,
      )
      ..addOption(
        'input',
        help: 'The directory to read the archives from.',
        mandatory: true,
      )
      ..addOption(
        'output',
        help: 'The output directory to store the original content.',
        mandatory: true,
      );
  }

  @override
  Future<void> run() async {
    final repository = argResults!['repository'] as String;
    final input = argResults!['input'] as String;
    final output = argResults!['output'] as String;

    final repo = Repository(fileSystem: fileSystem, path: repository);
    await repo.load();

    await repo.restore(
      inputPath: input,
      outputPath: output,
    );
  }
}
