import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

class HotkeyService {
  static final HotkeyService instance = HotkeyService._();
  HotkeyService._();

  HotKey? _registeredHotKey;

  Future<void> initialize({required Future<void> Function() onTrigger}) async {
    try {
      await hotKeyManager.unregisterAll();

      final keyModifiers = [HotKeyModifier.alt];

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
    } catch (e) {
      debugPrint('Global hotkey registration warning: $e');
    }
  }

  Future<void> dispose() async {
    try {
      await hotKeyManager.unregisterAll();
    } catch (_) {}
  }
}
