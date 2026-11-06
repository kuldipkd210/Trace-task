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

  DatePickSegment _datePickSegment = DatePickSegment.date;
  int _lastOpenCount = -1;
  bool _lastDatePickerOpen = false;
  bool _lastShortcutsOpen = false;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_onModelUpdated);

    // Register global keyboard handler so shortcuts like Ctrl+/ work anywhere in the app
    HardwareKeyboard.instance.addHandler(_onGlobalRawKeyEvent);

    // Custom key event interceptor directly on input box
    _inputFocusNode.onKeyEvent = _handleInputKeyEvent;

    // Ensure input is always focused whenever window is shown or focused
    WindowService.instance.onWindowShown = _focusInput;
    WindowService.instance.onFocusGained = _focusInput;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndAdjustHeight(force: true);
      _focusInput();
    });
  }

  void _focusInput() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _inputFocusNode.requestFocus();
        if (_inputController.text.isNotEmpty) {
          _inputController.selection = TextSelection.collapsed(
            offset: _inputController.text.length,
          );
        }
      }
    });
    // Fallback delayed check for X11/Wayland window server focus
    Future.delayed(const Duration(milliseconds: 60), () {
      if (mounted && !_inputFocusNode.hasFocus) {
        _inputFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onGlobalRawKeyEvent);
    widget.model.removeListener(_onModelUpdated);
    _inputController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onModelUpdated() {
    if (mounted) {
      if (widget.model.text != _inputController.text) {
        _inputController.text = widget.model.text;
        _inputController.selection = TextSelection.collapsed(
          offset: _inputController.text.length,
        );
      }
    }
    _checkAndAdjustHeight();
  }

  void _checkAndAdjustHeight({bool force = false}) {
    final allOpen = widget.model.store.items.where((i) => i.isOpen).toList();
    final currentCount = allOpen.length;
    final dateOpen = widget.model.datePick != null;
    final shortcutsOpen = widget.model.showingShortcuts;

    if (force ||
        currentCount != _lastOpenCount ||
        dateOpen != _lastDatePickerOpen ||
        shortcutsOpen != _lastShortcutsOpen) {
      _lastOpenCount = currentCount;
      _lastDatePickerOpen = dateOpen;
      _lastShortcutsOpen = shortcutsOpen;

      final datePickerHeight = dateOpen ? 40.0 : 0.0;
      double target;

      if (shortcutsOpen) {
        target = 410.0;
      } else if (currentCount == 0) {
        // 10 (top pin margin) + 84 (input) + 60 (empty text) + 1 (divider) + 32 (footer) + 6 (buffer)
        target = 193.0 + datePickerHeight;
      } else {
        // Count active groups (PINNED vs unpinned)
        final hasPinned = allOpen.any((i) => i.pinned);
        final hasUnpinned = allOpen.any((i) => !i.pinned);
        final groupHeadersCount = (hasPinned ? 1 : 0) + (hasUnpinned ? 1 : 0);

        // 10 (top pin margin) + 84 (input) + 1 (divider) + 32 (footer) + 6 (buffer) = 133.0
        // + group headers (28px each) + task rows (each row ~36px + 1px divider = 37px)
        target = 133.0 + (groupHeadersCount * 28.0) + (currentCount * 37.0) + datePickerHeight;
      }

      final clamped = target.clamp(WindowService.minPanelHeight, WindowService.maxPanelHeight);
      WindowService.instance.resize(clamped);
    }
  }

  void _toggleTheme() {
    final current = widget.model.config.appearance;
    final next = current == AppAppearance.light
        ? AppAppearance.dark
        : AppAppearance.light;
    widget.onAppearanceChange(next);
  }

  /// Intercepts keys while typing in the input box so arrow navigation works simultaneously
  KeyEventResult _handleInputKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final isShift = HardwareKeyboard.instance.isShiftPressed;
    final isControl = HardwareKeyboard.instance.isControlPressed;

    // Shift + Enter inside input box: Submit task and stay open for batch entry!
    if (event.logicalKey == LogicalKeyboardKey.enter && isShift && !isControl) {
      final trimmed = _inputController.text.trim();
      if (trimmed.isNotEmpty) {
        widget.model.setText(trimmed);
        widget.model.submit(stayOpen: true);
        _inputController.clear();
        _focusInput();
      }
      return KeyEventResult.handled;
    }

    // Up / Down arrow keys simultaneously navigate the task list without losing input focus
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (widget.model.datePick != null) {
        if (_datePickSegment == DatePickSegment.date) {
          widget.model.shiftDatePickDay(-1);
        } else {
          widget.model.shiftDatePickTime(-30);
        }
      } else {
        widget.model.selectNext();
      }
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (widget.model.datePick != null) {
        if (_datePickSegment == DatePickSegment.date) {
          widget.model.shiftDatePickDay(1);
        } else {
          widget.model.shiftDatePickTime(30);
        }
      } else {
        widget.model.selectPrevious();
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Global handler: catches shortcuts regardless of whether input is focused or not
  bool _onGlobalRawKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;

    // During key repeat (holding down a key), only allow arrow navigation / stepping
    if (event is KeyRepeatEvent) {
      final isArrow = event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.arrowRight;
      if (!isArrow) return false;
    }

    final isControl = HardwareKeyboard.instance.isControlPressed ||
        (Platform.isMacOS && HardwareKeyboard.instance.isMetaPressed);
    final isShift = HardwareKeyboard.instance.isShiftPressed;
    final text = _inputController.text;

    // 1. Esc: Cancel Dictation, Cancel, Clear, or Close Window
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (widget.model.isListening || widget.model.isTranscribing) {
        widget.model.cancelDictation();
        return true;
      }
      if (widget.model.showingShortcuts) {
        widget.model.toggleShortcuts();
        return true;
      }
      if (widget.model.datePick != null) {
        widget.model.cancelDatePick();
        _focusInput();
        return true;
      }
      if (widget.model.editingID != null) {
        widget.model.cancelEditing();
        _inputController.clear();
        return true;
      }
      if (text.isNotEmpty) {
        _inputController.clear();
        widget.model.setText('');
        return true;
      }
      WindowService.instance.hide();
      return true;
    }

    // 2. Ctrl + / (All keys / shortcuts cheat sheet) - Works anywhere!
    final isSlash = event.logicalKey == LogicalKeyboardKey.slash ||
        event.logicalKey == LogicalKeyboardKey.numpadDivide ||
        event.character == '/';
    if (isControl && isSlash) {
      widget.model.toggleShortcuts();
      return true;
    }

    // 3. Inline Date & Time Picker Key Handling (when open)
    if (widget.model.datePick != null) {
      if (isControl && event.logicalKey == LogicalKeyboardKey.keyD) {
        setState(() => _datePickSegment = DatePickSegment.date);
        return true;
      }
      if (isControl && event.logicalKey == LogicalKeyboardKey.keyT) {
        setState(() {
          _datePickSegment = DatePickSegment.time;
          if (!widget.model.datePick!.hasTime) {
            widget.model.toggleDatePickTime();
          }
        });
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        setState(() => _datePickSegment = DatePickSegment.date);
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        setState(() {
          _datePickSegment = DatePickSegment.time;
          if (!widget.model.datePick!.hasTime) {
            widget.model.toggleDatePickTime();
          }
        });
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter && !isShift && !isControl) {
        widget.model.commitDatePick();
        _focusInput();
        return true;
      }
    }

    // 4. Ctrl + Enter: Mark Selected Done
    if (event.logicalKey == LogicalKeyboardKey.enter && isControl) {
      widget.model.markSelectedDone();
      return true;
    }

    // 5. Shift + Enter: Add task and stay open
    if (event.logicalKey == LogicalKeyboardKey.enter && isShift && !isControl) {
      final trimmed = text.trim();
      if (trimmed.isNotEmpty) {
        widget.model.setText(trimmed);
        widget.model.submit(stayOpen: true);
        _inputController.clear();
        _focusInput();
      }
      return true;
    }

    // 6. Delete key: Deletes the selected task (BACKSPACE IS NOT USED TO DELETE TASKS!)
    if (event.logicalKey == LogicalKeyboardKey.delete) {
      widget.model.deleteSelected();
      return true;
    }

    // Note: Backspace is deliberately NOT used to delete tasks!

    // 7. Arrow keys when focus is NOT in input box
    if (!_inputFocusNode.hasFocus) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        widget.model.selectNext();
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        widget.model.selectPrevious();
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.space && text.isEmpty) {
        widget.model.markSelectedDone();
        return true;
      }
    }

    // 8. Ctrl Shortcuts (Works anywhere)
    if (isControl) {
      if (event.logicalKey == LogicalKeyboardKey.digit1) {
        widget.model.setBucketOverride(Bucket.today);
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.digit2) {
        widget.model.setBucketOverride(Bucket.week);
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.digit3) {
        widget.model.setBucketOverride(Bucket.month);
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyD) {
        if (widget.model.datePick == null) {
          widget.model.openDatePick();
          setState(() => _datePickSegment = DatePickSegment.date);
        } else {
          widget.model.cancelDatePick();
        }
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyT) {
        if (widget.model.datePick == null) {
          widget.model.openDatePick(hasTime: true);
          setState(() => _datePickSegment = DatePickSegment.time);
        } else {
          setState(() {
            _datePickSegment = DatePickSegment.time;
            if (!widget.model.datePick!.hasTime) {
              widget.model.toggleDatePickTime();
            }
          });
        }
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyE && widget.model.selectedID != null) {
        widget.model.startEditing(widget.model.selectedID!);
        _focusInput();
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyP) {
        widget.model.togglePinSelected();
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyS) {
        widget.model.snoozeSelected(15);
        return true;
      }
      final isPeriod = event.logicalKey == LogicalKeyboardKey.period ||
          event.logicalKey == LogicalKeyboardKey.numpadDecimal ||
          event.character == '.';
      if (isPeriod) {
        widget.model.toggleQuietMode();
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyL) {
        _toggleTheme();
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyM) {
        widget.model.toggleDictation();
        return true;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyZ) {
        widget.model.undo();
        return true;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.model,
      builder: (context, _) {
        final theme = AppTheme.of(context);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Align(
            alignment: Alignment.topCenter,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // Main Panel Surface (Identical geometry in both Light and Dark modes)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(theme.cornerRadius),
                    border: Border.all(
                      color: theme.divider,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.35 : 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(theme.cornerRadius),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Input Bar + Live Preview
                        QuickCaptureInput(
                          model: widget.model,
                          controller: _inputController,
                          focusNode: _inputFocusNode,
                          onToggleTheme: _toggleTheme,
                          onToggleShortcuts: widget.model.toggleShortcuts,
                        ),

                        // Inline Date & Time Picker (No checkbox, no overflow)
                        if (widget.model.datePick != null)
                          DatePickerInline(
                            pick: widget.model.datePick!,
                            activeSegment: _datePickSegment,
                            onChanged: widget.model.updateDatePick,
                            onSegmentChanged: (seg) => setState(() => _datePickSegment = seg),
                            onCommit: () {
                              widget.model.commitDatePick();
                              _focusInput();
                            },
                            onCancel: () {
                              widget.model.cancelDatePick();
                              _focusInput();
                            },
                          ),

                        // Task List or Shortcuts Sheet
                        Flexible(
                          child: widget.model.showingShortcuts
                              ? ShortcutsSheet(onClose: widget.model.toggleShortcuts)
                              : TaskListView(
                                  model: widget.model,
                                  scrollController: _scrollController,
                                ),
                        ),

                        // Ruled Divider before footer
                        Container(height: 1, color: theme.divider),

                        // Spaced Index Card Footer (Identical in both Light and Dark)
                        _buildFooter(theme),
                      ],
                    ),
                  ),
                ),

                // Red Tack Pin (Present in BOTH Light and Dark modes)
                Positioned(
                  top: 1,
                  child: _buildTackPin(theme),
                ),
              ],
            ),
          ),
        );
      },
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
            color: Colors.black.withOpacity(0.35),
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
                color: Colors.white.withOpacity(0.65),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(AppTheme theme) {
    if (widget.model.statusMessage != null) {
      return Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        alignment: Alignment.centerLeft,
        child: Text(
          widget.model.statusMessage!,
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'monospace',
            color: theme.secondary,
          ),
        ),
      );
    }

    final mod = Platform.isMacOS ? '⌘' : '^';

    final keys = [
      ('↩', 'Add'),
      ('$mod↩', 'Done'),
      ('${mod}D', 'Date'),
      ('${mod}T', 'Time'),
      ('${mod}P', 'Pin'),
      ('$mod/', 'All keys'),
    ];

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
              fontFamily: 'monospace',
              color: theme.secondary,
            ),
          );
        }).toList(),
      ),
    );
  }
}
