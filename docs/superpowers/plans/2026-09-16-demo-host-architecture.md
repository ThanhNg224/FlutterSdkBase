# Demo Host Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the `setState`-only example with a scalable Riverpod/go_router reference host while preserving the SDK package boundary.

**Architecture:** Use feature-first pragmatic Clean Architecture. `app/` owns bootstrap, provider wiring, routing, and a `StatefulShellRoute` navigation shell; `core/` owns host configuration, deterministic demo transport, errors, and theme; `features/health` and `features/settings` own their domain/data/presentation code.

**Tech Stack:** Flutter 3.47+, Dart 3.13+, `flutter_riverpod` 3.4.3, `riverpod_annotation` 4.0.7, `riverpod_generator` 4.0.9, `build_runner` 2.16.1, and `go_router` 18.0.1.

**Spec:** `docs/superpowers/specs/2026-09-16-demo-host-architecture-design.md`

## Global Constraints

- Change only the host example, host tooling/CI, and host documentation; do not change the SDK public barrels or `lib/src/`.
- Preserve Dart `>=3.13.0 <4.0.0`, Flutter `>=3.47.0`, Android API 24+, and iOS 15.0+.
- `example/` imports the SDK only through `package:flutter_sdk_base/flutter_sdk_base.dart` and `package:flutter_sdk_base/flutter_sdk_base_testing.dart`; no SDK-internal or relative imports.
- Use Riverpod Generator for all providers; generated `.g.dart` files are committed and regenerated with `dart run build_runner build`.
- Keep the demo deterministic and offline through a host-only adapter over `FakeSdkHttpTransport`; never add real credentials, persistence, or an external backend.
- Keep UI styling out of unit-test assertions; test state transitions, provider wiring, routing behavior, and user-visible error/diagnostic content.
- Preserve the pre-existing unrelated working-tree modification in `docs/GIT_FLOW.md` and never stage it.

---

### Task 1: Add host dependencies and app-level SDK wiring

**Files:**
- Modify: `example/pubspec.yaml`
- Create: `example/lib/core/config/app_config.dart`, `example/lib/core/demo/demo_health_scenario.dart`, `example/lib/core/demo/demo_sdk_http_transport.dart`
- Create: `example/lib/app/providers/app_providers.dart`, `example/lib/app/providers/app_providers.g.dart`
- Test: `example/test/app/providers/app_providers_test.dart`

**Interfaces:**
- `AppConfig` is an immutable host value with `environmentName`, `apiBaseUrl`, `apiKey`, and `transportDescription` string fields.
- `DemoHealthScenario` has `healthy` and `unauthorized` values; the default provider returns `healthy`.
- `DemoSdkHttpTransport` implements public `SdkHttpTransport`, delegates calls to `FakeSdkHttpTransport`, and queues a response for every open call based on a `DemoHealthScenario Function()` reader.
- Generated providers are `appConfigProvider`, `demoHealthScenarioProvider`, `demoTransportProvider`, and `sdkClientProvider`; `sdkClientProvider` owns and closes its `SdkClient` through `ref.onDispose`.

- [ ] Add the exact runtime/dev dependencies listed in the plan header.
- [ ] Implement the deterministic adapter without exposing `FakeSdkHttpTransport` outside host infrastructure and without logging or displaying `apiKey`.
- [ ] Generate provider code and test that the default client returns healthy data, an overridden unauthorized scenario maps to `SdkErrorCodes.unauthorized`, and provider disposal closes the SDK transport.
- [ ] Run `cd example && flutter pub get && dart run build_runner build && flutter test test/app/providers/app_providers_test.dart`.
- [ ] Commit only Task 1 files with `feat(example): add riverpod sdk wiring`.

### Task 2: Build the Health feature vertical slice

**Files:**
- Create: `example/lib/core/error/app_failure.dart`, `example/lib/core/error/app_error_copy.dart`
- Create: `example/lib/features/health/domain/models/health_snapshot.dart`, `example/lib/features/health/domain/health_repository.dart`
- Create: `example/lib/features/health/data/health_repository_impl.dart`, `example/lib/features/health/data/health_repository_provider.dart`, `example/lib/features/health/data/health_repository_provider.g.dart`
- Create: `example/lib/features/health/presentation/controllers/health_controller.dart`, `example/lib/features/health/presentation/controllers/health_controller.g.dart`
- Create: `example/lib/features/health/presentation/pages/health_page.dart`, `example/lib/features/health/presentation/widgets/health_status_card.dart`
- Test: `example/test/features/health/health_feature_test.dart`

