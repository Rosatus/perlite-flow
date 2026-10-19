import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:perlite_flow/services/perlite_client.dart';
import 'package:perlite_flow/models/file_node.dart';

void main() {
  group('PerliteClient tree parsing', () {
    test('parses folders, notes, canvas, attachments', () {
      final client = PerliteClient(baseUrl: 'https://x.test');
      const html = '''
      <div class="nav-files-container">
        <div class="tree-item nav-folder is-collapsed">
          <div class="nav-folder-title-content">docs</div>
          <div class="nav-folder-children">
            <div class="tree-item nav-file">
              <div class="nav-file-title perlite-link" onclick="getContent('/docs/Note%20One')">
                <div class="nav-file-title-content">Note One</div>
              </div>
            </div>
            <div class="tree-item nav-file">
              <div class="nav-file-title perlite-link" onclick="getContent('/docs/Board')">
                <div class="nav-file-title-content">Board</div>
                <div class="nav-file-tag">canvas</div>
              </div>
            </div>
          </div>
        </div>
        <div class="tree-item nav-file">
          <a class="nav-file-title perlite-download-link" href="/files/spec.pdf" download="spec.pdf">
            <div class="nav-file-title-content">spec</div>
            <div class="nav-file-tag">pdf</div>
          </a>
        </div>
      </div>
      ''';
      final doc = html_parser.parse(html);
      final nodes = client.parseTreeForTest(doc);
      expect(nodes.length, 2);

      // Folder with children.
      expect(nodes[0].type, FileNodeType.folder);
      expect(nodes[0].name, 'docs');
      expect(nodes[0].children.length, 2);

      // Markdown note.
      expect(nodes[0].children[0].type, FileNodeType.note);
      expect(nodes[0].children[0].notePath, '/docs/Note One');

      // Canvas file.
      expect(nodes[0].children[1].type, FileNodeType.canvas);

      // Attachment.
      expect(nodes[1].type, FileNodeType.attachment);
      expect(nodes[1].downloadUrl, '/files/spec.pdf');
    });
  });

  group('PerliteClient search result parsing', () {
    test('distinguishes filename matches from content matches', () {
      final client = PerliteClient(baseUrl: 'https://x.test');
      const html = '''
      <div class="tree-item search-result">
        <div class="tree-item-self search-result-file-title is-clickable">
          <div class="tree-item-inner" onclick="getContent('/docs/note')">docs / note</div>
        </div>
        <div class="search-result-file-matches" style="display:none">
          <div class="search-result-file-match"><span>hello <span class="search-result-file-matched-text">world</span></span></div>
        </div>
      </div>
      <div class="tree-item search-result">
        <div class="tree-item-self search-result-file-title is-clickable">
          <div class="tree-item-inner" onclick="getContent('/other')">other</div>
        </div>
      </div>
      ''';
      final groups = client.parseSearchResultsForTest(html);
      expect(groups.length, 2);
      expect(groups[0].notePath, '/docs/note');
      expect(groups[0].isFileNameMatch, false);
      expect(groups[0].matches.single, contains('world'));
      // Excerpt should split into alternating plain/match fragments.
      final ex = groups[0].excerpts.single;
      // fragments[0] = "hello ", fragments[1] = "world" (highlighted).
      expect(ex.fragments.length, greaterThanOrEqualTo(2));
      expect(ex.fragments[0], contains('hello'));
      expect(ex.fragments[1], 'world');
      expect(groups[1].isFileNameMatch, true);
    });
  });
}
