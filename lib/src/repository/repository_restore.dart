import 'dart:io';

import 'package:chill/src/repository/blob/blob_reader.dart';
import 'package:chill/src/repository/repository.dart';
import 'package:cryptography/cryptography.dart';
import 'package:file/file.dart';
import 'package:path/path.dart' as p;

extension RepositoryRestoreExt on Repository {
  Future<void> restore({
    required String inputPath,
    required String outputPath,
  }) async {
    final inputDir = fileSystem.directory(inputPath);
    final inputSessions = inputDir
        .listSync()
        .whereType<File>()
        .map((e) => e.basename.split('-').first)
        .toSet()
        .toList()
      ..sort();
    for (final sessionId in inputSessions.reversed) {
      final data = await sessionStore.getSessionData(sessionId);
      final reader = BlobReader(
        fileSystem: fileSystem,
        directory: inputDir,
        sessionId: sessionId,
      );
      final secretKey = await algorithm.newSecretKeyFromBytes(data.secret);
      for (final f in data.files) {
        final hasNewer = await sessionStore.hasNewerFile(
          path: f.path,
          length: f.length,
          modified: f.modified,
          sessionStarted: data.started,
        );
        if (hasNewer) {
          continue;
        }
        final destFile = fileSystem.file(p.join(
            outputPath, f.path.startsWith('/') ? f.path.substring(1) : f.path));
        await destFile.parent.create(recursive: true);
        if (await destFile.exists() && await destFile.length() == f.length) {
          continue;
        }
        if (await destFile.exists()) {
          await destFile.delete();
        }
        final sink = destFile.openWrite();
        for (final chunk in f.chunks) {
          final encoded = await reader.read(
              offset: chunk.blobOffset, length: chunk.blobLength);
          final secretBox = SecretBox.fromConcatenation(
            encoded,
            nonceLength: algorithm.nonceLength,
            macLength: algorithm.macAlgorithm.macLength,
          );
          final decoded =
              await algorithm.decrypt(secretBox, secretKey: secretKey);
          var content = decoded;
          if (chunk.encoding == 'gz') {
            content = gzip.decode(decoded);
          }
          if (content.length != chunk.contentLength) {
            throw Exception('Decoded length does not match.');
          }
          sink.add(content);
          await sink.flush();
        }
        await sink.close();
      }
    }
  }
}
