import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/date_pick.dart';
import '../theme/app_theme.dart';

class DatePickerInline extends StatefulWidget {
  final DatePick pick;
  final ValueChanged<DatePick> onChanged;
  final VoidCallback onCommit;
  final VoidCallback onCancel;

  const DatePickerInline({
    super.key,
    required this.pick,
    required this.onChanged,
    required this.onCommit,
    required this.onCancel,
  });

  @override
  State<DatePickerInline> createState() => _DatePickerInlineState();
}

class _DatePickerInlineState extends State<DatePickerInline> {
  late DateTime _currentDate;
  late bool _hasTime;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.pick.date;
    _hasTime = widget.pick.hasTime;
  }

  void _shiftDay(int days) {
    setState(() {
      _currentDate = _currentDate.add(Duration(days: days));
      widget.onChanged(DatePick(date: _currentDate, hasTime: _hasTime));
    });
  }

  void _toggleTime() {
    setState(() {
      _hasTime = !_hasTime;
      widget.onChanged(DatePick(date: _currentDate, hasTime: _hasTime));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final dateStr = DateFormat('EEE, MMM d').format(_currentDate);
    final timeStr = DateFormat('h:mm a').format(_currentDate);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.sunken,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.accent.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 14, color: theme.accent),
          const SizedBox(width: 8),
          Text(
            dateStr,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.ink,
            ),
          ),
          if (_hasTime) ...[
            const SizedBox(width: 8),
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.accent,
              ),
            ),
          ],
          const Spacer(),
          // Shift day buttons
          InkWell(
            onTap: () => _shiftDay(-1),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Icon(Icons.chevron_left_rounded, size: 16, color: theme.secondary),
            ),
          ),
          InkWell(
            onTap: () => _shiftDay(1),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Icon(Icons.chevron_right_rounded, size: 16, color: theme.secondary),
            ),
          ),
          const SizedBox(width: 6),
          // Toggle Time button
          InkWell(
            onTap: _toggleTime,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _hasTime ? theme.accent.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _hasTime ? 'Time on' : 'Time off',
                style: TextStyle(
                  fontSize: 11,
                  color: _hasTime ? theme.accent : theme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Commit button
          InkWell(
            onTap: widget.onCommit,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.accent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Set ↩',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
