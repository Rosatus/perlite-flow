/// Live test against the real Perlite server.
///
/// Runs on the Android emulator and exercises the full Dio + parsing
/// pipeline against https://ob.rosata.cn with the user's real
/// credentials. This is the only test that proves the app can reach a
/// Perlite instance through the emulator's NAT networking stack.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:perlite_flow/models/file_node.dart';
import 'package:perlite_flow/services/perlite_client.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const baseUrl = 'https://ob.rosata.cn';
  const user = 'rosatus';
  const pass = '79601522';

  PerliteClient buildClient() => PerliteClient(
        baseUrl: baseUrl,
        username: user,
        password: pass,
        timeout: const Duration(seconds: 20),
      );

  group('live Perlite @ ob.rosata.cn', () {
    test('pre-flight: ensure netd is ready before Dio calls', () async {
      // Emulator cold-boot: netd may not have bound the DNS resolver
      // to this app's network yet. Force a warmup socket to wake it.
      final probe = await InternetAddress.lookup('ob.rosata.cn')
          .timeout(const Duration(seconds: 10));
      // ignore: avoid_print
      print('warmup resolved ${probe.length} addrs');
      await Socket.connect('ob.rosata.cn', 443,
              timeout: const Duration(seconds: 10))
          .then((s) => s.close());
      // ignore: avoid_print
      print('warmup socket connected');
    });

    test('probe succeeds with valid basic-auth credentials', () async {
      final client = buildClient();
      final err = await client.probe();
      expect(err, isNull,
          reason: 'probe failed — check network/proxy/credentials');
    });

    test('file tree returns a populated vault', () async {
      final client = buildClient();
      final nodes = await client.fetchFileTree();
      expect(nodes, isNotEmpty);
      var leaves = 0;
      void walk(FileNode n) {
        if (n.children.isEmpty) leaves++;
        for (final c in n.children) {
          walk(c);
        }
      }

      for (final n in nodes) {
        walk(n);
      }
      // ignore: avoid_print
      print('live vault: ${nodes.length} top-level nodes, $leaves leaves');
      expect(leaves, greaterThan(50),
          reason: 'vault should have hundreds of notes');
    });

    test('content search returns groups for a common term', () async {
      final client = buildClient();
      final groups = await client.search('铁路');
      // ignore: avoid_print
      print('search "铁路": ${groups.length} groups');
      expect(groups, isNotEmpty);
      for (final g in groups) {
        expect(g.notePath, isNotEmpty);
        expect(g.displayPath, isNotEmpty);
      }
      // At least one result should carry a content match excerpt.
      final withContent = groups.where((g) => !g.isFileNameMatch);
      expect(withContent, isNotEmpty);
      for (final g in withContent) {
        expect(g.excerpts, isNotEmpty,
            reason: '"${g.displayPath}" claims content match but no excerpt');
        for (final e in g.excerpts) {
          expect(e.fragments.length, greaterThanOrEqualTo(2));
        }
      }
    });

    test('note fetch returns rendered HTML for a real file', () async {
      final client = buildClient();
      // Pull a real path out of the file tree rather than hardcoding.
      final nodes = await client.fetchFileTree();
      String? firstNote;
      void find(FileNode n) {
        if (firstNote != null) return;
        if (n.type == FileNodeType.note && n.notePath != null) {
          firstNote = n.notePath;
          return;
        }
        for (final c in n.children) {
          find(c);
        }
      }

      for (final n in nodes) {
        find(n);
      }
      expect(firstNote, isNotNull,
          reason: 'no note found in vault tree');
      // ignore: avoid_print
      print('fetching note: $firstNote');
      final html = await client.fetchNoteHtml(firstNote!);
      expect(html, isNotEmpty);
      // Should be a rendered HTML fragment — at least one tag.
      expect(html, contains(RegExp(r'<(p|h[1-6]|div|span)[\s>]')));
    });

    test('rejects bad credentials with PerliteAuthException', () async {
      final bad = PerliteClient(
        baseUrl: baseUrl,
        username: user,
        password: 'wrong-password',
      );
      expect(
        () => bad.fetchFileTree(),
        throwsA(isA<PerliteAuthException>()),
      );
    });
  });
}
