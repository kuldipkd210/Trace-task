import 'day.dart';

class DayCalendar {
  final int rolloverHour;

  const DayCalendar({this.rolloverHour = 3});

  /// The logical Day for a given local DateTime.
  /// If the hour is before rolloverHour (e.g. 01:00 AM with rollover 03:00),
  /// it belongs to the previous day.
  Day dayOf(DateTime date) {
    final local = date.toLocal();
    final d = Day(year: local.year, month: local.month, day: local.day);
    return local.hour < rolloverHour ? adding(-1, d) : d;
  }

  Day adding(int days, Day day) {
    return Day.fromOrdinal(day.ordinal + days);
  }

  int daysBetween(Day from, Day to) {
    return to.ordinal - from.ordinal;
  }

  /// 1 = Sunday, 2 = Monday, ..., 7 = Saturday.
  /// (Matches Swift's Calendar.current.component(.weekday, from:))
  int weekdayOf(Day day) {
    // 1970-01-01 (ordinal 0) was a Thursday (5).
    return ((day.ordinal + 4) % 7 + 7) % 7 + 1;
  }

  /// Weeks run Monday to Sunday.
  /// Returns the Sunday ending the current week.
  Day endOfWeek(Day day) {
    final w = weekdayOf(day);
    // If w == 1 (Sunday), offset is 0.
    // If w == 2 (Monday), offset is 6.
    // In general: (8 - w) % 7
    return adding((8 - w) % 7, day);
  }

  Day endOfMonth(Day day) {
    final next = day.month == 12
        ? Day(year: day.year + 1, month: 1, day: 1)
        : Day(year: day.year, month: day.month + 1, day: 1);
    return adding(-1, next);
  }

  /// Clock time on a logical day.
  /// Hours before rolloverHour fall on the next calendar date.
  DateTime dateOn(Day day, int hour, [int minute = 0]) {
    final calendarDay = hour < rolloverHour ? adding(1, day) : day;
    return DateTime(calendarDay.year, calendarDay.month, calendarDay.day, hour, minute);
  }

  /// Returns null for invalid dates like Feb 30.
  Day? validDay(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1) return null;
    final candidate = Day(year: year, month: month, day: day);
    return Day.fromOrdinal(candidate.ordinal) == candidate ? candidate : null;
  }
}

