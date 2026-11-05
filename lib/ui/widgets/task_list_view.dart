import 'package:flutter/material.dart';
import '../../core/models/bucket.dart';
import '../../core/panel/panel_model.dart';
import '../../core/parser/parser.dart';
import '../theme/app_theme.dart';

class TaskListView extends StatefulWidget {
  final PanelModel model;
  final ScrollController scrollController;

  const TaskListView({
    super.key,
    required this.model,
    required this.scrollController,
  });

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  String? _hoveredRowId;
  final Map<String, GlobalKey> _itemKeys = {};

  @override
  void didUpdateWidget(covariant TaskListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureSelectedVisible();
  }

  void _ensureSelectedVisible() {
    final selectedId = widget.model.selectedID;
    if (selectedId == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _itemKeys[selectedId];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          alignment: 0.5,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showContextMenu(BuildContext context, TapDownDetails details, TaskRow row) async {
    final theme = AppTheme.of(context);
    final item = row.item;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    widget.model.selectID(row.id);

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        details.globalPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      color: theme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: theme.divider,
          width: 1,
        ),
      ),
      items: [
        PopupMenuItem(
          value: 'done',
          height: 32,
          child: Row(
            children: [
              Icon(
                item.isOpen ? Icons.check_circle_outline : Icons.replay,
                size: 16,
                color: theme.ink,
              ),
              const SizedBox(width: 8),
              Text(
                item.isOpen ? 'Mark Done (Ctrl+Enter)' : 'Mark Open',
                style: TextStyle(color: theme.ink, fontSize: 13),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'pin',
          height: 32,
          child: Row(
            children: [
              Icon(item.pinned ? Icons.push_pin : Icons.push_pin_outlined, size: 16, color: theme.ink),
              const SizedBox(width: 8),
              Text(item.pinned ? 'Unpin' : 'Pin to Top Bar (Ctrl+P)', style: TextStyle(color: theme.ink, fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          height: 32,
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 16, color: theme.ink),
              const SizedBox(width: 8),
              Text('Edit Title (Ctrl+E)', style: TextStyle(color: theme.ink, fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 8),
        PopupMenuItem(
          value: 'today',
          height: 32,
          child: Row(
            children: [
              Icon(Icons.wb_sunny_outlined, size: 16, color: theme.ink),
              const SizedBox(width: 8),
              Text('Move to Today (Ctrl+1)', style: TextStyle(color: theme.ink, fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'week',
          height: 32,
          child: Row(
            children: [
              Icon(Icons.date_range_outlined, size: 16, color: theme.ink),
              const SizedBox(width: 8),
              Text('Move to Week (Ctrl+2)', style: TextStyle(color: theme.ink, fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'month',
          height: 32,
          child: Row(
            children: [
              Icon(Icons.calendar_month_outlined, size: 16, color: theme.ink),
              const SizedBox(width: 8),
              Text('Move to Month (Ctrl+3)', style: TextStyle(color: theme.ink, fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'date',
          height: 32,
          child: Row(
            children: [
              Icon(Icons.access_time_rounded, size: 16, color: theme.ink),
              const SizedBox(width: 8),
              Text('Pick Date… (Ctrl+D)', style: TextStyle(color: theme.ink, fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 8),
        PopupMenuItem(
          value: 'delete',
          height: 32,
          child: Row(
            children: [
              const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
              const SizedBox(width: 8),
              const Text('Delete Task (Delete)', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],
          ),
        ),
      ],
    );

    if (selected == null) return;
    switch (selected) {
      case 'done':
        widget.model.markDone(row.id);
      case 'pin':
        widget.model.togglePin(row.id);
      case 'edit':
        widget.model.startEditing(row.id);
      case 'today':
        widget.model.move(row.id, Bucket.today);
      case 'week':
        widget.model.move(row.id, Bucket.week);
      case 'month':
        widget.model.move(row.id, Bucket.month);
      case 'date':
        widget.model.openDatePick();
      case 'delete':
        widget.model.delete(row.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.model,
      builder: (context, _) {
        final theme = AppTheme.of(context);
        final groups = widget.model.groups;
        final allEmpty = groups.every((g) => g.rows.isEmpty);

        if (allEmpty) {
          return Container(
            height: 60,
            alignment: Alignment.center,
            child: Text(
              'Nothing here. Type a task and press ↩',
              style: TextStyle(
                fontSize: 15,
                fontFamily: 'serif',
                fontStyle: FontStyle.italic,
                color: theme.secondary,
              ),
            ),
          );
        }

        return ListView.builder(
          controller: widget.scrollController,
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          itemCount: groups.length,
          itemBuilder: (context, groupIndex) {
            final group = groups[groupIndex];
            if (group.rows.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSectionHeader(group.bucket, group.rows.length, theme),
                ...group.rows.map((row) {
                  final key = _itemKeys.putIfAbsent(row.id, () => GlobalKey());
                  return Container(
                    key: key,
                    child: _buildRow(row, group.bucket, theme),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(Bucket bucket, int count, AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 22,
        right: 22,
        top: 10,
        bottom: 4,
      ),
      child: Text(
        '${bucket.title.toUpperCase()} ($count)',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
          color: theme.secondary.withOpacity(0.85),
        ),
      ),
    );
  }

  Widget _buildRow(TaskRow row, Bucket bucket, AppTheme theme) {
    final isSelected = widget.model.selectedID == row.id;
    final isHovered = _hoveredRowId == row.id;
    final item = row.item;

    String? lateNote;
    if (row.overdueDays > 0 && row.isStale) {
      lateNote = '${row.overdueDays}d late. Do, move or kill';
    } else if (row.overdueDays > 0) {
      lateNote = row.overdueDays == 1 ? '1 day late' : '${row.overdueDays} days late';
    } else if (row.isStale) {
      lateNote = 'Do, move or kill';
    }

    String? detail;
    if (item.dueAt != null) {
      final time = Parser.timeLabel(item.dueAt!, widget.model.cal);
      detail = bucket == Bucket.today ? time : '${Parser.dayLabel(item.due, widget.model.cal)} $time';
    } else if (bucket != Bucket.today && item.flex.name == 'none') {
      detail = Parser.dayLabel(item.due, widget.model.cal);
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredRowId = row.id),
      onExit: (_) => setState(() => _hoveredRowId = null),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.model.selectID(row.id),
        onDoubleTap: () => widget.model.startEditing(row.id),
        onSecondaryTapDown: (details) => _showContextMenu(context, details, row),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: isHovered && !isSelected
                ? (theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03))
                : Colors.transparent,
          ),
          child: Row(
            children: [
              // 1. Checkbox circle
              InkWell(
                onTap: () => widget.model.markDone(row.id),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    item.isOpen ? Icons.circle_outlined : Icons.check_circle_rounded,
                    size: 15,
                    color: theme.secondary,
                  ),
                ),
              ),

              // 2. Red pushpin dot
              if (item.pinned) ...[
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: theme.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // 3. Task Title with Yellow Highlighter when selected
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected ? theme.highlighter : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontFamily: 'serif',
                            fontWeight: FontWeight.normal,
                            color: isSelected ? theme.highlighterInk : theme.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 4. Overdue / Stale Note
              if (lateNote != null) ...[
                Text(
                  lateNote,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'serif',
                    fontStyle: FontStyle.italic,
                    color: theme.warning,
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // 5. Date / Time Label
              if (detail != null) ...[
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: theme.secondary,
                  ),
                ),
                const SizedBox(width: 6),
              ],

              // 6. Mouse action icons on hover or selection
              if (isHovered || isSelected) ...[
                Tooltip(
                  message: item.pinned ? 'Unpin' : 'Pin to Top Bar (Ctrl+P)',
                  child: InkWell(
                    onTap: () => widget.model.togglePin(row.id),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        item.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                        size: 14,
                        color: item.pinned ? theme.accent : theme.secondary,
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Edit title (Ctrl+E)',
                  child: InkWell(
                    onTap: () => widget.model.startEditing(row.id),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: theme.secondary,
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: 'Delete task (Delete)',
                  child: InkWell(
                    onTap: () => widget.model.delete(row.id),
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 14,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
