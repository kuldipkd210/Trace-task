abstract class TackClock {
  DateTime get now;
}

class SystemClock implements TackClock {
  const SystemClock();

  @override
  DateTime get now => DateTime.now();
}

class FakeClock implements TackClock {
  @override
  DateTime now;

  FakeClock(this.now);
}

/// A logical work day, not a calendar date.
/// With a 03:00 rollover, 01:00 Thursday belongs to Wednesday.
class Day implements Comparable<Day> {
  final int year;
  final int month;
  final int day;

  const Day({
    required this.year,
    required this.month,
    required this.day,
  });

  /// Days since 1970-01-01.
  /// Algorithm: Howard Hinnant's days_from_civil.
  int get ordinal {
    final y = month <= 2 ? year - 1 : year;
    final era = (y >= 0 ? y : y - 399) ~/ 400;
    final yearOfEra = y - era * 400;
    final shiftedMonth = month > 2 ? month - 3 : month + 9;
    final dayOfYear = (153 * shiftedMonth + 2) ~/ 5 + day - 1;
    final dayOfEra = yearOfEra * 365 + yearOfEra ~/ 4 - yearOfEra ~/ 100 + dayOfYear;
    return era * 146097 + dayOfEra - 719468;
  }

  factory Day.fromOrdinal(int ordinal) {
    final z = ordinal + 719468;
    final era = (z >= 0 ? z : z - 146096) ~/ 146097;
    final dayOfEra = z - era * 146097;
    final yearOfEra = (dayOfEra - dayOfEra ~/ 1460 + dayOfEra ~/ 36524 - dayOfEra ~/ 146096) ~/ 365;
    final dayOfYear = dayOfEra - (365 * yearOfEra + yearOfEra ~/ 4 - yearOfEra ~/ 100);
    final shiftedMonth = (5 * dayOfYear + 2) ~/ 153;
    final d = dayOfYear - (153 * shiftedMonth + 2) ~/ 5 + 1;
    final m = shiftedMonth < 10 ? shiftedMonth + 3 : shiftedMonth - 9;
    return Day(
      year: yearOfEra + era * 400 + (m <= 2 ? 1 : 0),
      month: m,
      day: d,
    );
  }

  factory Day.fromString(String raw) {
    final parts = raw.split('-').map(int.parse).toList();
    if (parts.length != 3) {
      throw FormatException('Invalid Day format: $raw');
    }
    return Day(year: parts[0], month: parts[1], day: parts[2]);
  }

  @override
  String toString() {
    return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  String toJson() => toString();

  factory Day.fromJson(dynamic json) {
    if (json is String) return Day.fromString(json);
    throw FormatException('Invalid JSON for Day: $json');
  }

  @override
  int compareTo(Day other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  bool operator <(Day other) => compareTo(other) < 0;
  bool operator <=(Day other) => compareTo(other) <= 0;
  bool operator >(Day other) => compareTo(other) > 0;
  bool operator >=(Day other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Day &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);
}

