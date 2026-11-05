// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:tray_manager/legacy.dart';
import '../core/config/app_paths.dart';
import '../core/config/appearance.dart';
import '../core/models/menu_bar_state.dart';

class TrayService with TrayListener {
  static final TrayService instance = TrayService._();
  TrayService._();

  VoidCallback? onTogglePanel;
  void Function(AppAppearance)? onAppearanceChanged;
  bool _initialized = false;

  Future<void> initialize({
    required VoidCallback onToggle,
    required void Function(AppAppearance) onAppearance,
  }) async {
    onTogglePanel = onToggle;
    onAppearanceChanged = onAppearance;

    try {
      final iconPath = await _ensureIconFile();
      try {
        await trayManager.setIcon(iconPath);
      } catch (_) {
        // Fallback to standard Ubuntu GNOME system theme icon
        await trayManager.setIcon('appointment-soon');
      }

      trayManager.addListener(this);
      await updateContextMenu(AppAppearance.system);
      _initialized = true;
    } catch (e) {
      debugPrint('Tray initialization error: $e');
    }
  }

  Future<String> _ensureIconFile() async {
    final baseDir = await AppPaths.getBaseDir();
    final targetFile = File(p.join(baseDir.path, 'app_icon.png'));

    if (!targetFile.existsSync()) {
      try {
        // Try reading asset bundle
        final byteData = await rootBundle.load('assets/app_icon.png');
        await targetFile.writeAsBytes(byteData.buffer.asUint8List());
      } catch (_) {
        // If asset bundle not ready, check project folder
        final projectIcon = File('/home/kd/Work/Trace-task/assets/app_icon.png');
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
      // In Ubuntu GNOME and macOS, setTitle shows text next to tray icon
      await trayManager.setTitle(state.title);
      await trayManager.setToolTip(state.title);
    } catch (_) {}
  }

  Future<void> updateContextMenu(AppAppearance appearance) async {
    if (!_initialized) return;
    try {
      final menu = Menu(
        items: [
          MenuItem(
            key: 'open_panel',
            label: 'Open TraceTask',
          ),
          MenuItem.separator(),
          MenuItem.checkbox(
            key: 'appearance_system',
            label: 'Appearance: System',
            checked: appearance == AppAppearance.system,
          ),
          MenuItem.checkbox(
            key: 'appearance_light',
            label: 'Appearance: Index Card (Light)',
            checked: appearance == AppAppearance.light,
          ),
          MenuItem.checkbox(
            key: 'appearance_dark',
            label: 'Appearance: Native Glass (Dark)',
            checked: appearance == AppAppearance.dark,
          ),
          MenuItem.separator(),
          MenuItem(
            key: 'quit',
            label: 'Quit',
          ),
        ],
      );
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
    switch (menuItem.key) {
      case 'open_panel':
        onTogglePanel?.call();
      case 'appearance_system':
        onAppearanceChanged?.call(AppAppearance.system);
      case 'appearance_light':
        onAppearanceChanged?.call(AppAppearance.light);
      case 'appearance_dark':
        onAppearanceChanged?.call(AppAppearance.dark);
      case 'quit':
        exit(0);
    }
  }
}
