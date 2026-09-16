# Demo Host Architecture Design

**Date:** 2026-09-16

**Goal:** Turn `example/` into a scalable reference host application without
moving host concerns into the SDK package.

## Decisions

- `example/` is a real host application with `ProviderScope`, Riverpod code
  generation, `MaterialApp.router`, and a nested `go_router` shell.
- The host uses feature-first pragmatic Clean Architecture. `app/` owns
  bootstrap, dependency wiring, routing, and shell UI; `core/` owns reusable
  host infrastructure; each feature owns its data, domain, and presentation
  concerns.
- Riverpod Generator is the only provider convention. App-scoped SDK/config
  providers are kept alive; feature providers are disposed according to their
  normal Riverpod lifecycle.
- `go_router` uses a `StatefulShellRoute.indexedStack` with `/health` and
  `/settings` branches. The shell owns bottom navigation and feature pages do
  not navigate by constructing routes themselves.
- The SDK public API remains unchanged. Only `example/`, host tooling, CI, and
  host documentation change.
- The reference host keeps deterministic behavior by adapting
  `FakeSdkHttpTransport` behind a host-only demo transport. The default fixture
  is a successful health response. Tests override the fixture to exercise
  unauthorized and other error states; no real credential or backend is used.
- Settings is read-only diagnostics: environment label, API base URL, SDK
  version, and deterministic transport description. No persistence, token
  storage, or API-key display is added.

## Boundaries and data flow

```text
ProviderScope
  └── HostApp -> appRouterProvider -> HostShell -> feature pages

appConfigProvider + demoTransportProvider -> sdkClientProvider
sdkClientProvider -> HealthRepositoryImpl -> HealthController -> HealthPage
appConfigProvider + sdkVersion -> SettingsViewData -> SettingsPage
SdkException -> AppFailure -> host-owned error copy
```

The Health domain exposes a host-owned `HealthSnapshot` and
`HealthRepository`. The data implementation is the only feature layer that
knows `SdkClient`; it maps `SdkHealth` and `SdkException` into host-owned
values. Presentation consumes `AsyncValue` and never constructs SDK requests.

## Verification

- Generated providers are checked into `example/lib` so a fresh checkout can
  analyze and build without an implicit generation step.
- `make verify` runs the root SDK gates and the example's dependency,
  generation, analysis, and tests.
- CI generates providers before archive-consumer, Android, and iOS host gates.
- Host tests cover provider wiring, SDK-to-domain mapping, controller loading /
  success / error states, shell navigation, and diagnostics rendering. Pure
  visual styling is not unit-tested.
