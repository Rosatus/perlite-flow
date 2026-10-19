enum FileNodeType { folder, note, canvas, attachment }

class FileNode {
  final String name;
  final FileNodeType type;

  /// Vault-relative path used with `content.php?mdfile=` (e.g. `/docs/Note`).
  /// Null for folders and download-only attachments.
  final String? notePath;

  /// Absolute-ish URL path for direct downloads served by the web server.
  final String? downloadUrl;

  final List<FileNode> children;

  const FileNode({
    required this.name,
    required this.type,
    this.notePath,
    this.downloadUrl,
    this.children = const [],
  });

  bool get isFolder => type == FileNodeType.folder;
}
