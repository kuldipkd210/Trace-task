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
  final FocusNode _screenFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  DatePickSegment _datePickSegment = DatePickSegment.date;
  int _lastItemCount = -1;
  bool _lastDatePickerOpen = false;
  bool _lastShortcutsOpen = false;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_onModelUpdated);

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
    widget.model.removeListener(_onModelUpdated);
    _inputController.dispose();
    _inputFocusNode.dispose();
    _screenFocusNode.dispose();
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
    final currentCount = widget.model.store.items.length;
    final dateOpen = widget.model.datePick != null;
    final shortcutsOpen = widget.model.showingShortcuts;

    if (force ||
        currentCount != _lastItemCount ||
        dateOpen != _lastDatePickerOpen ||
        shortcutsOpen != _lastShortcutsOpen) {
      _lastItemCount = currentCount;
      _lastDatePickerOpen = dateOpen;
      _lastShortcutsOpen = shortcutsOpen;

      final baseHeight = shortcutsOpen ? 340.0 : 160.0;
      final rowHeight = 34.0;
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

  KeyEventResult _handleGlobalKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isControl = HardwareKeyboard.instance.isControlPressed ||
        (Platform.isMacOS && HardwareKeyboard.instance.isMetaPressed);
    final isShift = HardwareKeyboard.instance.isShiftPressed;
    final text = _inputController.text;

    // A. Inline Date & Time Picker Controls (High Priority when open)
    if (widget.model.datePick != null) {
      if (isControl && event.logicalKey == LogicalKeyboardKey.keyD) {
        setState(() => _datePickSegment = DatePickSegment.date);
        return KeyEventResult.handled;
      }
      if (isControl && event.logicalKey == LogicalKeyboardKey.keyT) {
        setState(() {
          _datePickSegment = DatePickSegment.time;
          if (!widget.model.datePick!.hasTime) {
            widget.model.toggleDatePickTime();
          }
        });
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        setState(() => _datePickSegment = DatePickSegment.date);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        setState(() {
          _datePickSegment = DatePickSegment.time;
          if (!widget.model.datePick!.hasTime) {
            widget.model.toggleDatePickTime();
          }
        });
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (_datePickSegment == DatePickSegment.date) {
          widget.model.shiftDatePickDay(1);
        } else {
          widget.model.shiftDatePickTime(30);
        }
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (_datePickSegment == DatePickSegment.date) {
          widget.model.shiftDatePickDay(-1);
        } else {
          widget.model.shiftDatePickTime(-30);
        }
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        widget.model.commitDatePick();
        _focusInput();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        widget.model.cancelDatePick();
        _focusInput();
        return KeyEventResult.handled;
      }
    }

    // B. Esc: Cancel, Clear, or Close Window
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (widget.model.showingShortcuts) {
        widget.model.toggleShortcuts();
        return KeyEventResult.handled;
      }
      if (widget.model.editingID != null) {
        widget.model.cancelEditing();
        _inputController.clear();
        return KeyEventResult.handled;
      }
      if (text.isNotEmpty) {
        _inputController.clear();
        widget.model.setText('');
        return KeyEventResult.handled;
      }
      WindowService.instance.hide();
      return KeyEventResult.handled;
    }

    // C. Up & Down Arrow Navigation across tasks
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      widget.model.selectNext();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      widget.model.selectPrevious();
      return KeyEventResult.handled;
    }

    // D. Enter Keys
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (isControl) {
        widget.model.markSelectedDone();
        return KeyEventResult.handled;
      }

      if (isShift) {
        final trimmed = text.trim();
        if (trimmed.isNotEmpty) {
          widget.model.setText(trimmed);
          widget.model.submit();
          _inputController.clear();
          _focusInput();
        }
        return KeyEventResult.handled;
      }

      // Plain Enter
      final trimmed = text.trim();
      if (trimmed.isNotEmpty) {
        widget.model.setText(trimmed);
        final effect = widget.model.submit();
        _inputController.clear();
        if (effect == PanelEffect.close) {
          WindowService.instance.hide();
        }
        return KeyEventResult.handled;
      } else if (widget.model.selectedID != null) {
        widget.model.markSelectedDone();
        return KeyEventResult.handled;
      }
    }

    // E. Delete & Backspace
    if (event.logicalKey == LogicalKeyboardKey.delete) {
      widget.model.deleteSelected();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (isControl || text.isEmpty) {
        widget.model.deleteSelected();
        return KeyEventResult.handled;
      }
    }

    // F. Space when input is empty -> Toggle Done
    if (event.logicalKey == LogicalKeyboardKey.space && text.isEmpty) {
      widget.model.markSelectedDone();
      return KeyEventResult.handled;
    }

    // G. Ctrl Shortcuts
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
          setState(() => _datePickSegment = DatePickSegment.date);
        } else {
          widget.model.cancelDatePick();
        }
        return KeyEventResult.handled;
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
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyE && widget.model.selectedID != null) {
        widget.model.startEditing(widget.model.selectedID!);
        _focusInput();
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
    return ListenableBuilder(
      listenable: widget.model,
      builder: (context, _) {
        final theme = AppTheme.of(context);

        return Focus(
          focusNode: _screenFocusNode,
          autofocus: false,
          onKeyEvent: _handleGlobalKeyEvent,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
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
                          color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.45 : 0.18),
                          blurRadius: 20,
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
                          // Input Bar + Live Preview
                          QuickCaptureInput(
                            model: widget.model,
                            controller: _inputController,
                            focusNode: _inputFocusNode,
                            onToggleTheme: _toggleTheme,
                            onToggleShortcuts: widget.model.toggleShortcuts,
                          ),

                          // Inline Date & Time Picker (Ctrl+D and Ctrl+T)
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
