import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/date_pick.dart';
import '../theme/app_theme.dart';

enum DatePickSegment { date, time }

class DatePickerInline extends StatefulWidget {
  final DatePick pick;
  final DatePickSegment activeSegment;
  final ValueChanged<DatePick> onChanged;
  final ValueChanged<DatePickSegment>? onSegmentChanged;
  final VoidCallback onCommit;
  final VoidCallback onCancel;

  const DatePickerInline({
    super.key,
    required this.pick,
    this.activeSegment = DatePickSegment.date,
    required this.onChanged,
    this.onSegmentChanged,
    required this.onCommit,
    required this.onCancel,
  });

  @override
  State<DatePickerInline> createState() => DatePickerInlineState();
}

class DatePickerInlineState extends State<DatePickerInline> {
  late DateTime _currentDate;
  late bool _hasTime;
  late DatePickSegment _segment;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.pick.date;
    _hasTime = widget.pick.hasTime;
    _segment = widget.activeSegment;
  }

  @override
  void didUpdateWidget(covariant DatePickerInline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pick.date != _currentDate || widget.pick.hasTime != _hasTime) {
      _currentDate = widget.pick.date;
      _hasTime = widget.pick.hasTime;
    }
    if (widget.activeSegment != _segment) {
      _segment = widget.activeSegment;
    }
  }

  void setSegment(DatePickSegment segment) {
    setState(() {
      _segment = segment;
      if (segment == DatePickSegment.time && !_hasTime) {
        _hasTime = true;
        widget.onChanged(DatePick(date: _currentDate, hasTime: _hasTime));
      }
      widget.onSegmentChanged?.call(_segment);
    });
  }

  void shiftDay(int days) {
    setState(() {
      _currentDate = _currentDate.add(Duration(days: days));
      widget.onChanged(DatePick(date: _currentDate, hasTime: _hasTime));
    });
  }

  void shiftTime(int minutes) {
    setState(() {
      _hasTime = true;
      _currentDate = _currentDate.add(Duration(minutes: minutes));
      widget.onChanged(DatePick(date: _currentDate, hasTime: _hasTime));
    });
  }

  void clearTime() {
    setState(() {
      _hasTime = false;
      _segment = DatePickSegment.date;
      widget.onChanged(DatePick(date: _currentDate, hasTime: false));
      widget.onSegmentChanged?.call(DatePickSegment.date);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final dateStr = DateFormat('EEE, MMM d').format(_currentDate);
    final timeStr = DateFormat('h:mm a').format(_currentDate);

    final isDateActive = _segment == DatePickSegment.date;
    final isTimeActive = _segment == DatePickSegment.time;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      color: theme.sunken,
      child: Row(
        children: [
          // 1. DATE BOX
          InkWell(
            onTap: () => setSegment(DatePickSegment.date),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 7),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDateActive ? theme.fieldStroke : theme.divider,
                  width: isDateActive ? 1.5 : 1.0,
                ),
                boxShadow: isDateActive
                    ? [
                        BoxShadow(
                          color: theme.accent.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: isDateActive ? theme.accent : theme.secondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: isDateActive ? FontWeight.bold : FontWeight.w500,
                      color: isDateActive ? theme.ink : theme.ink.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(width: 2),
                  InkWell(
                    onTap: () => shiftDay(-1),
                    child: Icon(Icons.arrow_drop_down, size: 16, color: theme.secondary),
                  ),
                  InkWell(
                    onTap: () => shiftDay(1),
                    child: Icon(Icons.arrow_drop_up, size: 16, color: theme.secondary),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 2. TIME BOX (NO separate checkbox)
          InkWell(
            onTap: () => setSegment(DatePickSegment.time),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 7),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isTimeActive ? theme.fieldStroke : theme.divider,
                  width: isTimeActive ? 1.5 : 1.0,
                ),
                boxShadow: isTimeActive
                    ? [
                        BoxShadow(
                          color: theme.accent.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: isTimeActive ? theme.accent : theme.secondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _hasTime ? timeStr : '+ Time',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: isTimeActive ? FontWeight.bold : FontWeight.w500,
                      color: _hasTime
                          ? (isTimeActive ? theme.ink : theme.ink.withOpacity(0.85))
                          : theme.secondary,
                    ),
                  ),
                  if (_hasTime) ...[
                    const SizedBox(width: 2),
                    InkWell(
                      onTap: () => shiftTime(-30),
                      child: Icon(Icons.arrow_drop_down, size: 16, color: theme.secondary),
                    ),
                    InkWell(
                      onTap: () => shiftTime(30),
                      child: Icon(Icons.arrow_drop_up, size: 16, color: theme.secondary),
                    ),
                    const SizedBox(width: 2),
                    InkWell(
                      onTap: clearTime,
                      child: Tooltip(
                        message: 'Remove time',
                        child: Icon(Icons.close, size: 13, color: theme.secondary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const Spacer(),

          // 3. KEYBOARD HINT (Compact, no overflow)
          Text(
            '↩ set · ^D Date · ^T Time · Esc',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: theme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