**Interfaces:**
- `HealthSnapshot` mirrors only `isHealthy`, `status`, and `checkedAt`; it has value equality.
- `HealthRepository` exposes `Future<HealthSnapshot> check()`.
- `HealthRepositoryImpl` depends on `SdkClient`, calls `sdk.health.check()`, maps `SdkHealth`, and converts `SdkException` to `AppFailure` while preserving code, retryability, and request ID.
- `HealthController` is a generated `AsyncNotifier<HealthSnapshot?>`; `build()` returns `null` for the idle state and `check()` transitions loading → data or loading → error.
- `AppErrorCopy.messageFor(Object error)` maps known `AppFailure.code` values to host-owned English copy and returns a safe generic fallback.

- [ ] Write tests for SDK-to-domain mapping, all known error-code mappings, controller idle/loading/success/error transitions, and retry after an error.
- [ ] Implement the repository, generated providers, controller, and presentational widgets. The page must use `ConsumerWidget`, `AsyncValue`, `SafeArea`, and callbacks into the controller; it must not use `setState` or create an SDK client.
- [ ] Run `cd example && dart run build_runner build && flutter test test/features/health/health_feature_test.dart`.
- [ ] Commit only Task 2 files with `feat(example): add health feature layers`.

### Task 3: Add host shell, routing, Settings diagnostics, and bootstrap

**Files:**
- Create: `example/lib/app/app.dart`, `example/lib/app/router/app_route_names.dart`, `example/lib/app/router/app_router.dart`, `example/lib/app/router/app_router.g.dart`, `example/lib/app/widgets/host_shell.dart`, `example/lib/core/theme/app_theme.dart`, `example/lib/features/settings/presentation/settings_view_data.dart`, `example/lib/features/settings/presentation/settings_view_data.g.dart`, `example/lib/features/settings/presentation/pages/settings_page.dart`, `example/lib/features/settings/presentation/widgets/diagnostic_tile.dart`
- Replace: `example/lib/main.dart`
- Test: `example/test/app/host_app_test.dart`

**Interfaces:**
- `appRouterProvider` returns a keep-alive `GoRouter` with `/health` and `/settings` branches under `StatefulShellRoute.indexedStack`; `/` redirects to `/health`.
- `HostShell` accepts `StatefulNavigationShell`, owns `NavigationBar`, and calls `goBranch(index)`; it does not contain feature state.
- `settingsViewDataProvider` returns `SettingsViewData` containing environment name, API base URL, SDK version, and transport description; it never contains the API key.
- `HostApp` is a `ConsumerWidget` that watches `appRouterProvider` and builds `MaterialApp.router` with `AppTheme`; `main()` only calls `runApp(const ProviderScope(child: HostApp()))`.

- [ ] Add the router, shell, theme, settings diagnostics provider/page, and bootstrap around the completed Health feature.
- [ ] Add widget behavior tests for initial Health route, navigation to Settings, successful health check, and unauthorized error copy using a provider override; do not assert colors, padding, or exact widget tree styling.
- [ ] Run `cd example && dart run build_runner build && flutter test test/app/host_app_test.dart`.
- [ ] Commit only Task 3 files with `feat(example): add host shell and routing`.

### Task 4: Make host verification and documentation canonical

**Files:**
- Modify: `Makefile`, `.github/workflows/ci.yml`, `.github/copilot-instructions.md`, `example/README.md`
- Test: existing root and example gates

**Interfaces:**
- Make targets are `example-pub-get`, `example-generate`, `example-analyze`, `example-test`, and `example-verify`; `make verify` invokes `example-verify` after the root package gates.
- CI runs provider generation after every example `flutter pub get` and before analysis/build in archive, Android, and iOS jobs.

- [ ] Document the host tree, provider graph, layer rules, generation command, and `flutter run` command in `example/README.md`; clarify that the fixture is offline and host-only.
- [ ] Update repository guidance so “no code generation” applies to the SDK package, while the example host explicitly uses Riverpod code generation.
- [ ] Add the example verification targets and CI generation step without weakening existing package/archive/platform gates.
- [ ] Run `make verify`, inspect the complete diff, and run the CI-equivalent example commands locally where the installed toolchain permits.
- [ ] Commit only Task 4 files with `ci(example): verify generated host architecture`.

### Final review

- [ ] Run the full root and example gates again after all task commits.
- [ ] Confirm `git diff -- docs/GIT_FLOW.md` is unchanged from the pre-existing user modification and that no secrets or SDK-internal imports were added.
- [ ] Review generated provider files and route/provider disposal for lifecycle leaks.
