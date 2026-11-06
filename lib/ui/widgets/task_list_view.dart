import 'package:flutter/material.dart';
import '../../core/models/bucket.dart';
import '../../core/models/item.dart';
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
                _buildSectionHeader(group, theme),
                ...group.rows.map((row) {
                  final key = _itemKeys.putIfAbsent(row.id, () => GlobalKey());
                  return Column(
                    key: key,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildRow(row, group, theme),
                      // Thin dividing line after every task: blue in light mode, red in dark mode
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(horizontal: 22),
                        color: theme.brightness == Brightness.dark
                            ? const Color(0xFFE63946)
                            : const Color(0xFF2563EB),
                      ),
                    ],
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(TaskGroup group, AppTheme theme) {
    return Container(
      padding: const EdgeInsets.only(
        left: 22,
        right: 22,
        top: 10,
        bottom: 4,
      ),
      color: Colors.transparent,
      child: Text(
        '${group.title.toUpperCase()} (${group.rows.length})',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
          color: theme.secondary.withOpacity(0.85),
        ),
      ),
    );
  }

  Widget _buildSnoozeBadge(Item item, AppTheme theme) {
    final now = widget.model.clock.now;
    if (item.snoozedUntil == null || !item.snoozedUntil!.isAfter(now)) {
      return const SizedBox.shrink();
    }
    final minsLeft = item.snoozedUntil!.difference(now).inMinutes.clamp(1, 120);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        '${minsLeft}m snoozed',
        style: TextStyle(
          fontSize: 13,
          fontFamily: 'monospace',
          color: theme.secondary,
        ),
      ),
    );
  }

  Widget _buildRow(TaskRow row, TaskGroup group, AppTheme theme) {
    final isSelected = widget.model.selectedID == row.id;
    final isHovered = _hoveredRowId == row.id;
    final item = row.item;
    final now = widget.model.clock.now;
    final today = widget.model.cal.dayOf(now);

    final isDelayed = item.isDelayed(now, today);

    String? lateNote;
    if (isDelayed) {
      if (row.overdueDays > 0) {
        lateNote = 'Delayed (${row.overdueDays}d)';
      } else {
        lateNote = 'Delayed';
      }
    } else if (row.isStale) {
      lateNote = 'Do, move or kill';
    }

    String? detail;
    if (item.dueAt != null) {
      final time = Parser.timeLabel(item.dueAt!, widget.model.cal);
      detail = group.bucket == Bucket.today ? time : '${Parser.dayLabel(item.due, widget.model.cal)} $time';
    } else if (item.hasExplicitDate && group.bucket != Bucket.today && item.flex.name == 'none') {
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
        child: Container(
          constraints: const BoxConstraints(minHeight: 34),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.highlighter
                : (isHovered
                    ? (theme.brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.04)
                        : Colors.black.withOpacity(0.03))
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Single Solid Dot: Centered vertically with the first line of task text
              Container(
                height: 23.25,
                padding: const EdgeInsets.only(right: 10),
                alignment: Alignment.center,
                child: InkWell(
                  onTap: () => widget.model.markDone(row.id),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: item.pinned
                          ? theme.accent
                          : (isDelayed
                              ? theme.accent
                              : (item.isOpen
                                  ? (isSelected && theme.brightness == Brightness.dark
                                      ? Colors.white.withOpacity(0.85)
                                      : theme.secondary.withOpacity(0.65))
                                  : theme.secondary.withOpacity(0.25))),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

              // Task Title (Red when delayed, 2 lines by default, expands on selection)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  child: Text(
                    item.title,
                    maxLines: isSelected ? null : 2,
                    overflow: isSelected ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontFamily: 'serif',
                      height: 1.25,
                      fontWeight: isDelayed ? FontWeight.w600 : FontWeight.normal,
                      color: isDelayed
                          ? theme.accent
                          : (isSelected ? theme.highlighterInk : theme.ink),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Trailing metadata & action icons aligned at top
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Overdue / Delayed Note (Red when delayed)
                    if (lateNote != null) ...[
                      Text(
                        lateNote,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontFamily: 'serif',
                          fontStyle: FontStyle.italic,
                          fontWeight: isDelayed ? FontWeight.bold : FontWeight.normal,
                          color: isDelayed ? theme.accent : theme.warning,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Snooze Badge if snoozed
                    _buildSnoozeBadge(item, theme),

                    // Date / Time Label (Increased font size)
                    if (detail != null) ...[
                      Text(
                        detail,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontFamily: 'monospace',
                          color: isDelayed
                              ? theme.accent
                              : (isSelected && theme.brightness == Brightness.dark
                                  ? const Color(0xFFC0C8D4)
                                  : theme.secondary),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
