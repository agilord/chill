import 'dart:math';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';
import 'package:file/file.dart';

class BlobReader {
  final FileSystem fileSystem;
  final Directory directory;
  final String sessionId;

  final _files = <_BlobFile>[];

  BlobReader({
    required this.fileSystem,
    required this.directory,
    required this.sessionId,
  });

  Future<void> _scanIfNeeded() async {
    if (_files.isNotEmpty) return;
    for (final f in directory.listSync().whereType<File>()) {
      if (!f.basename.startsWith('$sessionId-')) {
        continue;
      }
      if (!f.basename.endsWith('.blob')) {
        continue;
      }
      _files.add(_BlobFile(f, f.lengthSync()));
    }
    _files.sort((a, b) => a.file.path.compareTo(b.file.path));
  }

  Future<Uint8List> read({
    required int offset,
    required int length,
  }) async {
    await _scanIfNeeded();
    final bb = BytesBuffer();
    for (final f in _files) {
      if (f.length < offset) {
        offset -= f.length;
        continue;
      }
      final stopAt = min(offset + length, f.length);
      await for (final b in f.file.openRead(offset, stopAt)) {
        bb.add(b);
        offset += b.length;
        length -= b.length;
      }
      if (length > 0) {
        continue;
      } else {
        return bb.toBytes();
      }
    }
    throw Exception('Unable to read file content.');
  }
}

class _BlobFile {
  final File file;
  final int length;

  _BlobFile(this.file, this.length);
}
