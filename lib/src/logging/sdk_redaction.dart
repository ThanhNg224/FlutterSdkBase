/// Masking helpers applied before any value reaches an `SdkLogger`.
///
/// Internal: never exported from a public barrel.
abstract final class SdkRedaction {
  /// Rendered in place of a null value.
  static const String absentMarker = '(none)';

  /// Masks a credential, keeping [visible] characters at each end.
  ///
  /// A value short enough that the retained characters would reveal most of it
  /// is masked completely.
  static String secret(String? value, {int visible = 4}) {
    if (value == null) {
      return absentMarker;
    }
    if (value.length <= visible * 2) {
      return '*' * value.length;
    }
    return '${value.substring(0, visible)}…${value.substring(value.length - visible)}';
  }
}
