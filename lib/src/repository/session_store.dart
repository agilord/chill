import 'dart:convert';
import 'dart:io';

import 'package:chill/src/repository/model.dart';
import 'package:file/file.dart';

class SessionStore {
  final FileSystem fileSystem;
  final Directory directory;

  final _sessions = <SessionData>[];

  SessionStore({
    required this.fileSystem,
    required this.directory,
  });

  Future<String> nextSessionId() async {
    return DateTime.now()
        .millisecondsSinceEpoch
        .toRadixString(16)
        .padLeft(16, '0');
  }

  Future<void> load() async {
    if (!directory.existsSync()) {
      return;
    }
    for (final f in directory.listSync().whereType<File>()) {
      final data = SessionData.fromJson(
          json.decode(utf8.decode(gzip.decode(await f.readAsBytes())))
              as Map<String, dynamic>);
      _sessions.add(data);
    }
    _sessions.sort((a, b) => a.started.compareTo(b.started));
  }

  Future<void> storeSession(SessionData sessionData) async {
    await directory.create(recursive: true);
    final sessionFile = directory.childFile('${sessionData.sessionId}.json.gz');
    await sessionFile.writeAsBytes(GZipCodec(level: ZLibOption.maxLevel)
        .encode(utf8.encode(json.encode(sessionData.toJson()))));
    _sessions.add(sessionData);
  }

  Future<bool> shouldIncludeFile({
    required File file,
    required int length,
    required DateTime modified,
  }) async {
    for (final s in _sessions.reversed) {
      for (final f in s.files) {
        if (file.path != f.path) continue;
        if (length != f.length) continue;
        if (modified != f.modified) continue;
        return false;
      }
    }
    return true;
  }

  Future<bool> hasNewerFile({
    required String path,
    required int length,
    required DateTime modified,
    required DateTime sessionStarted,
  }) async {
    for (final s in _sessions.where((e) => e.started.isAfter(sessionStarted))) {
      for (final f in s.files) {
        if (f.path == path) {
          return true;
        }
      }
    }
    return false;
  }

  Future<SessionData> getSessionData(String sessionId) async {
    return _sessions.firstWhere((e) => e.sessionId == sessionId);
  }
}
