import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' show md5;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple disk cache for rendered note HTML with an LRU byte cap.
/// Entries live under app-documents/note_cache (md5-named .html) plus a
/// JSON index.
class NoteCache {
  static const _limitPrefKey = 'cache_limit_bytes';
  static const defaultLimitBytes = 100 * 1024 * 1024; // 100 MB

  Directory? _dir;
  File? _indexFile;

  /// cache key -> {'size': bytes, 'lastAccess': epoch ms}
  Map<String, Map<String, int>> _index = {};

  Future<void> _ensureInit() async {
    if (_dir != null) return;
    final base = await getApplicationDocumentsDirectory();
    _dir = Directory('${base.path}/note_cache');
    if (!await _dir!.exists()) await _dir!.create(recursive: true);
    _indexFile = File('${_dir!.path}/index.json');
    if (await _indexFile!.exists()) {
      try {
        final raw = jsonDecode(await _indexFile!.readAsString());
        _index = (raw as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as Map).cast<String, int>()),
        );
      } catch (_) {
        _index = {};
      }
    }
  }

  String _keyFor(String serverUrl, String notePath) =>
      md5.convert(utf8.encode('$serverUrl::$notePath')).toString();

  Future<String?> read(String serverUrl, String notePath) async {
    await _ensureInit();
    final key = _keyFor(serverUrl, notePath);
    final f = File('${_dir!.path}/$key.html');
    if (!await f.exists()) {
      _index.remove(key);
      return null;
    }
    _index[key]?['lastAccess'] = DateTime.now().millisecondsSinceEpoch;
    await _saveIndex();
    return f.readAsString();
  }

  Future<void> write(String serverUrl, String notePath, String html) async {
    await _ensureInit();
    final key = _keyFor(serverUrl, notePath);
    final f = File('${_dir!.path}/$key.html');
    await f.writeAsString(html);
    _index[key] = {
      'size': await f.length(),
      'lastAccess': DateTime.now().millisecondsSinceEpoch,
    };
    await _evictIfNeeded();
    await _saveIndex();
  }

  Future<int> get limitBytes async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_limitPrefKey) ?? defaultLimitBytes;
  }

  Future<void> setLimitBytes(int bytes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_limitPrefKey, bytes);
    await _ensureInit();
    await _evictIfNeeded();
    await _saveIndex();
  }

  Future<void> _evictIfNeeded() async {
    final limit = await limitBytes;
    var total = _index.values.fold<int>(0, (s, e) => s + (e['size'] ?? 0));
    if (total <= limit) return;
    final entries = _index.entries.toList()
      ..sort((a, b) => (a.value['lastAccess'] ?? 0)
          .compareTo(b.value['lastAccess'] ?? 0));
    for (final e in entries) {
      if (total <= limit) break;
      final f = File('${_dir!.path}/${e.key}.html');
      if (await f.exists()) await f.delete();
      total -= e.value['size'] ?? 0;
      _index.remove(e.key);
    }
  }

  Future<int> totalBytes() async {
    await _ensureInit();
    return _index.values.fold<int>(0, (s, e) => s + (e['size'] ?? 0));
  }

  Future<void> clear() async {
    await _ensureInit();
    await for (final entity in _dir!.list()) {
      if (entity is File) await entity.delete();
    }
    _index = {};
    await _saveIndex();
  }

  Future<void> _saveIndex() async {
    await _indexFile!.writeAsString(jsonEncode(_index));
  }
}
