import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:chill/src/exceptions.dart';
import 'package:chill/src/repository/repository_backup.dart';
import 'package:chill/src/repository/repository.dart';
import 'package:file/file.dart';

class BackupCommand extends Command {
  final FileSystem fileSystem;

  @override
  String get name => 'backup';

  @override
  String get description => 'Backup a directory into an archive file.';

  BackupCommand({
    required this.fileSystem,
  }) {
    argParser
      ..addOption(
        'repository',
        help: 'The repository path to use for keeping the state.',
        mandatory: true,
      )
      ..addOption(
        'output',
        help: 'The output directory to store the archive blobs.',
        mandatory: true,
      )
      ..addOption(
        'limit',
        help: 'The total limit of the bytes to write in the output directory.',
        mandatory: true,
      );
  }

  @override
  Future<void> run() async {
    final repository = argResults!['repository'] as String;
    final output = argResults!['output'] as String;
    final limit = argResults!['limit'] as String;

    final outputBytesLimit = parseLimit(limit);

    final repo = Repository(fileSystem: fileSystem, path: repository);
    await repo.load();

    await repo.backup(
      outputPath: output,
      outputBytesLimit: outputBytesLimit,
    );
  }
}

const _kb = 1000;
const _mb = _kb * _kb;
const _gb = _kb * _mb;
const _tb = _kb * _gb;
const _kib = 1024;
const _mib = _kib * _kib;
const _gib = _kib * _mib;
const _tib = _kib * _gib;

const _limitPostfixes = {
  'tib': _tib,
  'gib': _gib,
  'mib': _mib,
  'kib': _kib,
  'tb': _tb,
  'gb': _gb,
  'mb': _mb,
  'kb': _kb,
  't': _tib,
  'g': _gib,
  'm': _mib,
  'k': _kib,
};

int parseLimit(String origLimit) {
  final value = origLimit.toLowerCase().trim();
  for (final e in _limitPostfixes.entries) {
    if (value.endsWith(e.key)) {
      final vr = value.substring(0, value.length - e.key.length).trim();
      final v = double.tryParse(vr);
      if (v == null) continue;
      return (v * e.value).floor();
    }
  }
  final vi = int.tryParse(value);
  if (vi != null) {
    return vi;
  }
  throw ExitError('Unable to parse limit: `$origLimit`');
}
