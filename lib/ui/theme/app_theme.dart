import 'package:flutter/material.dart';

enum ThemeStyle { card, glass }

class AppTheme {
  final ThemeStyle style;
  final Color surface;
  final Color ink;
  final Color secondary;
  final Color warning;
  final Color accent;
  final Color divider;
  final Color keycap;
  final Color sunken;
  final Color fieldStroke;
  final Color highlighter;

  const AppTheme({
    required this.style,
    required this.surface,
    required this.ink,
    required this.secondary,
    required this.warning,
    required this.accent,
    required this.divider,
    required this.keycap,
    required this.sunken,
    required this.fieldStroke,
    required this.highlighter,
  });

  static const card = AppTheme(
    style: ThemeStyle.card,
    surface: Color(0xFFFDFDFB),
    ink: Color(0xFF1C2024),
    secondary: Color(0xFF5A626B),
    warning: Color(0xFFA83E1A),
    accent: Color(0xFFD8343C),
    divider: Color(0xFFCFE0F0),
    keycap: Color(0x18000000),
    sunken: Color(0xFFF1F3F1),
    fieldStroke: Color(0xFF1C2024),
    highlighter: Color(0xFFFFE680),
  );

  static const glass = AppTheme(
    style: ThemeStyle.glass,
    surface: Color(0xFF181A1E),
    ink: Color(0xFFF5F5F7),
    secondary: Color(0xFFC0C2C9),
    warning: Color(0xFFFFB454),
    accent: Color(0xFF0A6CDB),
    divider: Color(0x17FFFFFF),
    keycap: Color(0x1FFFFFFF),
    sunken: Color(0x0AFFFFFF),
    fieldStroke: Color(0xFF0A6CDB),
    highlighter: Color(0xFF383818),
  );

  static AppTheme of(BuildContext context, {Brightness? forcedBrightness}) {
    final brightness = forcedBrightness ?? Theme.of(context).brightness;
    return brightness == Brightness.dark ? glass : card;
  }
}

