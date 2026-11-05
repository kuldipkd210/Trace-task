import '../time/day_calendar.dart';
import 'item.dart';
import 'ranker.dart';

enum TrayTone { normal, amber, red }

class MenuBarState {
  static const int maxLength = 24;

  final String title;
  final TrayTone tone;

  const MenuBarState({required this.title, required this.tone});

  static MenuBarState compute(
    List<Item> items,
    DateTime now,
    DayCalendar cal, {
    bool quiet = false,
  }) {
    final todayItems = Ranker.today(items, now, cal);
    if (todayItems.isEmpty) {
      return const MenuBarState(title: '✓', tone: TrayTone.normal);
    }

    final day = cal.dayOf(now);
    final TrayTone tone;
    if (todayItems.any((item) => item.hasFired(now))) {
      tone = TrayTone.red;
    } else if (todayItems.any((item) => item.due < day)) {
      tone = TrayTone.amber;
    } else {
      tone = TrayTone.normal;
    }

    if (quiet) {
      return MenuBarState(title: '${todayItems.length}', tone: tone);
    }

    final top = todayItems.first;
    final prefix = '${todayItems.length} · ';
    final room = maxLength - prefix.length;
    final name = top.title.length > room
        ? '${top.title.substring(0, room - 1)}…'
        : top.title;

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

