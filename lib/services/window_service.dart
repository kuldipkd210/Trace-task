// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:window_manager/legacy.dart';

class WindowService with WindowListener {
  static final WindowService instance = WindowService._();
  WindowService._();

  VoidCallback? onFocusLost;

  static const double panelWidth = 440;
  static const double minPanelHeight = 180;
  static const double maxPanelHeight = 600;

  Future<void> initialize({VoidCallback? onBlur}) async {
    onFocusLost = onBlur;
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(panelWidth, 340),
      minimumSize: Size(panelWidth, minPanelHeight),
      maximumSize: Size(panelWidth, maxPanelHeight),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
      alwaysOnTop: true,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setAsFrameless();
      await windowManager.show();
      await windowManager.focus();
    });

    windowManager.addListener(this);
  }

  Future<void> show() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> hide() async {
    await windowManager.hide();
  }

  Future<void> toggle() async {
    final isVisible = await windowManager.isVisible();
    if (isVisible) {
      await hide();
    } else {
      await show();
    }
  }

  Future<void> resize(double targetHeight) async {
    final clampedHeight = targetHeight.clamp(minPanelHeight, maxPanelHeight);
    final size = await windowManager.getSize();
    if ((size.height - clampedHeight).abs() > 2) {
      await windowManager.setSize(Size(panelWidth, clampedHeight));
    }
  }

  @override
  void onWindowBlur() {
    onFocusLost?.call();
  }
}
