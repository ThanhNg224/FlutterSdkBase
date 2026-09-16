#!/bin/sh

set -eu

usage() {
  printf '%s\n' 'Usage: tool/verify_packaged_example.sh --platform android|ios' >&2
}

fail() {
  printf 'packaged-example: %s\n' "$1" >&2
  exit 1
}

if [ "$#" -ne 2 ] || [ "$1" != '--platform' ]; then
  usage
  exit 2
fi

platform=$2
case "$platform" in
  android|ios) ;;
  *)
    usage
    exit 2
    ;;
esac

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || fail 'must run inside a Git repository'

tmp_root=$(mktemp -d "${TMPDIR:-/tmp}/flutter-sdk-base-packaged.XXXXXX")
cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT HUP INT TERM

archive="$tmp_root/repository.tar"
sdk_stage="$tmp_root/sdk"
consumer_stage="$tmp_root/consumer"
consumer_reference="$tmp_root/consumer-reference"
mkdir -p "$sdk_stage" "$consumer_stage" "$consumer_reference"

printf '%s\n' 'Creating SDK and consumer inputs from git archive HEAD.'
git -C "$repo_root" archive --format=tar HEAD > "$archive" || fail 'git archive HEAD failed'
tar -xf "$archive" -C "$sdk_stage"
tar -xf "$archive" -C "$consumer_stage"
tar -xf "$archive" -C "$consumer_reference"

test -f "$sdk_stage/.pubignore" || fail 'archived .pubignore is missing'
test -f "$sdk_stage/pubspec.yaml" || fail 'archived SDK pubspec.yaml is missing'
test -f "$consumer_stage/example/pubspec.yaml" || fail 'archived example pubspec.yaml is missing'
test -d "$consumer_stage/example/lib" || fail 'archived example lib/ is missing'
test -d "$consumer_reference/example/lib" || fail 'archived example reference lib/ is missing'

validate_pubignore() {
  pubignore=$1

  while IFS= read -r pattern || [ -n "$pattern" ]; do
    case "$pattern" in
      ''|'#'*) continue ;;
    esac

    case "$pattern" in
      *'!'*|*'*'*|*'?'*|*'['*|*']'*|*\\*|*' '*|*'	'*)
        fail "unsupported .pubignore pattern: $pattern"
        ;;
    esac

    case "$pattern" in
      */) entry=${pattern%/} ;;
      *) entry=$pattern ;;
    esac

    case "$entry" in
      ''|.|..|/*|*/*|*'..'*|./*|*'/./'*|*'/../'*)
        fail "unsafe non-top-level .pubignore entry: $pattern"
        ;;
    esac
  done < "$pubignore"
}

validate_pubignore "$sdk_stage/.pubignore"

while IFS= read -r pattern || [ -n "$pattern" ]; do
  case "$pattern" in
    ''|'#'*) continue ;;
  esac
  case "$pattern" in
    */) entry=${pattern%/} ;;
    *) entry=$pattern ;;
  esac
  if [ -e "$sdk_stage/$entry" ] || [ -L "$sdk_stage/$entry" ]; then
    rm -rf "$sdk_stage/$entry"
  fi
done < "$sdk_stage/.pubignore"

# The example is a consumer fixture, not part of the SDK package snapshot.
rm -rf "$sdk_stage/example"
test -f "$sdk_stage/lib/flutter_sdk_base.dart" || fail 'publishable SDK snapshot is missing its public barrel'
test ! -e "$sdk_stage/docs" || fail 'publishable SDK snapshot still contains docs/'
test ! -e "$sdk_stage/tool" || fail 'publishable SDK snapshot still contains tool/'

consumer="$consumer_stage/example"
reference="$consumer_reference/example"
pubspec="$consumer/pubspec.yaml"
staged_pubspec="$tmp_root/pubspec.yaml"

