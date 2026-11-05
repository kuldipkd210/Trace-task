import '../time/day.dart';
import '../time/day_calendar.dart';
import 'bucket.dart';
import 'item.dart';
import 'sections.dart';

class Ranker {
  static int _rank(Item item, DateTime now, Day today) {
    if (item.pinned) return 0;
    if (item.hasFired(now)) return 1;
    if (item.dueAt != null &&
        item.dueAt!.isAfter(now) &&
        item.dueAt!.difference(now).inSeconds <= 3600) {
      return 2;
    }
    if (item.due < today) return 3;
    if (item.dueAt != null && item.dueAt!.isAfter(now)) return 5;
    return 4;
  }

  static DateTime _sortKey(Item item) {
    return item.dueAt ?? item.createdAt;
  }

  /// Most urgent first. The first entry is what the system tray / menu bar shows.
  static List<Item> today(List<Item> items, DateTime now, DayCalendar cal) {
    final day = cal.dayOf(now);
    final openItems = Sections.openToday(items, day, cal);

    openItems.sort((a, b) {
      final rankA = _rank(a, now, day);
      final rankB = _rank(b, now, day);
      if (rankA != rankB) return rankA.compareTo(rankB);

      final keyA = _sortKey(a);
      final keyB = _sortKey(b);
      final dateComp = keyA.compareTo(keyB);
      if (dateComp != 0) return dateComp;

      return a.id.compareTo(b.id);
    });

    return openItems;
  }

  static List<Item> later(
    List<Item> items,
    Bucket bucket,
    DateTime now,
    DayCalendar cal,
  ) {
    final day = cal.dayOf(now);
    final filtered = items
        .where((i) => i.isOpen && Sections.bucketOf(i, day, cal) == bucket)
        .toList();

    filtered.sort((a, b) {
      final dueComp = a.due.compareTo(b.due);
      if (dueComp != 0) return dueComp;

      final createdComp = a.createdAt.compareTo(b.createdAt);
      if (createdComp != 0) return createdComp;

      return a.id.compareTo(b.id);
    });

    return filtered;
  }
}

