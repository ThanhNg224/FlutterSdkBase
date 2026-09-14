/// Severity of a record handed to an `SdkLogger`.
enum SdkLogLevel {
  /// Routine detail useful while integrating.
  debug,

  /// A notable but expected event.
  info,

  /// Something the host probably wants to investigate.
  warn,

  /// An operation failed.
  error,
}
