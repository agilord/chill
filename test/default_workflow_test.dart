import 'package:chill/src/commands/chill_command_runner.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('Default workflow', () {
    final fileSystem = MemoryFileSystem();

    setUpAll(() async {
      fileSystem.directory('/home/user/repository/test');
      fileSystem.createFile(
        '/home/media/photos/p1.jpg',
        _generateBytes(5 * 1024 * 1024, pattern: [0, 1, 2]),
      );
    });

    test('initialize', () async {
      await ChillCommandRunner(fileSystem: fileSystem).run([
        'init',
        '--repository=/home/user/repository/test',
        '--source=/home/media/photos',
      ]);
      final repoDir = fileSystem.directory('/home/user/repository/test');
      final content = await repoDir.childFile('chill.yaml').readAsString();
      expect(content, contains('/home/media/photos'));
    });

    test('backup #1', () async {
      await ChillCommandRunner(fileSystem: fileSystem).run([
        'backup',
        '--repository=/home/user/repository/test',
        '--limit=2gb',
        '--output=/mnt/disk',
      ]);
      final outfiles = fileSystem
          .directory('/mnt/disk')
          .listSync(recursive: true)
          .whereType<File>()
          .toList();
      expect(outfiles, hasLength(2));
      expect(
        outfiles.firstWhere((e) => e.path.endsWith('blob')).lengthSync(),
        lessThan(5730 + 100), // compression works
      );
      final sessionFiles = fileSystem
          .directory('/home/user/repository/test/sessions')
          .listSync()
          .whereType<File>()
          .toList();
      expect(sessionFiles, hasLength(1));
    });

    test('backup #2', () async {
      fileSystem.createFile(
        '/home/media/photos/p2.jpg',
        _generateBytes(5 * 1024 * 1024, pattern: [0, 1, 2, 3]),
      );
      await ChillCommandRunner(fileSystem: fileSystem).run([
        'backup',
        '--repository=/home/user/repository/test',
        '--limit=2gb',
        '--output=/mnt/disk',
      ]);
      final sessionFiles = fileSystem
          .directory('/home/user/repository/test/sessions')
          .listSync()
          .whereType<File>()
          .toList();
      expect(sessionFiles, hasLength(2));
    });

    test('restore', () async {
      await ChillCommandRunner(fileSystem: fileSystem).run([
        'restore',
        '--repository=/home/user/repository/test',
        '--input=/mnt/disk',
        '--output=/mnt/restore',
      ]);
      expect(
        fileSystem.file('/home/media/photos/p1.jpg').readAsBytesSync(),
        fileSystem
            .file('/mnt/restore/home/media/photos/p1.jpg')
            .readAsBytesSync(),
      );
      for (final f
          in fileSystem.directory('/home/media').listSync(recursive: true)) {
        if (f is! File) continue;
        expect(
          f.readAsBytesSync(),
          fileSystem
              .file(p.join('/mnt/restore', f.path.substring(1)))
              .readAsBytesSync(),
          reason: f.path,
        );
      }
    });
  });
}

List<int> _generateBytes(int length, {required List<int> pattern}) {
  return List<int>.generate(length, (index) => pattern[index % pattern.length]);
}

extension on FileSystem {
  void createFile(String path, List<int> bytes) {
    final f = file(path);
    f.parent.createSync(recursive: true);
    file(path).writeAsBytesSync(bytes);
  }
}
