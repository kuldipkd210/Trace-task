// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tray_manager/legacy.dart';
import '../core/config/appearance.dart';
import '../core/models/menu_bar_state.dart';

class TrayService with TrayListener {
  static final TrayService instance = TrayService._();
  TrayService._();

  VoidCallback? onTogglePanel;
  void Function(AppAppearance)? onAppearanceChanged;

  Future<void> initialize({
    required VoidCallback onToggle,
    required void Function(AppAppearance) onAppearance,
  }) async {
    onTogglePanel = onToggle;
    onAppearanceChanged = onAppearance;

    await trayManager.setIcon(
      Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png',
    );

    trayManager.addListener(this);
    await updateContextMenu(AppAppearance.system);
  }

  Future<void> updateState(MenuBarState state) async {
    if (Platform.isMacOS) {
      await trayManager.setTitle(state.title);
    }
    // On Linux / Windows, tooltip displays the top task
    await trayManager.setToolTip(state.title);
  }

  Future<void> updateContextMenu(AppAppearance appearance) async {
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
