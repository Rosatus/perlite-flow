/// Integration test against a captured snapshot of https://ob.rosata.cn.
///
/// The HTML files in this directory were fetched with the user's real
/// credentials. Parsing them here verifies that our DOM contract holds
/// against the production vault (not just hand-crafted fixtures).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:perlite_flow/models/file_node.dart';
import 'package:perlite_flow/services/perlite_client.dart';

void main() {
  final indexSkip = File('test/real_index.html').existsSync()
      ? null
      : 'Private snapshot test/real_index.html is not present.';
  final searchSkip = File('test/real_search.html').existsSync()
      ? null
      : 'Private snapshot test/real_search.html is not present.';

  group('Real vault: index.html tree', () {
    test('parses the production vault nav into a usable file tree', () {
      final file = File('test/real_index.html');
      expect(file.existsSync(), isTrue,
          reason: 'snapshot missing — fetch '
              '`curl -u user:pass https://ob.rosata.cn/ > test/real_index.html`');
      final html = file.readAsStringSync();
      final client = PerliteClient(baseUrl: 'https://ob.rosata.cn');
      final nodes = client.parseTreeForTest(html_parser.parse(html));

      expect(nodes, isNotEmpty);

      // Walk every node; each should have a non-empty name and a
      // usable handle (notePath or downloadUrl) unless it's a folder.
      var folders = 0, notes = 0, canvas = 0, attachments = 0;
      void walk(FileNode n) {
        expect(n.name.trim(), isNotEmpty,
            reason: 'node has empty name: ${n.type}');
        switch (n.type) {
          case FileNodeType.folder:
            folders++;
          case FileNodeType.note:
            notes++;
            expect(n.notePath, isNotNull,
                reason: 'note "${n.name}" missing notePath');
          case FileNodeType.canvas:
            canvas++;
            expect(n.notePath, isNotNull,
                reason: 'canvas "${n.name}" missing notePath');
          case FileNodeType.attachment:
            attachments++;
            expect(n.downloadUrl, isNotNull,
                reason: 'attachment "${n.name}" missing downloadUrl');
        }
        for (final c in n.children) {
          walk(c);
        }
      }

      for (final n in nodes) {
        walk(n);
      }

      // Print a short census so the test log shows what we found.
      // ignore: avoid_print
      print('tree: $folders folders, $notes notes, '
          '$canvas canvas, $attachments attachments');
      expect(notes + canvas + attachments, greaterThan(0));
    }, skip: indexSkip);
  });

  group('Real vault: search result fragment', () {
    test('parses Chinese search results with highlighted excerpts', () {
      final file = File('test/real_search.html');
      expect(file.existsSync(), isTrue);
      final client = PerliteClient(baseUrl: 'https://ob.rosata.cn');
      final groups =
          client.parseSearchResultsForTest(file.readAsStringSync());

      expect(groups, isNotEmpty);
      for (final g in groups) {
        expect(g.notePath, isNotEmpty);
        expect(g.displayPath, isNotEmpty);
        for (final ex in g.excerpts) {
          expect(ex.plain.trim(), isNotEmpty);
          // Each excerpt should contain at least one matched fragment.
          expect(
            ex.fragments.length,
            greaterThanOrEqualTo(2),
            reason: 'excerpt "${ex.plain}" has no highlighted run',
          );
        }
      }

      // At least one group should carry content matches (not just a
      // filename hit), otherwise the fixture is stale.
      final withContent = groups.where((g) => !g.isFileNameMatch).length;
      // ignore: avoid_print
      print('search groups: ${groups.length}, with content: $withContent');
      expect(withContent, greaterThan(0));
    }, skip: searchSkip);
  });
}
