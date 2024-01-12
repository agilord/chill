import 'dart:typed_data';

import 'package:buffer/buffer.dart';

class Chunk {
  final int offset;
  final Uint8List bytes;

  Chunk(this.offset, this.bytes);
}

abstract class Chunker {
  void add(List<int> bytes);
  void close();
  bool get hasChunks;
  List<Chunk> takeChunks();

  static Chunker create({
    int? length,
    String? extension,
  }) {
    if ((length ?? 0) > 1024 * 1024 * 128) {
      return _DefaultChunker(maxLength: 1024 * 1024 * 4); // 4 MiB chunks
    } else {
      return _DefaultChunker(); // 512 KiB chunks
    }
  }
}

class _DefaultChunker implements Chunker {
  final int _maxLength;

  _DefaultChunker({
    int? maxLength,
  }) : _maxLength = maxLength ?? 512 * 1024;

  final _reader = ByteDataReader();
  final _chunks = <Chunk>[];
  var _offset = 0;

  @override
  void add(List<int> bytes) {
    _reader.add(bytes);
    while (_reader.remainingLength >= _maxLength) {
      // TODO: use a rolling hash to content-defined chunking
      final chunk = Chunk(_offset, _reader.read(_maxLength));
      _chunks.add(chunk);
      _offset += chunk.bytes.length;
    }
  }

  @override
  void close() {
    if (_reader.remainingLength > 0) {
      final chunk = Chunk(_offset, _reader.read(_reader.remainingLength));
      _chunks.add(chunk);
      _offset += chunk.bytes.length;
    }
  }

  @override
  bool get hasChunks => _chunks.isNotEmpty;

  @override
  List<Chunk> takeChunks() {
    final r = [..._chunks];
    _chunks.clear();
    return r;
  }
}
