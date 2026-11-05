import 'package:flutter/material.dart';
import '../../core/panel/panel_model.dart';
import '../../services/window_service.dart';
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
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final theme = AppTheme.of(context);
        final isCard = theme.style == ThemeStyle.card;
        final horizontalInset = isCard ? 22.0 : 18.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row: Large Input + Sun/Moon Button + Mic Button + Shortcuts Button
            Padding(
              padding: EdgeInsets.only(
                left: horizontalInset,
                right: 14,
                top: isCard ? 18 : 14,
                bottom: isCard ? 4 : 6,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: true,
                      style: TextStyle(
                        color: theme.ink,
                        fontSize: isCard ? 25 : 22,
                        fontFamily: isCard ? 'serif' : null,
                        fontWeight: isCard ? FontWeight.normal : FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: model.editingID != null
                            ? 'Editing task…'
                            : 'Add a task…  try: call bank 3pm',
                        hintStyle: TextStyle(
                          color: theme.secondary.withOpacity(0.5),
                          fontSize: isCard ? 25 : 22,
                          fontFamily: isCard ? 'serif' : null,
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: (text) {
                        model.setText(text);
                      },
                      onSubmitted: (text) {
                        final trimmed = text.trim();
                        if (trimmed.isNotEmpty) {
                          model.setText(trimmed);
                          final effect = model.submit();
                          controller.clear();
                          if (effect == PanelEffect.close) {
                            WindowService.instance.hide();
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Sun / Moon LookButton
                  Tooltip(
                    message: isCard ? 'Switch to dark (Ctrl+L)' : 'Switch to light (Ctrl+L)',
                    child: InkWell(
                      onTap: onToggleTheme,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        child: Icon(
                          isCard ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                          size: 16,
                          color: theme.secondary,
                        ),
                      ),
                    ),
                  ),

                  // Mic Dictation Button
                  Tooltip(
                    message: model.isListening ? 'Stop dictating' : 'Dictate',
                    child: InkWell(
                      onTap: () => model.toggleDictation(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: model.isListening
                              ? (isCard ? const Color(0xFFB4232C) : const Color(0xFFFF453A))
                              : Colors.transparent,
                        ),
                        child: Icon(
                          model.isListening ? Icons.mic : Icons.mic_none_outlined,
                          size: 16,
                          color: model.isListening ? Colors.white : theme.secondary,
                        ),
                      ),
                    ),
                  ),

                  // Help / All keys button
                  Tooltip(
                    message: 'All shortcuts (Ctrl+/)',
                    child: InkWell(
                      onTap: onToggleShortcuts,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.help_outline_rounded,
                          size: 16,
                          color: theme.secondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Status Line: Live hint or preview or dictation state
            Container(
              height: 22,
              padding: EdgeInsets.symmetric(horizontal: horizontalInset),
              alignment: Alignment.centerLeft,
              child: _buildStatusLine(theme),
            ),

            SizedBox(height: isCard ? 8 : 10),

            // Divider
            Container(
              height: isCard ? 2 : 1,
              color: isCard ? theme.accent : theme.divider,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusLine(AppTheme theme) {
    if (model.isListening) {
      return Text(
        'Listening… speak your task',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: theme.warning,
        ),
      );
    }

    final preview = model.preview;
    if (preview == null || preview.isEmpty) {
      return const SizedBox.shrink();
    }

    final cleanText = preview.replaceAll('→ ', '');

    if (theme.style == ThemeStyle.glass) {
      return Container(
        height: 20,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF0A84FF).withOpacity(0.24),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              cleanText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFA9D3FF),
              ),
            ),
          ],
        ),
      );
    } else {
      return Text(
        cleanText,
        style: TextStyle(
          fontSize: 14,
          fontFamily: 'serif',
          fontStyle: FontStyle.italic,
          color: theme.secondary,
        ),
      );
    }
  }
}
