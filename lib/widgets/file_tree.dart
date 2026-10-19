import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../models/file_node.dart';

/// Recursive file tree for the navigation drawer.
class FileTreeView extends StatelessWidget {
  final List<FileNode> nodes;
  final void Function(FileNode node) onOpenNote;
  final void Function(FileNode node) onOpenAttachment;

  const FileTreeView({
    super.key,
    required this.nodes,
    required this.onOpenNote,
    required this.onOpenAttachment,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [for (final n in nodes) _build(context, n, 0)],
    );
  }

  Widget _build(BuildContext context, FileNode node, int depth) {
    if (node.isFolder) {
      return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const Icon(Symbols.folder, size: 20),
          title: Text(node.name, overflow: TextOverflow.ellipsis),
          tilePadding: EdgeInsets.only(left: 16 + depth * 12, right: 12),
          childrenPadding: EdgeInsets.zero,
          children: [
            for (final c in node.children) _build(context, c, depth + 1),
          ],
        ),
      );
    }

    final icon = switch (node.type) {
      FileNodeType.note => Symbols.description,
      FileNodeType.canvas => Symbols.dashboard_customize,
      FileNodeType.attachment => Symbols.attach_file,
      FileNodeType.folder => Symbols.folder,
    };

    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20),
      title: Tooltip(
        message: node.name,
        waitDuration: const Duration(milliseconds: 600),
        child: Text(node.name, overflow: TextOverflow.ellipsis),
      ),
      contentPadding: EdgeInsets.only(left: 16 + depth * 12, right: 12),
      trailing: node.type == FileNodeType.canvas
          ? const _Tag('canvas')
          : null,
      onTap: () {
        if (node.type == FileNodeType.attachment) {
          onOpenAttachment(node);
        } else if (node.notePath != null) {
          onOpenNote(node);
        }
      },
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: cs.onSecondaryContainer),
      ),
    );
  }
}
