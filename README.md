# FlutterSdkBase

A Flutter SDK package with an independent example host. Hosts consume the explicit public barrels; `lib/src/` remains implementation detail.

## Prerequisites

Use Python 3.12+ and the existing SDK support contract:

| Platform / Surface | Supported Version | Notes |
| :--- | :--- | :--- |
| **Dart** | `>=3.13.0 <4.0.0` | Strict language contract |
| **Flutter** | `>=3.47.0` | Foundation only |
| **Android** | API 24+ | Fully validated |
| **iOS** | 15.0+ | Fully validated |

*Web and desktop targets may compile, but are untested and unsupported in this base.*

The example's Android build requires JDK 17 and Android SDK tools; iOS builds require the native Apple toolchain.

## Initialize

Clone into your SDK directory, then preview and rename:

```bash
dart run tool/rename_package.dart my_company_sdk --dry-run
make rename NAME=my_company_sdk
```

Rename updates the package identity, barrels, imports, and documentation; it leaves the checkout directory and remote unchanged. Follow the existing [Git workflow](docs/GIT_FLOW.md) for a derived SDK.

## Prepare

Run `make pub-get`. The independent example host's `make example-generate` resolves example dependencies, generates providers, and formats its Dart sources; the SDK package has no codegen.

## Verify

Choose the risk level in [Verification](docs/VERIFICATION.md). Local verification prepares the example before checking package/example behavior; `make format-check` itself is read-only. Package quality and existing committed-HEAD consumer requirements are separate evidence.

## Run the example

Run `flutter run` from `example/` on an Android/iOS device or emulator. Use `make example-build` for an Android debug build, defaulting to the device's arm64 ABI. The host integration and usage examples are retained in [Architecture](docs/ARCHITECTURE.md#installation).

## Further reading

- [Agent workflow](AGENTS.md) and [Git workflow](docs/GIT_FLOW.md)
- [Architecture and host usage](docs/ARCHITECTURE.md), [Standards and tests](docs/STANDARD.md)
- [Verification](docs/VERIFICATION.md)

Licensed under [MIT](LICENSE).
