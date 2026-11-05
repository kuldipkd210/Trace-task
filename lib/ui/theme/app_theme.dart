import 'package:flutter/material.dart';

enum ThemeStyle { card, glass }

class AppTheme {
  final ThemeStyle style;
  final Color surface;
  final Color ink;
  final Color secondary;
  final Color warning;
  final Color listening;
  final Color accent;
  final Color divider;
  final Color keycap;
  final Color sunken;
  final Color fieldStroke;
  final Color highlighter;
  final double cornerRadius;
  final double pinOverhang;

  const AppTheme({
    required this.style,
    required this.surface,
    required this.ink,
    required this.secondary,
    required this.warning,
    required this.listening,
    required this.accent,
    required this.divider,
    required this.keycap,
    required this.sunken,
    required this.fieldStroke,
    required this.highlighter,
    required this.cornerRadius,
    required this.pinOverhang,
  });

  static const glass = AppTheme(
    style: ThemeStyle.glass,
    surface: Color(0xFF222429),
    ink: Color(0xFFF5F5F7),
    secondary: Color(0xFFC0C2C9),
    warning: Color(0xFFFFB454),
    listening: Color(0xFFFF9F97),
    accent: Color(0xFF0A6CDB),
    divider: Color(0x17FFFFFF), // white 9%
    keycap: Color(0x1FFFFFFF),  // white 12%
    sunken: Color(0x0AFFFFFF),  // white 4%
    fieldStroke: Color(0xFF0A6CDB),
    highlighter: Color(0xFF383818),
    cornerRadius: 16,
    pinOverhang: 0,
  );

  static const card = AppTheme(
    style: ThemeStyle.card,
    surface: Color(0xFFFDFDFB), // warm paper
    ink: Color(0xFF1C2024),
    secondary: Color(0xFF5A626B),
    warning: Color(0xFFA83E1A),
    listening: Color(0xFFA83E1A),
    accent: Color(0xFFD8343C), // Tack red pin
    divider: Color(0xFFCFE0F0), // lined paper blue
    keycap: Colors.transparent,
    sunken: Color(0xFFF1F3F1),
    fieldStroke: Color(0xFF1C2024),
    highlighter: Color(0xFFFFE680), // highlighter yellow
    cornerRadius: 6,
    pinOverhang: 12,
  );

  static AppTheme of(BuildContext context, {Brightness? forcedBrightness}) {
    final brightness = forcedBrightness ?? Theme.of(context).brightness;
    return brightness == Brightness.dark ? glass : card;
  }
}
