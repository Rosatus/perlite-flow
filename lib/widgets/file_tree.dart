import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../models/file_node.dart';

/// Recursive file tree for the navigation drawer.
///
/// Renders each level with a vertical indent guide (a 1 px hairline
/// running the full height of the children block) — the convention
/// used by VS Code, Obsidian and Apple Notes to keep deep nesting
/// readable. Folder rows show a leading chevron that rotates on
/// expansion; leaf rows align their icon with the chevron column so
/// hierarchy reads at a glance.
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
      children: [
        for (final n in nodes)
          _buildNode(context, n, depth: 0),
      ],
    );
  }

  /// Shared dispatcher for one node — folder tiles also use it via
  /// `_ChildNode` so the type switch lives in exactly one place.
  static Widget _buildNode(
    BuildContext context,
    FileNode node, {
    required int depth,
    void Function(FileNode)? onOpenNote,
    void Function(FileNode)? onOpenAttachment,
  }) {
    final cs = Theme.of(context).colorScheme;

    if (node.isFolder) {
      return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: _FolderTile(
          node: node,
          depth: depth,
          onOpenNote: onOpenNote ?? (_) {},
          onOpenAttachment: onOpenAttachment ?? (_) {},
          guideColor: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      );
    }

    final icon = switch (node.type) {
      FileNodeType.note => Symbols.description,
      FileNodeType.canvas => Symbols.dashboard_customize,
      FileNodeType.attachment => Symbols.attach_file,
      FileNodeType.folder => Symbols.folder,
    };

    return _LeafTile(
      icon: icon,
      tag: node.type == FileNodeType.canvas ? 'canvas' : null,
      title: node.name,
      depth: depth,
      onTap: () {
        if (node.type == FileNodeType.attachment) {
          onOpenAttachment?.call(node);
        } else if (node.notePath != null) {
          onOpenNote?.call(node);
        }
      },
    );
  }

}

/// Folder row + collapsible children with per-level indent guides.
class _FolderTile extends StatefulWidget {
  final FileNode node;
  final int depth;
  final void Function(FileNode) onOpenNote;
  final void Function(FileNode) onOpenAttachment;
  final Color guideColor;

  const _FolderTile({
    required this.node,
    required this.depth,
    required this.onOpenNote,
    required this.onOpenAttachment,
    required this.guideColor,
  });

  @override
  State<_FolderTile> createState() => _FolderTileState();
}

class _FolderTileState extends State<_FolderTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: EdgeInsets.only(
              left: _indent(widget.depth),
              right: 12,
            ),
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: Icon(
                      Symbols.chevron_right,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Symbols.folder, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.node.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _Guides(
            depth: widget.depth,
            color: widget.guideColor,
            child: Column(
              children: [
                for (final c in widget.node.children)
                  _ChildNode(
                    node: c,
                    depth: widget.depth + 1,
                    onOpenNote: widget.onOpenNote,
                    onOpenAttachment: widget.onOpenAttachment,
                  ),
              ],
            ),
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 160),
        ),
      ],
    );
  }

  static double _indent(int depth) => 12 + depth * 16.0;
}

/// Leaf (note / attachment / canvas) row.
class _LeafTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? tag;
  final int depth;
  final VoidCallback onTap;

  const _LeafTile({
    required this.icon,
    required this.title,
    required this.depth,
    required this.onTap,
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(
          // Leaves align their icon with the folder's folder-icon column —
          // i.e. chevron width + gap is added so icons form a clean rail.
          left: _FolderTileState._indent(depth) + 24,
          right: 12,
        ),
        child: SizedBox(
          height: 40,
          child: Row(
            children: [
              Icon(icon, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Tooltip(
                  message: title,
                  waitDuration: const Duration(milliseconds: 600),
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              if (tag != null) _Tag(tag!),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints a single vertical guide at the chevron column of the parent
/// folder. Nested children pick up additional guides from their own
/// `_Guides` ancestors, so each layer only ever draws one line — the
/// parent's. This keeps x-positions exact and avoids a single
/// painter trying to reproduce every ancestor's geometry.
class _Guides extends StatelessWidget {
  final int depth;
  final Color color;
  final Widget child;

  const _Guides({
    required this.depth,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _GuidePainter(depth: depth, color: color),
          ),
        ),
        child,
      ],
    );
  }
}

class _GuidePainter extends CustomPainter {
  final int depth;
  final Color color;
  const _GuidePainter({required this.depth, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    // One guide per _Guides wrapper — at the x-centre of the parent
    // folder's chevron so the line reads as "hanging" from it.
    final x = _FolderTileState._indent(depth) + 9; // centre of 18px icon
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
  }

  @override
  bool shouldRepaint(_GuidePainter old) =>
      old.depth != depth || old.color != color;
}

/// Bridge that lets `_FolderTile` reuse the same `_build` dispatch
/// as the parent `FileTreeView` without recreating the widget class.
class _ChildNode extends StatelessWidget {
  final FileNode node;
  final int depth;
  final void Function(FileNode) onOpenNote;
  final void Function(FileNode) onOpenAttachment;

  const _ChildNode({
    required this.node,
    required this.depth,
    required this.onOpenNote,
    required this.onOpenAttachment,
  });

  @override
  Widget build(BuildContext context) {
    // Re-use the FileTreeView dispatcher so we don't fork _build logic.
    return FileTreeView._buildNode(
      context,
      node,
      depth: depth,
      onOpenNote: onOpenNote,
      onOpenAttachment: onOpenAttachment,
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
