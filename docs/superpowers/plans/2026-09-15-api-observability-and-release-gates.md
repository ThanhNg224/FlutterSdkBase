# API observability and release gates implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add per-operation cancellation, request observability, value equality, and package-quality release gates without widening the SDK beyond its documented boundary.

**Architecture:** The first task is one atomic public API wave. `SdkCancelToken`, `sdkVersion`, request IDs, and `SdkFailure.requestId` flow through the sole internal request executor; the health capability only forwards the token and interprets a response. The remaining tasks independently tighten package metadata and CI release evidence.

**Tech Stack:** Flutter 3.47+, Dart 3.13+, `package:http` (existing internal transport), GitHub Actions, Pana, Dartdoc.

**Spec:** `docs/superpowers/specs/2026-09-14-flutter-sdk-base-design.md`

## Global Constraints

- Dart remains `>=3.13.0 <4.0.0`; Flutter remains `>=3.47.0` with no upper bound.
- Android API 24+ and iOS 15.0+ remain the only supported release platforms.
- Do not add package dependencies. `pana` is a CI global tool only.
- Only `lib/flutter_sdk_base.dart` and `lib/flutter_sdk_base_testing.dart` are supported public API; public signatures never mention `package:http` or another implementation type.
- `SdkRequestExecutor` remains the sole request path; do not add a repository, use case, automatic retry, structured logger fields, config copy method, or separate connect timeout.
- Every commit runs `make verify` and `flutter pub publish --dry-run`; publish dry-run must report `Package has 0 warnings.`
- Use TDD: write and observe failing tests before implementation.
- Record mechanical deviations and gate-tightening fixes in `docs/superpowers/plans/EXECUTION_NOTES.md`.

**Execution order:** Run Task 1, Task 2, Task 4, Task 3, Task 5, then Task 6. Platform metadata must precede the zero-deficit Pana baseline so Pana evaluates the declared Android/iOS support rather than an intentionally incomplete pubspec. Each remains its own commit.

---

### Task 1: Atomic public API wave — cancellation, observability, and value equality

**Files:**
- Create: `lib/src/client/sdk_cancel_token.dart`, `lib/src/version/sdk_version.dart`, `test/client/sdk_cancel_token_test.dart`, `test/version/sdk_version_test.dart`
- Modify: `lib/flutter_sdk_base.dart`, `lib/src/client/sdk_request_executor.dart`, `lib/src/health/sdk_health_service.dart`, `lib/src/errors/sdk_failure.dart`, `lib/src/errors/sdk_status_mapping.dart`, `lib/src/client/sdk_config.dart`, `lib/src/health/sdk_health.dart`, existing client/health/error/public tests
- Modify documentation: `README.md`, `CHANGELOG.md`, `docs/ARCHITECTURE.md`, `docs/STANDARD.md`, `docs/superpowers/specs/2026-09-14-flutter-sdk-base-design.md`
- Create: `docs/superpowers/plans/2026-09-15-api-observability-and-release-gates.md`

**Interfaces:**
- Produces public `SdkCancelToken` with `void cancel()` and `bool get isCancelled`; `cancel()` is idempotent.
- Produces public `const String sdkVersion`, exactly `pubspec.yaml`'s `version` value.
- Changes public `Future<SdkHealth> SdkHealthService.check({SdkCancelToken? cancelToken})`.
- Changes public `SdkFailure` constructor to require non-empty `String requestId`.
- `SdkFailure ==`/`hashCode` compare code, message, retryability, status code, and request ID only; `cause` is excluded. `SdkHealth` and `SdkConfig` compare all their fields.
- Internal executor returns response plus the generated request ID to a capability, adds `X-Sdk-Version` and `X-Request-Id` before opening every call, and preserves the same ID in every failure path.

- [ ] **Step 1: Write failing consumer and unit tests**

Add barrel-only coverage proving `SdkCancelToken` and `sdkVersion` are public. Add tests that:

