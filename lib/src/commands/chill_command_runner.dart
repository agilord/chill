import 'package:args/command_runner.dart';
import 'package:chill/src/commands/backup_command.dart';
import 'package:chill/src/commands/restore_command.dart';
import 'package:file/file.dart';

import 'init_command.dart';

class ChillCommandRunner extends CommandRunner {
  ChillCommandRunner({
    required FileSystem fileSystem,
  }) : super(
          'chill',
          'Backup tool for incremental cold storage archives.',
        ) {
    addCommand(InitCommand(fileSystem: fileSystem));
    addCommand(BackupCommand(fileSystem: fileSystem));
    addCommand(RestoreCommand(fileSystem: fileSystem));
  }
}
