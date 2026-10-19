import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../models/file_node.dart';
import '../models/search_result.dart';

class PerliteAuthException implements Exception {
  final String message;
  const PerliteAuthException([this.message = 'Unauthorized']);
  @override
  String toString() => message;
}

class PerliteUnreachableException implements Exception {
  final String message;
  const PerliteUnreachableException([this.message = 'Server unreachable']);
  @override
  String toString() => message;
}

/// Thin client over Perlite's `content.php` endpoints. There is no JSON API;
/// every call returns HTML which we parse into structured models.
class PerliteClient {
  final Dio _dio;

  PerliteClient({
    required String baseUrl,
    String? username,
    String? password,
    Duration timeout = const Duration(seconds: 15),
  }) : _dio = Dio(BaseOptions(
          // Dio joins `baseUrl + path` with no separator, so a missing
          // trailing slash turns `example.com` + `content.php` into
          // `example.comcontent.php` — a DNS lookup that can never
          // resolve. Normalize once here.
          baseUrl: baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
          connectTimeout: timeout,
          receiveTimeout: timeout,
          followRedirects: true,
          validateStatus: (s) => s != null && s < 500,
        )) {
    if (username != null && username.isNotEmpty) {
      _dio.options.headers['Authorization'] =
          'Basic ${base64Encode(utf8.encode('$username:${password ?? ''}'))}';
    }

  }

  String get baseUrl => _dio.options.baseUrl;

