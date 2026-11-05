import 'dart:math';
import '../time/day.dart';
import '../time/day_calendar.dart';
import 'bucket.dart';
import 'flex.dart';
import 'item.dart';

class Sections {
  static Bucket bucketOf(Item item, Day today, DayCalendar cal) {
    final days = cal.daysBetween(today, item.due);
    switch (item.flex) {
      case Flex.none:
        if (days <= 0) return Bucket.today;
        return (days == 1 || item.due <= cal.endOfWeek(today))
            ? Bucket.week
            : Bucket.month;
      case Flex.week:
        return days <= 2 ? Bucket.today : Bucket.week;
      case Flex.month:
        if (days <= 2) return Bucket.today;
        return days <= 7 ? Bucket.week : Bucket.month;
    }
  }

  static int overdueDays(Item item, Day today, DayCalendar cal) {
    return max(0, cal.daysBetween(item.due, today));
  }

  static bool isStale(Item item, Day today, int staleDays, DayCalendar cal) {
    return cal.daysBetween(cal.dayOf(item.plannedAt), today) >= staleDays;
  }

  static List<Item> openToday(List<Item> items, Day today, DayCalendar cal) {
    return items
        .where((item) => item.isOpen && bucketOf(item, today, cal) == Bucket.today)
        .toList();
  }
}

