import 'package:flutter/material.dart';

/// Host-owned theme for the reference application.
abstract final class AppTheme {
  /// The light Material 3 theme used by the host.
  static ThemeData get light => ThemeData(
    colorSchemeSeed: const Color(0xFF1E56A0),
    useMaterial3: true,
  );
}
