import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        const horizontalInset = 22.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top row: Large Serif Input + Sun/Moon + Mic + Help
            Padding(
              padding: const EdgeInsets.only(
                left: horizontalInset,
                right: 14,
                top: 16,
                bottom: 4,
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
                        fontSize: 24,
                        fontFamily: 'serif',
                        fontWeight: FontWeight.normal,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: model.editingID != null
                            ? 'Editing task…'
                            : 'Add a task…  try: call bank 3pm',
                        hintStyle: TextStyle(
                          color: theme.secondary.withOpacity(0.55),
                          fontSize: 24,
                          fontFamily: 'serif',
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: (text) {
                        model.setText(text);
                      },
                      onSubmitted: (text) {
                        final isShift = HardwareKeyboard.instance.isShiftPressed;
                        final trimmed = text.trim();
                        if (trimmed.isNotEmpty) {
                          model.setText(trimmed);
                          final effect = model.submit(stayOpen: isShift);
                          controller.clear();
                          if (!isShift && effect == PanelEffect.close) {
                            WindowService.instance.hide();
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Sun / Moon LookButton
                  Tooltip(
                    message: theme.brightness == Brightness.dark
                        ? 'Switch to light (Ctrl+L)'
                        : 'Switch to dark (Ctrl+L)',
                    child: InkWell(
                      onTap: onToggleTheme,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        child: Icon(
                          theme.brightness == Brightness.dark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          size: 16,
                          color: theme.secondary,
                        ),
                      ),
                    ),
                  ),

                  // Mic Dictation Button
                  Tooltip(
                    message: model.isListening
                        ? 'Finish dictating (Ctrl+M)'
                        : (model.isTranscribing ? 'Transcribing…' : 'Dictate (Ctrl+M)'),
                    child: InkWell(
                      onTap: () => model.toggleDictation(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (model.isListening || model.isTranscribing)
                              ? theme.accent
                              : Colors.transparent,
                        ),
                        child: Icon(
                          (model.isListening || model.isTranscribing)
                              ? Icons.mic
                              : Icons.mic_none_outlined,
                          size: 16,
                          color: (model.isListening || model.isTranscribing)
                              ? Colors.white
                              : theme.secondary,
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
              padding: const EdgeInsets.symmetric(horizontal: horizontalInset),
              alignment: Alignment.centerLeft,
              child: _buildStatusLine(theme),
            ),

            const SizedBox(height: 8),

            // Red Accent Divider (Identical in both Light and Dark)
            Container(
              height: 2,
              color: theme.accent,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusLine(AppTheme theme) {
    if (model.dictationError != null) {
      return Text(
        model.dictationError!,
        style: TextStyle(
          fontSize: 13,
          fontFamily: 'serif',
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500,
          color: theme.accent,
        ),
      );
    }

    if (model.isTranscribing) {
      return Text(
        'Transcribing with Whisper Large v3…',
        style: TextStyle(
          fontSize: 13,
          fontFamily: 'serif',
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500,
          color: theme.warning,
        ),
      );
    }

    if (model.isListening) {
      return Text(
        'Listening… speak your task (Ctrl+M to finish)',
        style: TextStyle(
          fontSize: 13,
          fontFamily: 'serif',
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500,
          color: theme.accent,
        ),
      );
    }

    final preview = model.preview;
    if (preview == null || preview.isEmpty) {
      return const SizedBox.shrink();
    }

    final cleanText = preview.replaceAll('→ ', '');

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
