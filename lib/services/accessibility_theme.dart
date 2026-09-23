import 'package:flutter/material.dart';

import '../theme.dart';

ThemeData buildHighContrastTheme({required bool darkMode}) {
  final base = buildTheme(darkMode: darkMode);
  final black = Colors.black;
  final white = Colors.white;
  final scheme = base.colorScheme.copyWith(
    primary: darkMode ? white : black,
    onPrimary: darkMode ? black : white,
    secondary: darkMode ? white : black,
    onSecondary: darkMode ? black : white,
    surface: darkMode ? black : white,
    onSurface: darkMode ? white : black,
    surfaceVariant: darkMode ? black : white,
    outline: darkMode ? white : black,
  );
  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: darkMode ? black : white,
    appBarTheme: base.appBarTheme.copyWith(backgroundColor: darkMode ? black : white, foregroundColor: darkMode ? white : black),
    cardTheme: base.cardTheme.copyWith(color: darkMode ? black : white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: darkMode ? white : black, width: 1.4))),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: darkMode ? black : white,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: darkMode ? white : black, width: 1.4)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: darkMode ? white : black, width: 2.2)),
    ),
    filledButtonTheme: FilledButtonThemeData(style: base.filledButtonTheme.style?.copyWith(backgroundColor: WidgetStatePropertyAll(darkMode ? white : black), foregroundColor: WidgetStatePropertyAll(darkMode ? black : white))),
  );
}
