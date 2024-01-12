import 'dart:math';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';
import 'package:cryptography/cryptography.dart';
import 'package:file/file.dart';

final _random = Random.secure();

class BlobWriter {
  final FileSystem fileSystem;
  final String outputPath;
  final String sessionId;

  final _maxLength = 1024 * 1024 * 1024;
  int _offset = 0;
  int _remainingLength = 0;
  int _nextFileId = 0;
  File? _currentFile;
  IOSink? _currentSink;
  HashSink? _currentHashSink;

  final _hashLines = <String>[];

  BlobWriter({
    required this.fileSystem,
    required this.outputPath,
    required this.sessionId,
  });

  Future<void> _prepareNextFile() async {
    final dir = fileSystem.directory(outputPath);
    if (_currentFile == null) {
      await dir.create(recursive: true);
    } else {
      await _rollHash();
    }
    _currentSink = null;
    _currentFile = dir.childFile(
        '$sessionId-${_nextFileId.toRadixString(36).padLeft(6, '0')}.blob');
    _nextFileId++;
    _remainingLength = _maxLength;
    _currentHashSink = Sha512().newHashSink();
  }

  Future<void> close() async {
    if (_currentFile == null) {
      return;
    }
    if (_currentSink != null) {
      await _currentSink!.close();
    }
    if (_currentFile!.existsSync()) {
      await _rollHash();
    }
    await fileSystem
        .directory(outputPath)
        .childFile('$sessionId-hashes.txt')
        .writeAsString(_hashLines.join());
  }

  Future<void> _rollHash() async {
    _currentHashSink!.close();
    final hash = await _currentHashSink!.hash();
    final hashStr =
        hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    _hashLines.add('$hashStr  ${_currentFile!.basename}\n');
  }

  Future<int> write(Uint8List bytes) async {
    if (_currentFile == null || _remainingLength == 0) {
      await _prepareNextFile();
    }
    if (_currentFile == null) {
      await _writeToSink(_randomBytes(_random.nextInt(32)));
    } else {
      await _writeToSink(_randomBytes(_random.nextInt(4)));
    }
    final r = _offset;
    if (_remainingLength > bytes.length) {
      await _writeToSink(bytes);
      return r;
    }
    final reader = ByteDataReader()..add(bytes);
    while (reader.remainingLength > 0) {
      final crl = reader.remainingLength;
      if (_remainingLength < crl) {
        await _writeToSink(reader.read(_remainingLength));
        await _prepareNextFile();
        continue;
      }
      await _writeToSink(reader.read(crl));
    }
    return r;
  }

  Future<void> _writeToSink(List<int> bytes) async {
    if (bytes.isEmpty) return;
    _currentSink ??= _currentFile!.openWrite();
    _currentSink!.add(bytes);
    await _currentSink!.flush();
    _currentHashSink!.add(bytes);
    _remainingLength -= bytes.length;
    _offset += bytes.length;
  }
}

List<int> _randomBytes(int length) {
  return List<int>.generate(length, (_) => _random.nextInt(256));
}