1. A token cancelled before `check` yields `SdkException` with code `cancelled`, a non-empty request ID, and opens no fake transport request.
2. Cancelling a token during a never-completing health request invokes the call cancellation, yields `cancelled`, leaves the client and an independent operation usable, and never closes the transport.
3. A reused token cancels all in-flight operations that deliberately share it; its `cancel()` is idempotent.
4. Every health request has `X-Sdk-Version == sdkVersion`, a lowercase hexadecimal `X-Request-Id`, and distinct request IDs on distinct operations.
5. Transport, timeout, close, token cancellation, non-2xx, and invalid-2xx failures all expose the ID sent to the fake transport.
6. `sdkVersion` equals the root `pubspec.yaml` `version:` line. The test may use `dart:io` because tests never ship.
7. Equal and unequal `SdkFailure`, `SdkHealth`, and `SdkConfig` values have correct `==` and matching/different `hashCode` behavior. A different `cause` does not affect failure equality. `SdkFailure.toString()` still excludes its cause.

- [ ] **Step 2: Run focused tests and confirm the intended failures**

Run: `flutter test test/client/sdk_cancel_token_test.dart test/version/sdk_version_test.dart test/errors/sdk_failure_test.dart test/client/sdk_config_test.dart test/health/sdk_health_service_test.dart test/public_api_test.dart`

Expected: compile failures for the missing public types, missing optional `check` argument, missing `requestId`, headers, and equality overrides.

- [ ] **Step 3: Implement SDK-owned cancellation and request execution**

Implement `SdkCancelToken` without `package:async`, Dio, static mutable state, or a transport-library type. It maintains internal listeners, invokes each once when cancelled, immediately invokes a listener registered after cancellation, and returns an internal deregistration callback.

In the executor, generate a fresh 128-bit lowercase hexadecimal request ID with `dart:math`; construct the outgoing SDK request with both mandatory headers without mutating a host-provided map. Track an active call with its ID and cancellation origin. Token cancellation must call only that call's `cancel()`, map it to `SdkErrorCodes.cancelled`, and deregister when the operation settles. Timeout, client close, token cancellation, transport error, HTTP error, and invalid successful body all retain the same ID. Do not log the ID together with credentials, headers, or bodies.

- [ ] **Step 4: Update value contracts, capability, and public barrel**

Require `requestId` in every `SdkFailure` constructor and thread it through status mapping. Implement equality/hashCode as specified above. Make health obtain the executor's returned request context so its status/parse failures retain the wire request ID; forward `cancelToken` unchanged. Export only `SdkCancelToken` and `sdkVersion` in addition to the existing production barrel surface.

- [ ] **Step 5: Update public documentation and authoritative spec**

Document best-effort per-operation cancellation, token reuse/group semantics, request ID support, `sdkVersion`, and value equality. Preserve the rule that `cause` never appears in `toString()`. Add user-visible entries to `CHANGELOG.md` under unreleased `0.1.0`.

- [ ] **Step 6: Run focused and full gates**

Run: `flutter test`, `make verify`, and `flutter pub publish --dry-run`.

Expected: all tests pass, analyzer has 0 issues, boundary passes, and publish dry-run has 0 warnings.

- [ ] **Step 7: Review and commit the complete public API wave**

Review every production-barrel export, the authoritative spec diff, and the new test coverage. Commit:

```text
feat(api): add operation cancellation, request observability and value equality
```

---

### Task 2: Remove the unread coverage artifact

**Files:**
- Modify: `.github/workflows/ci.yml`, `docs/superpowers/plans/EXECUTION_NOTES.md`

**Interfaces:**
- CI retains the test gate but stops producing an unconsumed `lcov.info` artifact.

- [ ] **Step 1: Remove only `--coverage` from the package test CI command**

Keep `flutter test` as a required CI gate. Do not introduce a coverage threshold or a coverage dependency because no consumer reads the report.

- [ ] **Step 2: Record the decision**

Add one Execution Notes line: coverage generation was removed because CI neither enforces a threshold nor uploads/reads `lcov.info`; producing it has no quality signal and wastes CI time.

- [ ] **Step 3: Run and commit**

Run `make verify` and `flutter pub publish --dry-run`, review the workflow diff, then commit:

```text
ci: remove unread coverage generation
```

---

### Task 3: Add a zero-deficit Pana gate

**Files:**
- Modify: `.github/workflows/ci.yml`, `docs/STANDARD.md`, `docs/superpowers/specs/2026-09-14-flutter-sdk-base-design.md`

**Interfaces:**
- CI installs current Pana with `dart pub global activate pana` and runs `dart pub global run pana . --exit-code-threshold 0` after package analysis and docs generation.

- [ ] **Step 1: Add Pana to the package gate**