# Rewrite exactly the expected path dependency in the staged consumer.
awk -v replacement="$sdk_stage" '
  /^  flutter_sdk_base:[[:space:]]*$/ {
    in_sdk_dependency = 1
    dependency_count++
    print
    next
  }
  /^[^[:space:]]/ { in_sdk_dependency = 0 }
  in_sdk_dependency && /^[[:space:]]+path:[[:space:]]*\.\.[\/][[:space:]]*$/ {
    print "    path: " replacement
    path_count++
    next
  }
  { print }
  END {
    if (dependency_count != 1 || path_count != 1) exit 42
  }
' "$pubspec" > "$staged_pubspec" || fail 'example must contain exactly one flutter_sdk_base path dependency on ../'
mv "$staged_pubspec" "$pubspec"

config="$consumer/.dart_tool/package_config.json"
validator="$tmp_root/validate_package_config.dart"
cat > "$validator" <<'DART'
import 'dart:convert';
import 'dart:io';

Never fail(String message) => throw StateError(message);

void main(List<String> args) {
  if (args.length != 3) fail('invalid package-config validator arguments');

  final configFile = File(args[0]).absolute;
  final expectedRoot = Directory(args[1]).resolveSymbolicLinksSync();
  final raw = configFile.readAsStringSync();
  final checkoutUri = Directory(args[2]).absolute.uri.toString();
  if (raw.contains(args[2]) || raw.contains(checkoutUri)) {
    fail('package config contains the checkout path');
  }

  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic> || decoded['packages'] is! List) {
    fail('package config has an unexpected shape');
  }
  final packages = (decoded['packages'] as List).whereType<Map>();
  final matches = packages.where((package) => package['name'] == 'flutter_sdk_base').toList();
  if (matches.length != 1) fail('flutter_sdk_base is not resolved exactly once');

  final rootUriText = matches.single['rootUri'];
  if (rootUriText is! String) fail('flutter_sdk_base rootUri is missing');
  final resolvedUri = configFile.uri.resolve(rootUriText);
  if (resolvedUri.scheme != 'file') fail('flutter_sdk_base rootUri is not a file URI');
  final actualRoot = Directory.fromUri(resolvedUri).resolveSymbolicLinksSync();
  if (actualRoot != expectedRoot) {
    fail('flutter_sdk_base does not resolve to the staged SDK');
  }

  stdout.writeln('package_config resolves flutter_sdk_base to the staged SDK');
  stdout.writeln('package_config contains no checkout path');
}
DART

printf '%s\n' 'Resolving the staged consumer dependency.'
(
  cd "$consumer"
  flutter pub get
)
test -f "$config" || fail 'flutter pub get did not create package_config.json'
dart "$validator" "$config" "$sdk_stage" "$repo_root" || fail 'package resolution validation failed'

printf '%s\n' 'Regenerating and checking archived example sources.'
(
  cd "$consumer"
  dart run build_runner build
  dart format --output=none --set-exit-if-changed lib
)
if ! diff -ruN "$reference/lib" "$consumer/lib" >/dev/null; then
  fail 'generated consumer lib/ differs from the archived example source'
fi

printf '%s\n' 'Running staged consumer analysis and tests.'
(
  cd "$consumer"
  flutter analyze --fatal-infos
  flutter test -j 8
)

case "$platform" in
  android)
    grep -Fq 'minSdk = flutter.minSdkVersion' "$consumer/android/app/build.gradle.kts" \
      || fail 'example Android minSdk is not inherited from Flutter'
    printf '%s\n' 'Building staged Android consumer (debug, no device claim).'
    (
      cd "$consumer"
      flutter build apk --debug
    )
    ;;
  ios)
    grep -Fq 'IPHONEOS_DEPLOYMENT_TARGET = 15.0;' "$consumer/ios/Runner.xcodeproj/project.pbxproj" \
      || fail 'example iOS deployment target is not 15.0'
    printf '%s\n' 'Building staged iOS consumer (debug, no device claim).'
    (
      cd "$consumer"
      flutter build ios --debug --no-codesign
    )
    ;;
esac

printf 'packaged-example: %s gate passed\n' "$platform"
