import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ShortcutsSheet extends StatelessWidget {
  final VoidCallback onClose;

  const ShortcutsSheet({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    final shortcuts = [
      ('Enter', 'Add task and close'),
      ('Shift + Enter', 'Add task and stay open'),
      ('↑  ↓', 'Select previous / next task'),
      ('Ctrl + Enter', 'Mark selected task as Done'),
      ('Ctrl + 1 / 2 / 3', 'Today / Week / Month bucket'),
      ('Ctrl + D', 'Pick date and time'),
      ('Ctrl + E', 'Edit selected task'),
      ('Ctrl + P', 'Pin task to system tray / top bar'),
      ('Ctrl + S', 'Snooze timed alert (+15 mins)'),
      ('Ctrl + Backspace', 'Delete selected task'),
      ('Ctrl + Z', 'Undo last action'),
      ('Ctrl + /', 'Show / hide this cheat sheet'),
      ('Esc', 'Clear draft, cancel, or close'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Keyboard Shortcuts',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.ink,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onClose,
                child: Icon(Icons.close_rounded, size: 18, color: theme.secondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: shortcuts.length,
              separatorBuilder: (_, _) => Divider(color: theme.divider, height: 8),
              itemBuilder: (context, index) {
                final item = shortcuts[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.keycap,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: theme.divider),
                        ),
                        child: Text(
                          item.$1,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                            color: theme.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
