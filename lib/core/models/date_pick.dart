import '../time/day.dart';
import '../time/day_calendar.dart';

class ResolvedDatePick {
  final Day due;
  final DateTime? dueAt;

  const ResolvedDatePick({required this.due, this.dueAt});
}

class DatePick {
  final DateTime date;
  final bool hasTime;

  const DatePick({required this.date, required this.hasTime});

  ResolvedDatePick resolve(DayCalendar cal) {
    if (hasTime) {
      return ResolvedDatePick(due: cal.dayOf(date), dueAt: date);
    }
    // The picker shows calendar dates.
    final local = date.toLocal();
    return ResolvedDatePick(
      due: Day(year: local.year, month: local.month, day: local.day),
      dueAt: null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DatePick &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          hasTime == other.hasTime;

  @override
  int get hashCode => Object.hash(date, hasTime);
}

