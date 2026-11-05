// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:window_manager/legacy.dart';

class WindowService with WindowListener {
  static final WindowService instance = WindowService._();
  WindowService._();

  VoidCallback? onFocusLost;
  bool autoHideOnBlur = false;

  static const double panelWidth = 460;
  static const double minPanelHeight = 220;
  static const double maxPanelHeight = 700;

  Future<void> initialize({VoidCallback? onBlur}) async {
    onFocusLost = onBlur;
    try {
      await windowManager.ensureInitialized();

      const windowOptions = WindowOptions(
        size: Size(panelWidth, 420),
        minimumSize: Size(panelWidth, minPanelHeight),
        maximumSize: Size(panelWidth, maxPanelHeight),
        center: true,
        title: 'TraceTask',
        skipTaskbar: false,
        alwaysOnTop: true,
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });

      windowManager.addListener(this);
    } catch (e) {
      debugPrint('WindowService initialization error: $e');
    }
  }

  Future<void> show() async {
    try {
      await windowManager.show();
      await windowManager.focus();
    } catch (_) {}
  }

  Future<void> hide() async {
    try {
      await windowManager.hide();
    } catch (_) {}
  }

  Future<void> toggle() async {
    try {
      final isVisible = await windowManager.isVisible();
      if (isVisible) {
        await hide();
      } else {
        await show();
      }
    } catch (_) {}
  }

  Future<void> resize(double targetHeight) async {
    try {
      final clampedHeight = targetHeight.clamp(minPanelHeight, maxPanelHeight);
      final size = await windowManager.getSize();
      if ((size.height - clampedHeight).abs() > 2) {
        await windowManager.setSize(Size(panelWidth, clampedHeight));
      }
    } catch (_) {}
  }

  @override
  void onWindowBlur() {
    if (autoHideOnBlur) {
      onFocusLost?.call();
    }
  }
}