Use the Flutter SDK's `dart` command. Keep Pana as a global CI tool rather than a pubspec dependency. The zero threshold means Pana may grant no fewer points than its reported maximum.

- [ ] **Step 2: Run the same command locally after Task 4 has declared platform metadata, and tighten remaining repository-controlled docs/metadata if Pana reports a remediable deficit**

Run:

```bash
dart pub global activate pana
dart pub global run pana . --exit-code-threshold 0
```

Only tighten material under repository control; do not lower the threshold. Record any mechanical remediation in Execution Notes.

- [ ] **Step 3: Document and commit**

Document Pana's role as the pub.dev quality gate in standards/spec, run `make verify` and publish dry-run, then commit:

```text
ci: add zero-deficit pana quality gate
```

---

### Task 4: Declare supported package platforms

**Files:**
- Modify: `pubspec.yaml`, `CHANGELOG.md`, `docs/superpowers/specs/2026-09-14-flutter-sdk-base-design.md`
- Test: `test/package_metadata_test.dart`

**Interfaces:**
- `pubspec.yaml` declares exactly:

```yaml
platforms:
  android:
  ios:
```

- [ ] **Step 1: Write the failing metadata test**

Read `pubspec.yaml` as text and assert it declares Android and iOS, no unsupported platform claim, and retains the established SDK floors.

- [ ] **Step 2: Add platform metadata and update release documentation**

Add the YAML block at the package root. Update the spec's support policy and changelog to state that pub.dev metadata now matches the Android/iOS support commitment.

- [ ] **Step 3: Verify and commit**

Run the focused metadata test, `make verify`, and publish dry-run, then commit:

```text
chore: declare android and ios package platforms
```

---

### Task 5: Test the declared Flutter floor and latest stable

**Files:**
- Modify: `.github/workflows/ci.yml`, `docs/superpowers/specs/2026-09-14-flutter-sdk-base-design.md`

**Interfaces:**
- Every CI job that selects Flutter uses `strategy.matrix.flutter: ['3.47.0', stable]` and passes `${{ matrix.flutter }}` to `subosito/flutter-action`.

- [ ] **Step 1: Convert all Flutter-consuming jobs to the shared two-version matrix**

Apply the matrix to package, archive consumer, Android, and iOS jobs. Preserve the existing job dependencies, archive proof, Android floor check, and iOS target check. Remove the obsolete single-version environment pin.

- [ ] **Step 2: Document the floor/stable evidence**

Update the spec gate text to say both the declared floor and latest stable are compiled. Do not change support floors.

- [ ] **Step 3: Verify and commit**

Review the workflow to ensure every Flutter-action expression uses the matrix, run `make verify` and publish dry-run, then commit:

```text
ci: test flutter floor and stable in a matrix
```

---

### Task 6: Gate generated API documentation

**Files:**
- Modify: `Makefile`, `.github/workflows/ci.yml`, `docs/STANDARD.md`, `docs/superpowers/specs/2026-09-14-flutter-sdk-base-design.md`

**Interfaces:**
- `make doc` runs `dart doc`; CI runs the same command and fails on unresolved documentation links.

- [ ] **Step 1: Add a Make target and CI step**

Add `doc` to `.PHONY` and a documented `doc` target that runs `dart doc`. Add a package CI step after analysis and before Pana. Generated `doc/api` is already ignored; do not commit it.

- [ ] **Step 2: Run the documentation gate and repair only broken documentation**

Run `make doc`. If it reports an actionable unresolved reference, repair the owning doc comment without changing public behavior. Do not disable Dartdoc checks.

- [ ] **Step 3: Verify and commit**

Run `make verify`, `make doc`, and publish dry-run, review the generated-doc artifact is ignored, then commit:

```text
ci: gate generated API documentation
```

---

## Final verification

```bash
make ci
./tool/check_boundaries.sh
make doc
dart pub global run pana . --exit-code-threshold 0
flutter test
flutter pub publish --dry-run
```

Confirm by hand:

- The production barrel exports `SdkCancelToken` and `sdkVersion`, without any transport implementation type.
- Every captured SDK request has both version and unique request-ID headers.
- Every `SdkFailure` failure path carries a non-empty request ID; `cause` remains absent from equality and `toString()`.
- Token cancellation does not close the client or its transport.
- `pubspec.yaml` declares only Android and iOS under `platforms:`.
- Every Flutter CI job runs at `3.47.0` and `stable`.
