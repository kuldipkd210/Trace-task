import 'package:flutter/material.dart';
import '../../core/models/bucket.dart';
import '../../core/panel/panel_model.dart';
import '../../core/parser/parser.dart';
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
    final allEmpty = groups.every((g) => g.rows.isEmpty);

    if (allEmpty) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        child: Text(
          'Nothing here. Type a task and press ↩',
          style: TextStyle(
            fontSize: theme.style == ThemeStyle.card ? 15 : 13,
            fontFamily: theme.style == ThemeStyle.card ? 'serif' : null,
            fontStyle: theme.style == ThemeStyle.card ? FontStyle.italic : FontStyle.normal,
            color: theme.secondary,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.only(
        top: theme.style == ThemeStyle.glass ? 4 : 2,
        bottom: 8,
      ),
      itemCount: groups.length,
      itemBuilder: (context, groupIndex) {
        final group = groups[groupIndex];
        if (group.rows.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Section Header
            _buildSectionHeader(group.bucket, group.rows.length, theme),

            // Rows
            ...group.rows.map((row) => _buildRow(row, group.bucket, theme)),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(Bucket bucket, int count, AppTheme theme) {
    final isCard = theme.style == ThemeStyle.card;
    final inset = isCard ? 22.0 : 18.0;

    return Padding(
      padding: EdgeInsets.only(
        left: inset,
        right: inset,
        top: 10,
        bottom: 4,
      ),
      child: Text(
        '${bucket.title.toUpperCase()} ($count)',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
          color: theme.secondary.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildRow(TaskRow row, Bucket bucket, AppTheme theme) {
    final isSelected = model.selectedID == row.id;
    final isCard = theme.style == ThemeStyle.card;

    return InkWell(
      onTap: () => model.selectID(row.id),
      onDoubleTap: () => model.startEditing(row.id),
      child: isCard
          ? _buildCardRow(row, isSelected, bucket, theme)
          : _buildGlassRow(row, isSelected, bucket, theme),
    );
  }

  // Exact reproduction of Tack's Native Glass row
  Widget _buildGlassRow(TaskRow row, bool isSelected, Bucket bucket, AppTheme theme) {
    final item = row.item;
    final ink = isSelected ? Colors.white : theme.ink;
    final quiet = isSelected ? Colors.white.withOpacity(0.8) : theme.secondary;
    final warning = isSelected ? Colors.white : theme.warning;

    String? detail;
    if (item.dueAt != null) {
      final time = Parser.timeLabel(item.dueAt!, model.cal);
      detail = bucket == Bucket.today ? time : '${Parser.dayLabel(item.due, model.cal)} $time';
    } else if (bucket != Bucket.today && item.flex.name == 'none') {
      detail = Parser.dayLabel(item.due, model.cal);
    }

    return Container(
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isSelected ? theme.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (item.pinned) ...[
            Icon(Icons.push_pin, size: 11, color: ink),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: ink,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (row.isStale) ...[
            Text(
              'do, move or kill',
              style: TextStyle(fontSize: 12, color: warning),
            ),
            const SizedBox(width: 6),
          ],
          if (row.overdueDays > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : const Color(0xFFFF9F0A).withOpacity(0.2),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                '${row.overdueDays}d',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: warning,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (detail != null) ...[
            Text(
              detail,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: quiet,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Exact reproduction of Tack's Index Card row
  Widget _buildCardRow(TaskRow row, bool isSelected, Bucket bucket, AppTheme theme) {
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
      final time = Parser.timeLabel(item.dueAt!, model.cal);
      detail = bucket == Bucket.today ? time : '${Parser.dayLabel(item.due, model.cal)} $time';
    } else if (bucket != Bucket.today && item.flex.name == 'none') {
      detail = Parser.dayLabel(item.due, model.cal);
    }

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          // Red pushpin circle
          if (item.pinned) ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: theme.accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Title with yellow highlighter when selected
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
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
                        color: theme.ink,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

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

          if (detail != null) ...[
            Text(
              detail,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Color(0xFF3B424A),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
