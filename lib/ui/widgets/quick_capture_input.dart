import 'package:flutter/material.dart';
import '../../core/panel/panel_model.dart';
import '../theme/app_theme.dart';

class QuickCaptureInput extends StatelessWidget {
  final PanelModel model;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleShortcuts;

  const QuickCaptureInput({
    super.key,
    required this.model,
    required this.controller,
    required this.focusNode,
    required this.onToggleTheme,
    required this.onToggleShortcuts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final preview = model.preview;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.sunken,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.fieldStroke.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  style: TextStyle(
                    color: theme.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: model.editingID != null
                        ? 'Editing task…'
                        : 'What needs doing?',
                    hintStyle: TextStyle(
                      color: theme.secondary.withOpacity(0.6),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: model.setText,
                  onSubmitted: (_) {
                    final effect = model.submit();
                    if (effect == PanelEffect.close) {
                      controller.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Appearance switcher (Sun / Moon)
              InkWell(
                onTap: onToggleTheme,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    theme.style == ThemeStyle.card
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    size: 16,
                    color: theme.secondary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Help / Shortcuts
              InkWell(
                onTap: onToggleShortcuts,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.help_outline_rounded,
                    size: 16,
                    color: theme.secondary,
                  ),
                ),
              ),
            ],
          ),
          if (preview != null) ...[
            const SizedBox(height: 5),
            Text(
              preview,
              style: TextStyle(
                fontSize: 12,
                color: theme.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

