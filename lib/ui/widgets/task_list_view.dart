import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/panel/panel_model.dart';
import '../theme/app_theme.dart';

class TaskListView extends StatelessWidget {
  final PanelModel model;
  final ScrollController scrollController;

  const TaskListView({
    super.key,
    required this.model,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final groups = model.groups;

    final allRowsCount = groups.fold<int>(0, (sum, g) => sum + g.rows.length);
    if (allRowsCount == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'No tasks. You are all caught up!',
            style: TextStyle(
              fontSize: 13,
              color: theme.secondary.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: groups.length,
      itemBuilder: (context, groupIndex) {
        final group = groups[groupIndex];
        if (group.rows.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bucket Header
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4, left: 4),
              child: Row(
                children: [
                  Text(
                    group.bucket.title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: theme.secondary.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.sunken,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${group.rows.length}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Rows
            ...group.rows.map((row) => _buildTaskRow(context, row, theme)),
          ],
        );
      },
    );
  }

  Widget _buildTaskRow(BuildContext context, TaskRow row, AppTheme theme) {
    final isSelected = model.selectedID == row.id;
    final item = row.item;
    final now = model.clock.now;
    final hasFired = item.hasFired(now);

    return InkWell(
      onTap: () => model.selectID(row.id),
      onDoubleTap: () => model.startEditing(row.id),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (theme.style == ThemeStyle.card
                  ? theme.highlighter.withOpacity(0.6)
                  : theme.accent.withOpacity(0.2))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected
              ? Border.all(color: theme.accent.withOpacity(0.4), width: 1)
              : null,
        ),
        child: Row(
          children: [
            // Done check circle
            InkWell(
              onTap: () => model.store.markDone(row.id),
              child: Icon(
                Icons.circle_outlined,
                size: 16,
                color: theme.secondary,
              ),
            ),
            const SizedBox(width: 8),

            // Pinned Icon
            if (item.pinned) ...[
              Icon(
                Icons.push_pin_rounded,
                size: 14,
                color: theme.accent,
              ),
              const SizedBox(width: 4),
            ],

            // Title
            Expanded(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: theme.ink,
                ),
              ),
            ),

            // Overdue or Stale Badges
            if (row.overdueDays > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${row.overdueDays}d late',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: theme.warning,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ] else if (row.isStale) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'stale',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: theme.secondary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],

            // Due Time / Date label
            if (item.dueAt != null) ...[
              Text(
                DateFormat('h:mm a').format(item.dueAt!.toLocal()),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: hasFired ? theme.warning : theme.secondary,
                ),
              ),
              const SizedBox(width: 6),
            ],

            // Action buttons on selection
            if (isSelected) ...[
              InkWell(
                onTap: () => model.togglePinSelected(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Icon(
                    item.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                    size: 14,
                    color: item.pinned ? theme.accent : theme.secondary,
                  ),
                ),
              ),
              InkWell(
                onTap: () => model.deleteSelected(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 14,
                    color: theme.secondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
