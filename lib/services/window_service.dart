// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:window_manager/legacy.dart';

class WindowService with WindowListener {
  static final WindowService instance = WindowService._();
  WindowService._();

  VoidCallback? onFocusLost;
  VoidCallback? onWindowShown;
  VoidCallback? onFocusGained;
  bool autoHideOnBlur = false;

  static const double panelWidth = 560;
  static const double minPanelHeight = 140;
  static const double maxPanelHeight = 520;

  Future<void> initialize({VoidCallback? onBlur}) async {
    onFocusLost = onBlur;
    try {
      await windowManager.ensureInitialized();

      const windowOptions = WindowOptions(
        size: Size(panelWidth, 240),
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
      onWindowShown?.call();
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
      try {
        final size = await windowManager.getSize();
        if ((size.height - clampedHeight).abs() <= 2) {
          return;
        }
      } catch (_) {}
      await windowManager.setSize(Size(panelWidth, clampedHeight));
    } catch (_) {}
  }

  @override
  void onWindowFocus() {
    onFocusGained?.call();
  }

  @override
  void onWindowBlur() {
    if (autoHideOnBlur) {
      onFocusLost?.call();
    }
  }
}
