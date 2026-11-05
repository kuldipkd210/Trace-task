import '../time/day_calendar.dart';
import 'item.dart';

enum TrayTone { normal, amber, red }

class MenuBarState {
  static const int maxLength = 26;

  final String title;
  final TrayTone tone;

  const MenuBarState({required this.title, required this.tone});

  static Item? selectTopPriorityTask(List<Item> openItems, DateTime now, DayCalendar cal) {
    if (openItems.isEmpty) return null;

    final today = cal.dayOf(now);

    DateTime effectiveTime(Item item) {
      if (item.dueAt != null) return item.dueAt!;
      return cal.dateOn(item.due, cal.rolloverHour);
    }

    // 1. High priority: Tasks with date and time mentioned (earliest time first)
    final timedOrDatedTasks = openItems.where((i) => i.dueAt != null || i.due > today).toList();
    if (timedOrDatedTasks.isNotEmpty) {
      timedOrDatedTasks.sort((a, b) {
        final comp = effectiveTime(a).compareTo(effectiveTime(b));
        if (comp != 0) return comp;
        return a.createdAt.compareTo(b.createdAt);
      });
      return timedOrDatedTasks.first;
    }

    // 2. If no date and time mentioned, show pinned tasks (newest pinned first)
    final pinnedTasks = openItems.where((i) => i.pinned).toList();
    if (pinnedTasks.isNotEmpty) {
      pinnedTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return pinnedTasks.first;
    }

    // 3. If no time mentioned and no pinned task, show the last task added
    final sortedByRecent = List<Item>.from(openItems);
    sortedByRecent.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedByRecent.first;
  }

  static MenuBarState compute(
    List<Item> items,
    DateTime now,
    DayCalendar cal, {
    bool quiet = false,
  }) {
    final openItems = items.where((i) => i.isOpen).toList();
    if (openItems.isEmpty) {
      return const MenuBarState(title: '✓', tone: TrayTone.normal);
    }

    final today = cal.dayOf(now);
    final TrayTone tone;
    if (openItems.any((item) => item.hasFired(now) || item.due < today)) {
      tone = TrayTone.red;
    } else if (openItems.any((item) =>
        item.dueAt != null &&
        item.dueAt!.isAfter(now) &&
        item.dueAt!.difference(now).inMinutes <= 60)) {
      tone = TrayTone.amber;
    } else {
      tone = TrayTone.normal;
    }

    if (quiet) {
      return MenuBarState(title: '${openItems.length}', tone: tone);
    }

    final topTask = selectTopPriorityTask(openItems, now, cal);
    if (topTask == null) {
      return MenuBarState(title: '${openItems.length}', tone: tone);
    }

    final prefix = '${openItems.length} · ';
    final room = maxLength - prefix.length;
    final name = topTask.title.length > room
        ? '${topTask.title.substring(0, room - 1)}…'
        : topTask.title;

    return MenuBarState(title: '$prefix$name', tone: tone);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuBarState &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          tone == other.tone;

  @override
  int get hashCode => Object.hash(title, tone);
}
