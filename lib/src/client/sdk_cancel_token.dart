import 'package:meta/meta.dart';

/// SDK-owned cancellation for one or more in-flight operations.
///
/// Cancellation is best-effort. It stops the SDK waiting for the operation but
/// cannot prove that a server did not receive or process the request. Hosts
/// normally create one token per operation; deliberately reusing a token groups
/// those operations under one cancellation request.
final class SdkCancelToken {
  final List<void Function()> _listeners = <void Function()>[];
  bool _isCancelled = false;

  /// Cancels operations currently using this token.
  ///
  /// This method is idempotent. Cancelling a token never closes an
  /// `SdkClient` or its transport.
  void cancel() {
    if (_isCancelled) {
      return;
    }
    _isCancelled = true;
    final List<void Function()> listeners = List<void Function()>.of(_listeners);
    _listeners.clear();
    for (final void Function() listener in listeners) {
      listener();
    }
  }

  /// Whether [cancel] has been called.
  bool get isCancelled => _isCancelled;

  /// Registers an internal operation listener.
  @internal
  void Function() addListener(void Function() listener) {
    if (_isCancelled) {
      listener();
      return () {};
    }
    _listeners.add(listener);
    bool removed = false;
    return () {
      if (removed) {
        return;
      }
      removed = true;
      _listeners.remove(listener);
    };
  }
}
