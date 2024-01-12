import 'dart:convert';

import 'package:yaml/yaml.dart' as yaml;

class ChillConfig {
  final List<Source> sources;

  ChillConfig({
    required this.sources,
  });

  factory ChillConfig.fromYaml(String content) {
    return ChillConfig.fromJson(json.decode(json.encode(yaml.loadYaml(content)))
        as Map<String, dynamic>);
  }

  factory ChillConfig.fromJson(Map<String, dynamic> content) {
    final sources =
        (content['sources'] as List).map((e) => Source.fromJson(e)).toList();
    return ChillConfig(sources: sources);
  }
}

class Source {
  final String path;

  Source({
    required this.path,
  });

  factory Source.fromJson(dynamic value) {
    if (value is String) {
      return Source(path: value);
    } else {
      final map = value as Map<String, dynamic>;
      return Source(path: map['path'] as String);
    }
  }
}

class SessionData {
  final String sessionId;
  final List<int> secret;
  final DateTime started;
  final DateTime completed;
  final List<FileEntry> files;

  SessionData({
    required this.sessionId,
    required this.secret,
    required this.started,
    required this.completed,
    required this.files,
  });

  factory SessionData.fromJson(Map<String, dynamic> map) {
    return SessionData(
      sessionId: map['sessionId'] as String,
      secret: base64.decode(map['secret'] as String),
      started: DateTime.parse(map['started'] as String),
      completed: DateTime.parse(map['completed'] as String),
      files: (map['files'] as List)
          .map((e) => FileEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'secret': base64.encode(secret),
      'started': started.toIso8601String(),
      'completed': completed.toIso8601String(),
      'files': files.map((e) => e.toJson()).toList(),
    };
  }
}

class FileEntry {
  final String path;
  final int length;
  final DateTime modified;
  final List<ChunkEntry> chunks;

  FileEntry({
    required this.path,
    required this.length,
    required this.modified,
    required this.chunks,
  });

  factory FileEntry.fromJson(Map<String, dynamic> map) {
    return FileEntry(
      path: map['path'] as String,
      length: map['length'] as int,
      modified: DateTime.parse(map['modified'] as String),
      chunks: (map['chunks'] as List)
          .map((e) => ChunkEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'length': length,
      'modified': modified.toIso8601String(),
      'chunks': chunks.map((e) => e.toJson()).toList(),
    };
  }
}

class ChunkEntry {
  final int contentOffset;
  final int contentLength;
  final String? encoding;
  final int blobOffset;
  final int blobLength;

  ChunkEntry({
    required this.contentOffset,
    required this.contentLength,
    required this.encoding,
    required this.blobOffset,
    required this.blobLength,
  });

  factory ChunkEntry.fromJson(Map<String, dynamic> map) {
    return ChunkEntry(
      contentOffset: map['co'] as int,
      contentLength: map['cl'] as int,
      encoding: map['e'] as String?,
      blobOffset: map['bo'] as int,
      blobLength: map['bl'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'co': contentOffset,
      'cl': contentLength,
      if (encoding != null) 'e': encoding,
      'bo': blobOffset,
      'bl': blobLength,
    };
  }
}
