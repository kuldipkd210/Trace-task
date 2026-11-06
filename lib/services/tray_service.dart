// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:tray_manager/legacy.dart';
import '../core/config/app_paths.dart';
import '../core/models/item.dart';
import '../core/models/menu_bar_state.dart';
import '../core/parser/parser.dart';
import '../core/time/day_calendar.dart';

class TrayService with TrayListener {
  static final TrayService instance = TrayService._();
  TrayService._();

  VoidCallback? onTogglePanel;
  void Function(String taskId)? onTaskSelected;
  void Function(String taskId)? onTaskComplete;
  bool _initialized = false;
  String? _cachedNormalIcon;
  String? _cachedRedIcon;
  TrayTone _currentTone = TrayTone.normal;

  Future<void> initialize({
    required VoidCallback onToggle,
    void Function(String taskId)? onTaskSelect,
    void Function(String taskId)? onTaskComplete,
  }) async {
    onTogglePanel = onToggle;
    onTaskSelected = onTaskSelect;
    this.onTaskComplete = onTaskComplete;

    try {
      _cachedNormalIcon = await _ensureIconFile(isRed: false);
      _cachedRedIcon = await _ensureIconFile(isRed: true);
      try {
        await trayManager.setIcon(_cachedNormalIcon!);
      } catch (_) {
        // Fallback to standard Ubuntu GNOME system theme icon
        await trayManager.setIcon('appointment-soon');
      }

      trayManager.addListener(this);
      await updateContextMenu(pinnedTasks: const []);
      _initialized = true;
    } catch (e) {
      debugPrint('Tray initialization error: $e');
    }
  }

  Future<String> _ensureIconFile({bool isRed = false}) async {
    final fileName = isRed ? 'app_icon_red.png' : 'app_icon.png';
    final baseDir = await AppPaths.getBaseDir();
    final targetFile = File(p.join(baseDir.path, fileName));

    if (!targetFile.existsSync()) {
      try {
        // Try reading asset bundle
        final byteData = await rootBundle.load('assets/$fileName');
        await targetFile.writeAsBytes(byteData.buffer.asUint8List());
      } catch (_) {
        // If asset bundle not ready, check project folder
        final projectIcon = File('/home/kd/Work/Trace-task/assets/$fileName');
        if (projectIcon.existsSync()) {
          projectIcon.copySync(targetFile.path);
        }
      }
    }

    if (targetFile.existsSync()) {
      return targetFile.path;
    }
    return 'appointment-soon';
  }

  Future<void> updateState(MenuBarState state) async {
    if (!_initialized) return;
    try {
      if (state.tone != _currentTone) {
        _currentTone = state.tone;
        final iconPath = state.tone == TrayTone.red
            ? (_cachedRedIcon ??= await _ensureIconFile(isRed: true))
            : (_cachedNormalIcon ??= await _ensureIconFile(isRed: false));
        await trayManager.setIcon(iconPath);
      }

      // In Ubuntu GNOME and macOS, setTitle shows text next to tray icon
      await trayManager.setTitle(state.title);
      await trayManager.setToolTip(state.title.isNotEmpty ? state.title : 'TraceTask');
    } catch (_) {}
  }

  Future<void> updateContextMenu({
    required List<Item> pinnedTasks,
    DayCalendar? cal,
  }) async {
    if (!_initialized) return;
    try {
      final menuItems = <MenuItem>[
        MenuItem(
          key: 'open_panel',
          label: 'Open TraceTask',
        ),
        MenuItem.separator(),
      ];

      if (pinnedTasks.isNotEmpty) {
        final calendar = cal ?? const DayCalendar();
        for (final task in pinnedTasks.take(5)) {
          const dot = '• ';
          final timeStr = task.dueAt != null
              ? ' (${Parser.timeLabel(task.dueAt!, calendar)})'
              : '';
          menuItems.add(MenuItem.submenu(
            label: '$dot${task.title}$timeStr',
            submenu: Menu(
              items: [
                MenuItem(
                  key: 'done_${task.id}',
                  label: '✓ Mark as Completed',
                ),
                MenuItem(
                  key: 'task_${task.id}',
                  label: '↗ Open in TraceTask',
                ),
              ],
            ),
          ));
        }
      } else {
        menuItems.add(MenuItem(
          key: 'no_pinned',
          label: '(No pinned tasks)',
          disabled: true,
        ));
      }

      menuItems.addAll([
        MenuItem.separator(),
        MenuItem(
          key: 'quit',
          label: 'Quit',
        ),
      ]);

      final menu = Menu(items: menuItems);
      await trayManager.setContextMenu(menu);
    } catch (_) {}
  }

  @override
  void onTrayIconMouseDown() {
    onTogglePanel?.call();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final key = menuItem.key;
    if (key != null && key.startsWith('done_')) {
      final taskId = key.substring(5);
      onTaskComplete?.call(taskId);
      return;
    }
    if (key != null && key.startsWith('task_')) {
      final taskId = key.substring(5);
      onTaskSelected?.call(taskId);
      return;
    }

    switch (key) {
      case 'open_panel':
        onTogglePanel?.call();
      case 'quit':
        exit(0);
    }
  }
}
