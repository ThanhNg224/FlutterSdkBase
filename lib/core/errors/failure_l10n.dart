import 'package:flutter_sdk_base/core/errors/failure.dart';
import 'package:flutter_sdk_base/l10n/app_localizations.dart';

/// Turns a [Failure] into copy that can be shown to a person.
///
/// [Failure.message] is written for logs and bug reports — it can be a raw
/// `PlatformException` string straight out of the native SDK, which is the last
/// thing a customer should see. The UI shows this instead, and leaves
/// the technical detail to the logs.
extension FailureL10n on Failure {
  String localizedMessage(AppLocalizations l10n) => switch (this) {
    NetworkFailure() => l10n.errorNetwork,
    UnauthorizedFailure() => l10n.errorUnauthorized,
    ServerFailure() => l10n.errorServer,
    PlatformFailure() => l10n.errorPlatform,
    StorageFailure() => l10n.errorStorage,
    UnexpectedFailure() => l10n.errorUnexpected,
  };
}
