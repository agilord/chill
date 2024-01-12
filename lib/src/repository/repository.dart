import 'package:chill/src/exceptions.dart';
import 'package:chill/src/repository/model.dart';
import 'package:chill/src/repository/session_store.dart';
import 'package:cryptography/cryptography.dart';
import 'package:file/file.dart';

class Repository {
  final FileSystem fileSystem;
  final Directory directory;
  late ChillConfig config;

  Repository({
    required this.fileSystem,
    required String path,
  }) : directory = fileSystem.directory(path);

  final algorithm = Chacha20.poly1305Aead();
  late final sessionStore = SessionStore(
    fileSystem: fileSystem,
    directory: directory.childDirectory('sessions'),
  );

  Future<void> init({
    required List<String> sources,
  }) async {
    if (sources.isEmpty) {
      throw ExitError('No source has been specified.');
    }
    if (directory.existsSync() && directory.listSync().isNotEmpty) {
      throw ExitError('Directory at `${directory.path}` is not empty.');
    }
    await directory.create(recursive: true);
    await directory.childFile('chill.yaml').writeAsString([
          'sources:',
          ...sources.map((e) => '  - $e'),
        ].join('\n'));
  }

  Future<void> load() async {
    config = ChillConfig.fromYaml(
        await directory.childFile('chill.yaml').readAsString());
    await sessionStore.load();
  }
}
