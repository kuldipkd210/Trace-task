import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/config/appearance.dart';
import '../core/models/bucket.dart';
import '../core/panel/panel_model.dart';
import '../services/window_service.dart';
import 'theme/app_theme.dart';
import 'widgets/date_picker_inline.dart';
import 'widgets/quick_capture_input.dart';
import 'widgets/shortcuts_sheet.dart';
import 'widgets/task_list_view.dart';

class PanelScreen extends StatefulWidget {
  final PanelModel model;
  final void Function(AppAppearance) onAppearanceChange;

  const PanelScreen({
    super.key,
    required this.model,
    required this.onAppearanceChange,
  });

  @override
  State<PanelScreen> createState() => _PanelScreenState();
}

class _PanelScreenState extends State<PanelScreen> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_onModelUpdated);
  }

  @override
  void dispose() {
    widget.model.removeListener(_onModelUpdated);
    _inputController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onModelUpdated() {
    if (widget.model.text != _inputController.text) {
      _inputController.text = widget.model.text;
      _inputController.selection = TextSelection.collapsed(
        offset: _inputController.text.length,
      );
    }
    _adjustWindowHeight();
  }

  void _adjustWindowHeight() {
    final taskCount = widget.model.groups.fold<int>(
      0,
      (sum, g) => sum + g.rows.length,
    );
    final baseHeight = 160.0;
    final rowHeight = 32.0;
    final datePickerHeight = widget.model.datePick != null ? 50.0 : 0.0;
    final target = baseHeight + (taskCount * rowHeight) + datePickerHeight;
    WindowService.instance.resize(target);
  }

  void _toggleTheme() {
    final current = widget.model.config.appearance;
    final next = current == AppAppearance.light
        ? AppAppearance.dark
        : AppAppearance.light;
    widget.onAppearanceChange(next);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isControl = HardwareKeyboard.instance.isControlPressed ||
        (Platform.isMacOS && HardwareKeyboard.instance.isMetaPressed);
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    // Esc
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (widget.model.showingShortcuts ||
          widget.model.datePick != null ||
          widget.model.editingID != null ||
          _inputController.text.isNotEmpty) {
        widget.model.clearOrClose();
        _inputController.clear();
      } else {
        WindowService.instance.hide();
      }
      return KeyEventResult.handled;
    }

    // Enter / Shift+Enter
    if (event.logicalKey == LogicalKeyboardKey.enter && !isControl) {
      final effect = widget.model.submit();
      _inputController.clear();
      if (effect == PanelEffect.close && !isShift) {
        WindowService.instance.hide();
      }
      return KeyEventResult.handled;
    }

    // Ctrl + Enter (Mark Done)
    if (event.logicalKey == LogicalKeyboardKey.enter && isControl) {
      widget.model.markSelectedDone();
      return KeyEventResult.handled;
    }

    // Up / Down (Navigation)
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      widget.model.selectNext();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      widget.model.selectPrevious();
      return KeyEventResult.handled;
    }

    // Ctrl + 1, 2, 3 (Buckets)
    if (isControl) {
      if (event.logicalKey == LogicalKeyboardKey.digit1) {
        widget.model.setBucketOverride(Bucket.today);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.digit2) {
        widget.model.setBucketOverride(Bucket.week);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.digit3) {
        widget.model.setBucketOverride(Bucket.month);
        return KeyEventResult.handled;
      }
      // Ctrl + D (Date Pick)
      if (event.logicalKey == LogicalKeyboardKey.keyD) {
        if (widget.model.datePick == null) {
          widget.model.openDatePick();
        } else {
          widget.model.cancelDatePick();
        }
        return KeyEventResult.handled;
      }
      // Ctrl + E (Edit)
      if (event.logicalKey == LogicalKeyboardKey.keyE &&
          widget.model.selectedID != null) {
        widget.model.startEditing(widget.model.selectedID!);
        _inputFocusNode.requestFocus();
        return KeyEventResult.handled;
      }
      // Ctrl + P (Pin)
      if (event.logicalKey == LogicalKeyboardKey.keyP) {
        widget.model.togglePinSelected();
        return KeyEventResult.handled;
      }
      // Ctrl + S (Snooze 15m)
      if (event.logicalKey == LogicalKeyboardKey.keyS) {
        widget.model.snoozeSelected(15);
        return KeyEventResult.handled;
      }
      // Ctrl + Backspace (Delete)
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        widget.model.deleteSelected();
        return KeyEventResult.handled;
      }
      // Ctrl + Z (Undo)
      if (event.logicalKey == LogicalKeyboardKey.keyZ) {
        widget.model.undo();
        return KeyEventResult.handled;
      }
      // Ctrl + / (Shortcuts)
      if (event.logicalKey == LogicalKeyboardKey.slash) {
        widget.model.toggleShortcuts();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.divider, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: widget.model.showingShortcuts
              ? ShortcutsSheet(onClose: widget.model.toggleShortcuts)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Input Bar
                    QuickCaptureInput(
                      model: widget.model,
                      controller: _inputController,
                      focusNode: _inputFocusNode,
                      onToggleTheme: _toggleTheme,
                      onToggleShortcuts: widget.model.toggleShortcuts,
                    ),

                    // Inline Date Picker
                    if (widget.model.datePick != null)
                      DatePickerInline(
                        pick: widget.model.datePick!,
                        onChanged: widget.model.updateDatePick,
                        onCommit: widget.model.commitDatePick,
                        onCancel: widget.model.cancelDatePick,
                      ),

                    const SizedBox(height: 8),

                    // Task List
                    Flexible(
                      child: TaskListView(
                        model: widget.model,
                        scrollController: _scrollController,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Footer Legend
                    _buildFooter(theme),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFooter(AppTheme theme) {
    final mod = Platform.isMacOS ? '⌘' : '^';
    return Container(
      padding: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.divider, width: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _footerKey('↩', 'Add', theme),
          _footerKey('$mod↩', 'Done', theme),
          _footerKey('${mod}D', 'Date', theme),
          _footerKey('${mod}P', 'Pin', theme),
          _footerKey('$mod/', 'All keys', theme),
        ],
      ),
    );
  }

  Widget _footerKey(String key, String label, AppTheme theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: theme.keycap,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: theme.divider, width: 0.5),
          ),
          child: Text(
            key,
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: theme.ink,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.secondary.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}
