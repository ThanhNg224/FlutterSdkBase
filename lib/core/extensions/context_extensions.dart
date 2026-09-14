import 'package:flutter/widgets.dart';
import 'package:flutter_sdk_base/l10n/app_localizations.dart';

extension ContextExtensions on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