  Never _rethrow(DioException e) {
    final code = e.response?.statusCode;
    if (code == 401) {
      throw const PerliteAuthException('用户名或密码错误 (401)');
    }
    if (code == 403) {
      throw const PerliteAuthException('访问被拒绝 (403)');
    }
    final inner = e.error?.toString() ?? '';
    final msg = e.message ?? (inner.isNotEmpty ? inner : e.type.name);
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.unknown) {
      // Distinguish DNS / TLS / refused so users know where to look.
      final detail = inner.isEmpty ? '' : ' ($inner)';
      if (inner.contains('Failed host lookup') ||
          inner.contains('No address associated')) {
        throw const PerliteUnreachableException('域名解析失败，请检查地址');
      }
      if (inner.contains('handshake') ||
          inner.contains('certificate') ||
          inner.contains('CERT_')) {
        throw const PerliteUnreachableException('TLS 握手失败，请检查 HTTPS 证书');
      }
      if (inner.contains('Connection refused') ||
          inner.contains('errno = 111')) {
        throw const PerliteUnreachableException('连接被拒绝（端口未开放或防火墙拦截）');
      }
      if (inner.contains('Network is unreachable') ||
          inner.contains('errno = 101')) {
        throw const PerliteUnreachableException('网络不可达，请检查网络或代理');
      }
      throw PerliteUnreachableException('无法连接服务器: $msg$detail');
    }
    throw PerliteUnreachableException('请求失败: $msg$inner');
  }

  Future<String> _get(String path, Map<String, String> query) async {
    try {
      final res = await _dio.get<String>(path, queryParameters: query);
      final code = res.statusCode;
      if (code == 401) {
        throw const PerliteAuthException('用户名或密码错误 (401)');
      }
      if (code == 404) {
        throw const PerliteUnreachableException('服务器返回 404，请检查 URL');
      }
      if (code == null || code >= 400) {
        throw PerliteUnreachableException('HTTP $code');
      }
      return res.data ?? '';
    } on DioException catch (e) {
      _rethrow(e);
    }
  }

  /// Probes connectivity. Returns null on success, error message otherwise.
  Future<String?> probe() async {
    try {
      await _get('content.php', {'about': ''});
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Fetches the rendered HTML fragment for a note.
  Future<String> fetchNoteHtml(String notePath) {
    return _get('content.php', {'mdfile': notePath});
  }

  /// Fetches the vault index note (`?home`).
  Future<String> fetchHomeHtml() {
    return _get('content.php', {'home': ''});
  }

  /// Fetches the landing page and parses the nav file tree out of it.
  Future<List<FileNode>> fetchFileTree() async {
    final html = await _get('index.php', const {});
    final doc = html_parser.parse(html);
    return _parseTree(doc);
  }

  @visibleForTesting
  List<FileNode> parseTreeForTest(dom.Document doc) => _parseTree(doc);

  List<FileNode> _parseTree(dom.Document doc) {
    List<FileNode> parseContainer(dom.Element container) {
      final nodes = <FileNode>[];
      for (final el in container.children) {
        if (!el.classes.contains('tree-item')) continue;
        if (el.classes.contains('nav-folder')) {
          final titleEl = el.querySelector('.nav-folder-title-content');
          final childrenEl = el.querySelector('.nav-folder-children');
          nodes.add(FileNode(
            name: titleEl?.text.trim() ?? '?',
            type: FileNodeType.folder,
            children:
                childrenEl != null ? parseContainer(childrenEl) : const [],
          ));
        } else if (el.classes.contains('nav-file')) {
          nodes.add(_parseFileNode(el));
        }
      }
      return nodes;
    }

    final nav = doc.querySelector('.nav-files-container') ??
        doc.querySelector('.tree-item-children') ??
        doc.body!;
    return parseContainer(nav);
  }

  FileNode _parseFileNode(dom.Element el) {
    final title =
        el.querySelector('.nav-file-title-content')?.text.trim() ?? '?';
    final tag = el.querySelector('.nav-file-tag')?.text.trim();

    final clickable = el.querySelector('[onclick*="getContent"]');
    if (clickable != null) {
      final onclick = clickable.attributes['onclick'] ?? '';
      final m = RegExp(r'''getContent\('([^']*)'\)''').firstMatch(onclick);
      final path = m != null ? Uri.decodeComponent(m.group(1)!) : null;
      return FileNode(
        name: title,
        type: tag == 'canvas' ? FileNodeType.canvas : FileNodeType.note,
        notePath: path,
      );
    }

    final link = el.querySelector('a[href]');
    return FileNode(
      name: title,
      type: FileNodeType.attachment,
      downloadUrl: link?.attributes['href'],
    );
  }

  /// Runs a full-text search and parses the HTML fragment into groups.
  /// A group whose filename matched has an empty [SearchResultGroup.matches]
  /// list and [SearchResultGroup.isFileNameMatch] = true.
  Future<List<SearchResultGroup>> search(String query) {
    return _get('content.php', {'search': query}).then(_parseSearchResults);
  }

  @visibleForTesting
  List<SearchResultGroup> parseSearchResultsForTest(String html) =>
      _parseSearchResults(html);

  List<SearchResultGroup> _parseSearchResults(String html) {
    final doc = html_parser.parse(html);
    final groups = <SearchResultGroup>[];
    for (final item in doc.querySelectorAll('.tree-item.search-result')) {
      final titleEl = item.querySelector('.tree-item-inner');
      final displayPath = titleEl?.text.trim() ?? '';
      final onclickHost = item.querySelector('[onclick*="getContent"]');
      final onclick = onclickHost?.attributes['onclick'] ?? '';
      final m = RegExp(r'''getContent\('([^']*)'\)''').firstMatch(onclick);
      if (m == null) continue;
      final notePath = Uri.decodeComponent(m.group(1)!);

      final matches = item
          .querySelectorAll('.search-result-file-match')
          .map((e) => e.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      // Build highlighted excerpts: walk each .search-result-file-match
      // element and split its text at <span class="search-result-file-
      // matched-text"> boundaries so the UI can bold the hit.
      final excerpts = item
          .querySelectorAll('.search-result-file-match')
          .map(_toExcerpt)
          .where((e) => e.plain.trim().isNotEmpty)
          .toList();

      groups.add(SearchResultGroup(
        notePath: notePath,
        displayPath: displayPath,
        matches: matches,
        isFileNameMatch: matches.isEmpty,
        excerpts: excerpts,
      ));
    }
    return groups;
  }

  /// Splits a `.search-result-file-match` DOM subtree into alternating
  /// plain/matched fragments. The Perlite search template wraps each hit
  /// in `<span class="search-result-file-matched-text">`.
  ///
  /// Contract: even indices are plain runs, odd indices are matched runs.
  /// An empty leading plain fragment is inserted when the excerpt starts
  /// with a match.
  SearchExcerpt _toExcerpt(dom.Element el) {
    final pieces =
        <({String text, bool match})>[]; // capture in encounter order
    void walk(dom.Node node, bool inMatch) {
      if (node is dom.Text) {
        if (node.text.isEmpty) return;
        pieces.add((text: node.text, match: inMatch));
        return;
      }
      if (node is dom.Element) {
        final isMatchSpan = node.classes.contains(
          'search-result-file-matched-text',
        );
        for (final child in node.nodes) {
          walk(child, inMatch || isMatchSpan);
        }
      }
    }

    for (final child in el.nodes) {
      walk(child, false);
    }

    // Merge consecutive same-kind pieces into runs.
    final runs = <({String text, bool match})>[];
    for (final p in pieces) {
      if (runs.isNotEmpty && runs.last.match == p.match) {
        runs[runs.length - 1] =
            (text: runs.last.text + p.text, match: p.match);
      } else {
        runs.add(p);
      }
    }
    // Convert runs to alternating fragments where even indices are
    // plain and odd are matched. Pad with empty strings as needed.
    final fragments = <String>[];
    for (final r in runs) {
      while ((fragments.length.isOdd) != r.match) {
        fragments.add('');
      }
      fragments.add(r.text);
    }
    return SearchExcerpt(fragments);
  }

  /// Resolves a possibly-relative href from rendered content to an absolute URL.
  String resolveUrl(String href) => _dio.options.baseUrl + href;
}
