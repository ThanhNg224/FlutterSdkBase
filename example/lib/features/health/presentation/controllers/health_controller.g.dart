// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the asynchronous state of the Health feature.

@ProviderFor(HealthController)
final healthControllerProvider = HealthControllerProvider._();

/// Owns the asynchronous state of the Health feature.
final class HealthControllerProvider
    extends $AsyncNotifierProvider<HealthController, HealthSnapshot?> {
  /// Owns the asynchronous state of the Health feature.
  HealthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthControllerHash();

  @$internal
  @override
  HealthController create() => HealthController();
}

String _$healthControllerHash() => r'8f6a9e59d7bd1b863c0683de96cd70b5b274c358';

/// Owns the asynchronous state of the Health feature.

abstract class _$HealthController extends $AsyncNotifier<HealthSnapshot?> {
  FutureOr<HealthSnapshot?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<HealthSnapshot?>, HealthSnapshot?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<HealthSnapshot?>, HealthSnapshot?>,
              AsyncValue<HealthSnapshot?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
