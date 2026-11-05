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

  int _lastItemCount = -1;
  bool _lastDatePickerOpen = false;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_onModelUpdated);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndAdjustHeight(force: true);
      _inputFocusNode.requestFocus();
    });
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
    _checkAndAdjustHeight();
  }

  void _checkAndAdjustHeight({bool force = false}) {
    final currentCount = widget.model.store.items.length;
    final dateOpen = widget.model.datePick != null;
    final shortcutsOpen = widget.model.showingShortcuts;

    if (force ||
        currentCount != _lastItemCount ||
        dateOpen != _lastDatePickerOpen) {
      _lastItemCount = currentCount;
      _lastDatePickerOpen = dateOpen;

      final baseHeight = shortcutsOpen ? 320.0 : 160.0;
      final rowHeight = 32.0;
      final datePickerHeight = dateOpen ? 44.0 : 0.0;
      final target = (baseHeight + (currentCount * rowHeight) + datePickerHeight)
          .clamp(WindowService.minPanelHeight, WindowService.maxPanelHeight);

      WindowService.instance.resize(target);
    }
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

    // Esc: Clear text or cancel
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

    // Enter without Shift/Ctrl is handled by TextField.onSubmitted
    // Shift + Enter: Add task and keep typing
    if (event.logicalKey == LogicalKeyboardKey.enter && isShift && !isControl) {
      final text = _inputController.text.trim();
      if (text.isNotEmpty) {
        widget.model.setText(text);
        widget.model.submit();
        _inputController.clear();
        _inputFocusNode.requestFocus();
      }
      return KeyEventResult.handled;
    }

    // Ctrl + Enter (Mark Done)
    if (event.logicalKey == LogicalKeyboardKey.enter && isControl) {
      widget.model.markSelectedDone();
      return KeyEventResult.handled;
    }

    // Up / Down selection
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      widget.model.selectNext();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      widget.model.selectPrevious();
      return KeyEventResult.handled;
    }

    // Ctrl shortcuts
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
      if (event.logicalKey == LogicalKeyboardKey.keyD) {
        if (widget.model.datePick == null) {
          widget.model.openDatePick();
        } else {
          widget.model.cancelDatePick();
        }
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyE &&
          widget.model.selectedID != null) {
        widget.model.startEditing(widget.model.selectedID!);
        _inputFocusNode.requestFocus();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyP) {
        widget.model.togglePinSelected();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyS) {
        widget.model.snoozeSelected(15);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyL) {
        _toggleTheme();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        widget.model.deleteSelected();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyZ) {
        widget.model.undo();
        return KeyEventResult.handled;
      }
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
    final isCard = theme.style == ThemeStyle.card;

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Main Panel Container
              Container(
                margin: EdgeInsets.only(top: isCard ? 10 : 0),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(theme.cornerRadius),
                  border: Border.all(
                    color: isCard ? const Color(0xFFD0D7DE) : Colors.white.withOpacity(0.14),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isCard ? 0.18 : 0.45),
                      blurRadius: isCard ? 18 : 28,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(theme.cornerRadius),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Input Row + StatusLine
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

                      // Task List or Shortcuts
                      Flexible(
                        child: widget.model.showingShortcuts
                            ? ShortcutsSheet(onClose: widget.model.toggleShortcuts)
                            : TaskListView(
                                model: widget.model,
                                scrollController: _scrollController,
                              ),
                      ),

                      // Footer divider in glass mode
                      if (!isCard)
                        Container(height: 1, color: theme.divider),

                      // Footer Shortcuts Legend
                      _buildFooter(theme, isCard),
                    ],
                  ),
                ),
              ),

              // The iconic Tack Red Pin in Card Mode
              if (isCard)
                Positioned(
                  top: 1,
                  child: _buildTackPin(theme),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTackPin(AppTheme theme) {
    const size = 18.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.accent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: size * 0.2,
            top: size * 0.2,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(AppTheme theme, bool isCard) {
    final mod = Platform.isMacOS ? '⌘' : '^';

    final keys = [
      ('↩', 'Add'),
      ('$mod↩', 'Done'),
      ('${mod}D', 'Date'),
      ('${mod}P', 'Pin'),
      ('$mod/', 'All keys'),
    ];

    if (!isCard) {
      // Native Glass footer: centered row with pill keycaps
      return Container(
        height: 36,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: keys.map((k) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.keycap,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      k.$1,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: theme.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    k.$2,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.secondary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    } else {
      // Index Card footer: spaced text across 22px margin
      return Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: keys.map((k) {
            return Text(
              '${k.$1} ${k.$2}',
              style: TextStyle(
                fontSize: 11,
                color: theme.secondary,
              ),
            );
          }).toList(),
        ),
      );
    }
  }
}
