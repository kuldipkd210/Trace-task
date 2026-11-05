import 'dart:io';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

class HotkeyService {
  static final HotkeyService instance = HotkeyService._();
  HotkeyService._();

  HotKey? _registeredHotKey;

  Future<void> initialize({required Future<void> Function() onTrigger}) async {
    await hotKeyManager.unregisterAll();

    // Default: Alt+Space on Linux/Windows, Option+Space on macOS
    final keyModifiers = Platform.isMacOS
        ? [HotKeyModifier.alt]
        : [HotKeyModifier.alt];

    _registeredHotKey = HotKey(
      key: PhysicalKeyboardKey.space,
      modifiers: keyModifiers,
      scope: HotKeyScope.system,
    );

    await hotKeyManager.register(
      _registeredHotKey!,
      keyDownHandler: (hotKey) async {
        await onTrigger();
      },
    );
  }

  Future<void> dispose() async {
    await hotKeyManager.unregisterAll();
  }
}
