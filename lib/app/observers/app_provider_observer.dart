import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sdk_base/core/logging/logging.dart';

const _log = AppLogger('Riverpod');

/// Centralized state observer for Riverpod provider lifecycle events.
/// Logs provider names only at [LogLevel.trace] without exposing values.
base class AppProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    _trace('⚡ update', context);
  }

  @override
  void didAddProvider(
    ProviderObserverContext context,
    Object? value,
  ) {
    _trace('➕ add', context);
  }

  @override
  void didDisposeProvider(
    ProviderObserverContext context,
  ) {
    _trace('🗑️ dispose', context);
  }

  void _trace(String event, ProviderObserverContext context) {
    _log.trace(
      event,
      data: {
        'provider': Redacted.unredacted(
          context.provider.name ?? context.provider.runtimeType.toString(),
          because: 'provider identity is source-code metadata, never user data',
        ),
      },
    );
  }
}
