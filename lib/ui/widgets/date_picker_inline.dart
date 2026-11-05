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
    final isCard = theme.style == ThemeStyle.card;
    final dateStr = DateFormat('EEE, MMM d').format(_currentDate);
    final timeStr = DateFormat('h:mm a').format(_currentDate);

    return Container(
      height: isCard ? 40 : 44,
      padding: EdgeInsets.symmetric(horizontal: isCard ? 22 : 18),
      color: theme.sunken,
      child: Row(
        children: [
          // Date badge
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isCard ? const Color(0xFFFDFDFB) : Colors.white.withOpacity(0.09),
              borderRadius: BorderRadius.circular(isCard ? 4 : 7),
              border: Border.all(color: theme.fieldStroke, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _hasTime ? '$dateStr $timeStr' : dateStr,
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: theme.ink,
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _shiftDay(-1),
                  child: Icon(Icons.arrow_drop_down, size: 16, color: theme.secondary),
                ),
                InkWell(
                  onTap: () => _shiftDay(1),
                  child: Icon(Icons.arrow_drop_up, size: 16, color: theme.secondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Time checkbox
          InkWell(
            onTap: _toggleTime,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _hasTime ? Icons.check_box_outlined : Icons.check_box_outline_blank,
                  size: 16,
                  color: theme.ink,
                ),
                const SizedBox(width: 4),
                Text(
                  'Time',
                  style: TextStyle(fontSize: 12, color: theme.ink),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Key hints
          Text(
            _hasTime ? '↩ set · Ctrl+T no time · Esc' : 'No timed alert · ↩ set · Ctrl+T time · Esc',
            style: TextStyle(fontSize: 11, color: theme.secondary),
          ),
        ],
      ),
    );
  }
}
