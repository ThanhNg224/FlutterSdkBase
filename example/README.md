# Flutter SDK Base reference host

This directory is an independent Flutter host application for exercising
`flutter_sdk_base` through its supported public barrels. It is intentionally
offline: the app uses a host-only adapter over `FakeSdkHttpTransport`, so the
Health flow does not need a backend or a real API key.

## Run it

From the repository root:

```sh
make example-verify
cd example
flutter run
```

When provider annotations change, regenerate the committed outputs with:

```sh
cd example
dart run build_runner build
dart format lib
```

## Host structure

```text
lib/
├── main.dart                         # ProviderScope + HostApp bootstrap
├── app/
│   ├── app.dart                       # MaterialApp.router
│   ├── providers/                     # app config, demo transport, SdkClient
│   ├── router/                        # route names and generated GoRouter provider
│   └── widgets/                       # navigation shell
├── core/
│   ├── config/                        # host-owned configuration values
│   ├── demo/                          # deterministic test fixture adapter
│   ├── error/                         # host failure mapping and user copy
│   └── theme/                         # host-owned Material 3 theme
└── features/
    ├── health/
    │   ├── data/                      # SDK adapter and repository provider
    │   ├── domain/                    # host contract and HealthSnapshot
    │   └── presentation/              # AsyncNotifier, page, and widgets
    └── settings/presentation/         # read-only host diagnostics
```

The provider graph is:

```text
ProviderScope
  └── HostApp → appRouterProvider → HostShell → feature pages

appConfigProvider + demoTransportProvider → sdkClientProvider
sdkClientProvider → HealthRepositoryImpl → HealthController → HealthPage
appConfigProvider + sdkVersion → SettingsViewData → SettingsPage
SdkException → AppFailure → host-owned error copy
```

## Layer rules

- `app/` owns bootstrap, routing, provider composition, and the navigation
  shell. Feature pages do not construct routes or SDK clients.
- `core/` contains reusable host infrastructure only. It must not absorb
  Health-specific business logic.
- `features/health/data` is the only Health layer coupled to `SdkClient`.
  `domain` exposes host-owned values and contracts; `presentation` consumes
  Riverpod `AsyncValue` state.
- All providers use Riverpod Generator. Generated `.g.dart` files are derived
  source and must stay in sync with their annotated Dart files.
- Settings is read-only diagnostics. The API key is supplied to the SDK client
  but is never exposed by the view model or rendered in the UI.
- The SDK package remains independent: do not import `lib/src/`, add host UI,
  routing, Riverpod, persistence, or native code under the package's `lib/`.

This host is a reference architecture, not a production API integration. A
product host should replace the demo transport and fixture configuration with
its own composition root while retaining the feature and lifecycle boundaries.
