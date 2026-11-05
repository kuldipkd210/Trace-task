import 'package:intl/intl.dart';
import '../models/flex.dart';
import '../time/day.dart';
import '../time/day_calendar.dart';

class ParsedTask {
  final String title;
  final Day due;
  final DateTime? dueAt;
  final Flex flex;
  final bool hasDate;

  const ParsedTask({
    required this.title,
    required this.due,
    this.dueAt,
    this.flex = Flex.none,
    required this.hasDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedTask &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          due == other.due &&
          dueAt == other.dueAt &&
          flex == other.flex &&
          hasDate == other.hasDate;

  @override
  int get hashCode => Object.hash(title, due, dueAt, flex, hasDate);
}

sealed class _DateSpec {}

class _DaySpec extends _DateSpec {
  final Day day;
  _DaySpec(this.day);
}

class _FlexSpec extends _DateSpec {
  final Flex flex;
  _FlexSpec(this.flex);
}

sealed class _Relative {}

class _RelMinutes extends _Relative {
  final int minutes;
  _RelMinutes(this.minutes);
}

class _RelDays extends _Relative {
  final int days;
  _RelDays(this.days);
}

class Parser {
  static const Map<String, int> weekdays = {
    'sun': 1, 'sunday': 1,
    'mon': 2, 'monday': 2,
    'tue': 3, 'tues': 3, 'tuesday': 3,
    'wed': 4, 'wednesday': 4,
    'thu': 5, 'thur': 5, 'thurs': 5, 'thursday': 5,
    'fri': 6, 'friday': 6,
    'sat': 7, 'saturday': 7,
  };

  static const Map<String, int> months = {
    'jan': 1, 'january': 1,
    'feb': 2, 'february': 2,
    'mar': 3, 'march': 3,
    'apr': 4, 'april': 4,
    'may': 5,
    'jun': 6, 'june': 6,
    'jul': 7, 'july': 7,
    'aug': 8, 'august': 8,
    'sep': 9, 'sept': 9, 'september': 9,
    'oct': 10, 'october': 10,
    'nov': 11, 'november': 11,
    'dec': 12, 'december': 12,
  };

  static ParsedTask parse(String raw, DateTime now, DayCalendar cal) {
    final today = cal.dayOf(now);
    var text = raw.trim();

    // A trailing "." turns parsing off, so "call mon." stays literal.
    if (text.endsWith('.')) {
      text = text.substring(0, text.length - 1).trimRight();
      return ParsedTask(
        title: text,
        due: today,
        dueAt: null,
        flex: Flex.none,
        hasDate: false,
      );
    }

    final tokens = text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    ({int hour, int minute})? time;
    _DateSpec? date;
    _Relative? relative;

    // Up to two passes, so both "fri 3pm" and "3pm fri" work.
    for (var pass = 0; pass < 2 && relative == null; pass++) {
      if (time == null && date == null) {
        final relMatch = _matchRelative(tokens);
        if (relMatch != null && tokens.length > relMatch.$2) {
          relative = relMatch.$1;
          tokens.removeRange(tokens.length - relMatch.$2, tokens.length);
          break;
        }
      }

      if (time == null) {
        final timeMatch = _matchTime(tokens);
        if (timeMatch != null && tokens.length > timeMatch.$2) {
          time = timeMatch.$1;
          tokens.removeRange(tokens.length - timeMatch.$2, tokens.length);
          _dropConnector('at', tokens);
        }
      }

      if (date == null) {
        final dateMatch = _matchDate(tokens, today, cal);
        if (dateMatch != null && tokens.length > dateMatch.$2) {
          date = dateMatch.$1;
          tokens.removeRange(tokens.length - dateMatch.$2, tokens.length);
          if (tokens.length >= 2 &&
              tokens[tokens.length - 2].toLowerCase() == 'on' &&
              tokens[tokens.length - 1].toLowerCase() == 'the') {
            tokens.removeLast();
          }
          _dropConnector('on', tokens);
        }
      }
    }

    final title = tokens.join(' ');

    if (relative != null) {
      if (relative is _RelMinutes) {
        final at = now.add(Duration(minutes: relative.minutes));
        return ParsedTask(
          title: title,
          due: cal.dayOf(at),
          dueAt: at,
          flex: Flex.none,
          hasDate: true,
        );
      } else if (relative is _RelDays) {
        return ParsedTask(
          title: title,
          due: cal.adding(relative.days, today),
          dueAt: null,
          flex: Flex.none,
          hasDate: true,
        );
      }
    }

    if (date == null && time == null) {
      return ParsedTask(
        title: title,
        due: today,
        dueAt: null,
        flex: Flex.none,
        hasDate: false,
      );
    }

    if (date == null && time != null) {
      final at = _nextOccurrence(time.hour, time.minute, now, cal);
      return ParsedTask(
        title: title,
        due: cal.dayOf(at),
        dueAt: at,
        flex: Flex.none,
        hasDate: true,
      );
    }

    if (date is _DaySpec && time == null) {
      return ParsedTask(
        title: title,
        due: date.day,
        dueAt: null,
        flex: Flex.none,
        hasDate: true,
      );
    }

    if (date is _DaySpec && time != null) {
      final at = cal.dateOn(date.day, time.hour, time.minute);
      return ParsedTask(
        title: title,
        due: date.day,
        dueAt: at,
        flex: Flex.none,
        hasDate: true,
      );
    }

    if (date is _FlexSpec && time == null) {
      return ParsedTask(
        title: title,
        due: flexDue(date.flex, today, cal),
        dueAt: null,
        flex: date.flex,
        hasDate: true,
      );
    }

    if (date is _FlexSpec && time != null) {
      final d = flexDue(date.flex, today, cal);
      final at = cal.dateOn(d, time.hour, time.minute);
      return ParsedTask(
        title: title,
        due: d,
        dueAt: at,
        flex: Flex.none,
        hasDate: true,
      );
    }

    return ParsedTask(
      title: title,
      due: today,
      dueAt: null,
      flex: Flex.none,
      hasDate: false,
    );
  }

  static Day flexDue(Flex flex, Day today, DayCalendar cal) {
    switch (flex) {
      case Flex.none:
        return today;
      case Flex.week:
        final end = cal.endOfWeek(today);
        return cal.daysBetween(today, end) <= 2 ? cal.adding(7, end) : end;
      case Flex.month:
        final end = cal.endOfMonth(today);
        return cal.daysBetween(today, end) <= 7
            ? cal.endOfMonth(cal.adding(1, end))
            : end;
    }
  }

  static void _dropConnector(String word, List<String> tokens) {
    if (tokens.isNotEmpty && tokens.last.toLowerCase() == word) {
      tokens.removeLast();
    }
  }

  static (_Relative, int)? _matchRelative(List<String> tokens) {
    if (tokens.length >= 3 && tokens[tokens.length - 3].toLowerCase() == 'in') {
      final amount = tokens[tokens.length - 2].toLowerCase();
      final number = (amount == 'a' || amount == 'an') ? 1 : int.tryParse(amount);
      if (number != null && number >= 1 && number <= 100000) {
        switch (tokens.last.toLowerCase()) {
          case 'minute':
          case 'minutes':
          case 'min':
          case 'mins':
            return (_RelMinutes(number), 3);
          case 'hour':
          case 'hours':
          case 'hr':
          case 'hrs':
            return (_RelMinutes(number * 60), 3);
          case 'day':
          case 'days':
            return (_RelDays(number), 3);
          case 'week':
          case 'weeks':
            return (_RelDays(number * 7), 3);
        }
      }
    }

    if (tokens.length >= 2 && tokens[tokens.length - 2].toLowerCase() == 'in') {
      final val = tokens.last.toLowerCase();
      if (val.length >= 2) {
        final unit = val[val.length - 1];
        final numPart = int.tryParse(val.substring(0, val.length - 1));
        if (numPart != null && numPart >= 1 && numPart <= 100000) {
          switch (unit) {
            case 'm':
              return (_RelMinutes(numPart), 2);
            case 'h':
              return (_RelMinutes(numPart * 60), 2);
            case 'd':
              return (_RelDays(numPart), 2);
          }
        }
      }
    }

    return null;
  }

  static (({int hour, int minute}), int)? _matchTime(List<String> tokens) {
    if (tokens.isEmpty) return null;
    final last = tokens.last.toLowerCase();

    if ((last == 'am' || last == 'pm') && tokens.length >= 2) {
      final prev = tokens[tokens.length - 2].toLowerCase();
      final clock = _parseClock(prev + last);
      if (clock != null) return (clock, 2);
    }

    final clock = _parseClock(last);
    if (clock != null) return (clock, 1);

    return null;
  }

  static ({int hour, int minute})? _parseClock(String raw) {
    var body = raw;
    String? meridiem;
    if (body.endsWith('am') || body.endsWith('pm')) {
      meridiem = body.substring(body.length - 2);
      body = body.substring(0, body.length - 2);
    }

    // "1030 am" -> "10:30"
    if (meridiem != null &&
        body.length >= 3 &&
        body.length <= 4 &&
        body.codeUnits.every((c) => c >= 48 && c <= 57)) {
      body = '${body.substring(0, body.length - 2)}:${body.substring(body.length - 2)}';
    }

    final parts = body.split(':');
    if (parts.length > 2) return null;
    final hour = int.tryParse(parts[0]);
    if (hour == null) return null;

    final int minute;
    if (parts.length == 2) {
      if (parts[1].length != 2) return null;
      final val = int.tryParse(parts[1]);
      if (val == null || val < 0 || val >= 60) return null;
      minute = val;
    } else {
      if (meridiem == null) return null;
      minute = 0;
    }

    if (meridiem == null) {
      return (hour >= 0 && hour < 24) ? (hour: hour, minute: minute) : null;
    }

    if (hour < 1 || hour > 12) return null;
    final base = hour % 12;
    return (
      hour: meridiem == 'pm' ? base + 12 : base,
      minute: minute,
    );
  }

  static (_DateSpec, int)? _matchDate(List<String> tokens, Day today, DayCalendar cal) {
    if (tokens.isEmpty) return null;
    final last = tokens.last.toLowerCase();

    // "next week", "next month", "next fri"
    if (tokens.length >= 2 && tokens[tokens.length - 2].toLowerCase() == 'next') {
      final nextMonday = cal.adding(1, cal.endOfWeek(today));
      switch (last) {
        case 'week':
        case 'wk':
          return (_DaySpec(nextMonday), 2);
        case 'month':
          return (_DaySpec(cal.adding(1, cal.endOfMonth(today))), 2);
      }
      final weekday = weekdays[last];
      if (weekday != null) {
        return (_DaySpec(cal.adding((weekday + 5) % 7, nextMonday)), 2);
      }
    }

    switch (last) {
      case 'today':
      case 'tod':
        return (_DaySpec(today), 1);
      case 'tomorrow':
      case 'tmr':
      case 'tmrw':
        return (_DaySpec(cal.adding(1, today)), 1);
      case 'week':
      case 'wk':
        return (_FlexSpec(Flex.week), 1);
      case 'month':
        return (_FlexSpec(Flex.month), 1);
    }

    if (tokens.length >= 2) {
      final prev = tokens[tokens.length - 2].toLowerCase();
      final monthPrev = months[prev];
      final dayLast = _dayNumber(last);
      if (monthPrev != null && dayLast != null) {
        final d = _resolve(monthPrev, dayLast, today, cal);
        if (d != null) return (_DaySpec(d), 2);
      }

      final monthLast = months[last];
      final dayPrev = _dayNumber(prev);
      if (monthLast != null && dayPrev != null) {
        final d = _resolve(monthLast, dayPrev, today, cal);
        if (d != null) return (_DaySpec(d), 2);
      }

      // "12th of november"
      if (tokens.length >= 3 && prev == 'of') {
        final dayFirst = _dayNumber(tokens[tokens.length - 3].toLowerCase());
        if (monthLast != null && dayFirst != null) {
          final d = _resolve(monthLast, dayFirst, today, cal);
          if (d != null) return (_DaySpec(d), 3);
        }
      }
    }

    // "11/12" is month/day
    final numeric = last.split('/');
    if (numeric.length == 2) {
      final m = int.tryParse(numeric[0]);
      final d = int.tryParse(numeric[1]);
      if (m != null && d != null) {
        final resolved = _resolve(m, d, today, cal);
        if (resolved != null) return (_DaySpec(resolved), 1);
      }
    }

    final weekday = weekdays[last];
    if (weekday != null) {
      final current = cal.weekdayOf(today);
      final offset = (weekday - current + 7) % 7;
      return (_DaySpec(cal.adding(offset == 0 ? 7 : offset, today)), 1);
    }

    return null;
  }

  static int? _dayNumber(String raw) {
    for (final suffix in ['st', 'nd', 'rd', 'th']) {
      if (raw.endsWith(suffix)) {
        return int.tryParse(raw.substring(0, raw.length - suffix.length));
      }
    }
    return int.tryParse(raw);
  }

  static Day? _resolve(int month, int day, Day today, DayCalendar cal) {
    final candidate = cal.validDay(today.year, month, day);
    if (candidate != null && candidate >= today) {
      return candidate;
    }
    return cal.validDay(today.year + 1, month, day);
  }

  static DateTime _nextOccurrence(
    int hour,
    int minute,
    DateTime now,
    DayCalendar cal,
  ) {
    var candidate = DateTime(now.year, now.month, now.day, hour, minute);
    if (candidate.isBefore(now) || candidate == now) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  static String dayLabel(Day day, DayCalendar cal) {
    final date = cal.dateOn(day, 12);
    return DateFormat('EEE MMM d').format(date);
  }

  static String timeLabel(DateTime date, DayCalendar cal) {
    return DateFormat('h:mm a').format(date.toLocal());
  }

  static String label(ParsedTask parsed, DateTime now, DayCalendar cal) {
    final today = cal.dayOf(now);
    switch (parsed.flex) {
      case Flex.week:
        return '→ Sometime this week, by ${dayLabel(parsed.due, cal)}';
      case Flex.month:
        return '→ Sometime this month, by ${dayLabel(parsed.due, cal)}';
      case Flex.none:
        break;
    }

    final String label;
    final days = cal.daysBetween(today, parsed.due);
    if (days == 0) {
      label = 'Today';
    } else if (days == 1) {
      label = 'Tomorrow';
    } else {
      label = dayLabel(parsed.due, cal);
    }

    if (parsed.dueAt != null) {
      return '→ $label ${timeLabel(parsed.dueAt!, cal)}';
    }
    return '→ $label';
  }
}

