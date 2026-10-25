import 'package:flutter/material.dart';

class C {
  static const primary = Color(0xFF6B3FD4);
  static const bg = Color(0xFFF6F3FC);
  static const tint = Color(0xFFEDE6FB);
  static const tintBorder = Color(0xFFDCCFF6);
  static const ink = Color(0xFF1E1B2E);
  static const muted = Color(0xFF6B6880);
  static const line = Color(0xFFE6E1F2);
  static const dangerBg = Color(0xFFFDEBEC);
  static const danger = Color(0xFFB3261E);
  static const okBg = Color(0xFFE7F5EC);
  static const ok = Color(0xFF1E7B45);
  static const warnBg = Color(0xFFFFF4DC);
  static const warn = Color(0xFF8A5A00);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: C.primary,
    brightness: Brightness.light,
  ).copyWith(primary: C.primary);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: C.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: C.bg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: C.ink,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: C.tint,
    ),
    textTheme: ThemeData.light().textTheme.apply(
          bodyColor: C.ink,
          displayColor: C.ink,
        ),
  );
}
