import 'package:flutter_sdk_base/core/utils/redaction.dart';

/// A wrapped value safe for logging with redaction applied.
final class Redacted {
  const Redacted._(this._display);

  /// Credentials (e.g. appToken, clientKey, datasetId).
  factory Redacted.secret(String? value) => Redacted._(Redaction.secret(value));

  /// Phone numbers (masked keeping trailing digits).
  factory Redacted.phone(String? value) => Redacted._(Redaction.tail(value));

  /// Payload or raw content length representation.
  factory Redacted.length(String? value) => Redacted._(Redaction.length(value));

  /// Type name only.
  factory Redacted.type(Object? value) => Redacted._(Redaction.typeOf(value));

  /// Numeric count.
  factory Redacted.count(int value) => Redacted._('$value');

  /// Boolean flag.
  factory Redacted.flag(bool value) => Redacted._(value ? 'true' : 'false');

  /// Explicit unredacted value with documented reason.
  // ignore: avoid_unused_constructor_parameters
  factory Redacted.unredacted(String value, {required String because}) => Redacted._(value);

  final String _display;

  @override
  String toString() => _display;
}
