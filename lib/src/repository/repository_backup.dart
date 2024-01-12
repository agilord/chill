import 'dart:io';

import 'package:chill/src/repository/blob/blob_writer.dart';
import 'package:chill/src/repository/blob/entropy.dart';
import 'package:chill/src/repository/chunker/chunker.dart';
import 'package:chill/src/repository/model.dart';
import 'package:chill/src/repository/repository.dart';
import 'package:file/file.dart';
import 'package:path/path.dart' as p;

extension RepositoryExt on Repository {
  Future<void> backup({
    required String outputPath,
    required int outputBytesLimit,
  }) async {
    final started = DateTime.now().toUtc();
    int bytesRemaining = outputBytesLimit;
    final secretKey = await algorithm.newSecretKey();
    final fileEntries = <FileEntry>[];
    final sessionId = await sessionStore.nextSessionId();

    final blobWriter = BlobWriter(
      fileSystem: fileSystem,
      outputPath: outputPath,
      sessionId: sessionId,
    );
    for (final source in config.sources) {
      if (bytesRemaining <= 0) break;
      final sourceDir = fileSystem.directory(source.path);
      await for (final e in sourceDir.list(recursive: true)) {
        if (e is! File) {
          continue;
        }
        final modified = await e.lastModified();
        final length = await e.length();
        if (!await sessionStore.shouldIncludeFile(
          file: e,
          modified: modified,
          length: length,
        )) {
          continue;
        }

        if (bytesRemaining < length) {
          // TODO: file split over archives
          break;
        }

        final entries = <ChunkEntry>[];
        final chunker = Chunker.create(
          length: length,
          extension: p.extension(e.path),
        );

        Future<void> processChunks() async {
          for (final chunk in chunker.takeChunks()) {
            final contentBytes = chunk.bytes;
            final contentEntropy = contentBytes.entropy();
            String? encoding;
            List<int> encodedBytes = contentBytes;
            if (contentEntropy <= 0.9) {
              final gzipped = gzip.encode(contentBytes);
              if (gzipped.length < contentBytes.length) {
                encoding = 'gz';
                encodedBytes = gzipped;
              }
            }
            final secretBox =
                await algorithm.encrypt(encodedBytes, secretKey: secretKey);
            final allBytes = secretBox.concatenation();
            final blobOffset = await blobWriter.write(allBytes);
            entries.add(ChunkEntry(
              contentOffset: chunk.offset,
              contentLength: chunk.bytes.length,
              encoding: encoding,
              blobOffset: blobOffset,
              blobLength: allBytes.length,
            ));
          }
        }

        await for (final b in e.openRead()) {
          chunker.add(b);
          if (!chunker.hasChunks) {
            continue;
          }
          await processChunks();
        }
        chunker.close();
        await processChunks();

        fileEntries.add(FileEntry(
          path: e.path,
          length: length,
          modified: modified,
          chunks: entries,
        ));
      }
    }
    final completed = DateTime.now().toUtc();
    await blobWriter.close();
    await sessionStore.storeSession(SessionData(
      sessionId: sessionId,
      secret: await secretKey.extractBytes(),
      started: started,
      completed: completed,
      files: fileEntries,
    ));
  }
}
