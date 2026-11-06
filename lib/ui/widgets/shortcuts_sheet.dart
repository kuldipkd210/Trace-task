import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ShortcutsSheet extends StatelessWidget {
  final VoidCallback onClose;

  const ShortcutsSheet({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final mod = Platform.isMacOS ? '⌘' : 'Ctrl+';

    final left = [
      ('↩', 'Add and close'),
      ('⇧↩', 'Add and stay open'),
      ('↑ ↓', 'Select task'),
      ('$mod↩', 'Mark Done'),
      ('$mod⌫', 'Delete'),
      ('${mod}Z', 'Undo'),
      ('${mod}E', 'Edit'),
      ('$mod 1 2 3', 'Today / Week / Month'),
      ('${mod}S', 'Snooze 15m'),
    ];

    final right = [
      ('${mod}P', 'Pin to tray / menu bar'),
      ('${mod}D', 'Pick a date and time'),
      ('${mod}T', 'Toggle time in date row'),
      ('${mod}L', 'Switch light / dark look'),
      ('${mod}M', 'Dictate task with mic'),
      ('$mod.', 'Quiet mode (1 hr)'),
      ('Esc', 'Clear draft, then close'),
      ('$mod/', 'Show or hide this cheat sheet'),
    ];

    const inset = 22.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: inset, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'ALL KEYS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: theme.secondary,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onClose,
                child: Icon(Icons.close_rounded, size: 16, color: theme.secondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildColumn(left, theme)),
              const SizedBox(width: 20),
              Expanded(child: _buildColumn(right, theme)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColumn(List<(String, String)> items, AppTheme theme) {
    return Column(
      children: items.map((item) {
        return Container(
          height: 26,
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              SizedBox(
                width: 78,
                child: Text(
                  item.$1,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: theme.ink,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  item.$2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.secondary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
