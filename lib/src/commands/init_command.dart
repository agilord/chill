import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:chill/src/repository/repository.dart';
import 'package:file/file.dart';

class InitCommand extends Command {
  final FileSystem fileSystem;

  @override
  String get name => 'init';

  @override
  String get description => 'Initialize a local database';

  InitCommand({
    required this.fileSystem,
  }) {
    argParser
      ..addOption(
        'repository',
        mandatory: true,
        help: 'The local directory to store the repository information.',
      )
      ..addMultiOption(
        'source',
        help: 'source directory to backup',
      );
  }

  @override
  Future<void> run() async {
    final repository = argResults!['repository'] as String;
    final sources = argResults!['source'] as List<String>;

    final repo = Repository(fileSystem: fileSystem, path: repository);
    await repo.init(sources: sources);
  }
}
