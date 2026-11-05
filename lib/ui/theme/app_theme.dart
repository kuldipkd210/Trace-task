import 'package:flutter/material.dart';

enum ThemeStyle { card }

class AppTheme {
  final ThemeStyle style = ThemeStyle.card;
  final Brightness brightness;
  final Color surface;
  final Color ink;
  final Color secondary;
  final Color warning;
  final Color listening;
  final Color accent;
  final Color divider;
  final Color sunken;
  final Color fieldStroke;
  final Color highlighter;
  final Color highlighterInk;
  final double cornerRadius = 6.0;
  final double pinOverhang = 12.0;

  const AppTheme({
    required this.brightness,
    required this.surface,
    required this.ink,
    required this.secondary,
    required this.warning,
    required this.listening,
    required this.accent,
    required this.divider,
    required this.sunken,
    required this.fieldStroke,
    required this.highlighter,
    required this.highlighterInk,
  });

  // Light Mode: Authentic Warm White Index Card
  static const light = AppTheme(
    brightness: Brightness.light,
    surface: Color(0xFFFDFDFB),       // Warm paper white
    ink: Color(0xFF1C2024),           // Deep charcoal ink
    secondary: Color(0xFF5A626B),     // Muted pencil gray
    warning: Color(0xFFA83E1A),       // Rust red warning
    listening: Color(0xFFA83E1A),
    accent: Color(0xFFD8343C),        // Tack pushpin red
    divider: Color(0xFFD0D7DE),       // Clean card border / ruled line
    sunken: Color(0xFFF4F5F6),        // Soft sunken row
    fieldStroke: Color(0xFFD8343C),   // Focus stroke
    highlighter: Color(0xFFFFE680),   // Fluorescent yellow highlighter
    highlighterInk: Color(0xFF1C2024), // Ink on highlighter
  );

  // Dark Mode: Identical Index Card Design in Charcoal Slate
  static const dark = AppTheme(
    brightness: Brightness.dark,
    surface: Color(0xFF212328),       // Slate charcoal index card
    ink: Color(0xFFF5F5F7),           // Crisp light ink
    secondary: Color(0xFF9EA3AC),     // Muted card pencil gray
    warning: Color(0xFFFF9F0A),       // Amber warning
    listening: Color(0xFFFF6961),
    accent: Color(0xFFE63946),        // Tack pushpin red (vibrant)
    divider: Color(0xFF383C44),       // Subtle card border / ruled line
    sunken: Color(0xFF1A1C20),        // Dark sunken row
    fieldStroke: Color(0xFFE63946),   // Focus stroke
    highlighter: Color(0xFFFFE680),   // Yellow highlighter
    highlighterInk: Color(0xFF1C2024), // Dark ink on yellow highlighter for maximum contrast
  );

  static AppTheme of(BuildContext context, {Brightness? forcedBrightness}) {
    final brightness = forcedBrightness ?? Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }
}
