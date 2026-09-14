import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sdk_base/core/theme/app_theme.dart';
import 'package:flutter_sdk_base/l10n/app_localizations.dart';

/// Wraps [child] in the same theme + localization setup the real app uses.
Widget harness({
  required Widget child,
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('en'),
}) {
  return MaterialApp(
    theme: brightness == Brightness.dark ? AppTheme.darkTheme : AppTheme.lightTheme,
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}
