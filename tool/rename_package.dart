// A command-line tool: printing is the entire point of it.
// ignore_for_file: avoid_print

import 'dart:io';

/// Renames this package everywhere it is referenced.
///
/// A team cloning this base needs the package to carry their own name before
/// they write a line of their own code. The name appears in `pubspec.yaml`, in
/// both barrel filenames, in every `package:` import across `lib/`, `test/` and
/// `example/`, in the boundary script, and throughout the documentation —
/// roughly forty files. Doing that by hand is how a clone ends up half-renamed.
///
/// ```sh
/// dart run tool/rename_package.dart my_company_sdk
/// dart run tool/rename_package.dart my_company_sdk --dry-run
/// ```
///
/// What it does NOT do, because neither is this tool's business: rename the
/// checkout directory, or change the git remote.
Future<void> main(List<String> arguments) async {
  final List<String> positional = arguments.where((String a) => !a.startsWith('--')).toList();
  final bool isDryRun = arguments.contains('--dry-run');
  final bool isForced = arguments.contains('--force');

  if (positional.length != 1) {
    _fail('Usage: dart run tool/rename_package.dart <new_package_name> [--dry-run] [--force]');
  }

  final String newName = positional.single;
  final String currentName = _readCurrentName();

  _validate(newName, currentName);

  if (!isDryRun && !isForced && _hasUncommittedChanges()) {
    _fail(
      'The working tree has uncommitted changes.\n'
      'Rename touches most files in the repository, so commit or stash first — '
      'that is what lets you review the rename as one diff and undo it with one '
      'command. Pass --force to proceed anyway.',
    );
  }

  // Build every change in memory first so the post-conditions below can reject
  // the whole rename before a single file is touched.
  final Map<String, String> pending = <String, String>{};

  for (final String path in _trackedTextFiles()) {
    final String original = File(path).readAsStringSync();
    if (!original.contains(currentName)) {
      continue;
    }
    final String updated = path.endsWith('pubspec.yaml')
        ? _rewritePubspec(original, currentName, newName)
        : _rewriteText(original, currentName, newName);
    if (updated != original) {
      pending[path] = updated;
    }
  }

  _checkPostConditions(pending, currentName, newName);

  final List<String> rewritten = pending.keys.toList()..sort();
  if (!isDryRun) {
    for (final MapEntry<String, String> entry in pending.entries) {
      File(entry.key).writeAsStringSync(entry.value);
    }
  }

  final Map<String, String> renames = <String, String>{
    'lib/$currentName.dart': 'lib/$newName.dart',
    'lib/${currentName}_testing.dart': 'lib/${newName}_testing.dart',
  };

  for (final MapEntry<String, String> entry in renames.entries) {
    if (!File(entry.key).existsSync()) {
      _fail('Expected barrel ${entry.key} is missing; the package layout is not what this tool assumes.');
    }
    if (!isDryRun) {
      File(entry.key).renameSync(entry.value);
    }
  }

  print('${isDryRun ? 'Would rename' : 'Renamed'} "$currentName" to "$newName".');
  print('  ${rewritten.length} file(s) containing the name:');
  for (final String path in rewritten) {
    print('    $path');
  }
  print('  2 barrel file(s):');
  for (final MapEntry<String, String> entry in renames.entries) {
    print('    ${entry.key} -> ${entry.value}');
  }

  if (isDryRun) {
    print('\nDry run: nothing was written.');
    return;
  }

  final String directory = Directory.current.path.split(Platform.pathSeparator).last;
  print(
    '\nNext:\n'
    '  make verify\n'
    '  cd example && flutter pub get && cd ..\n'
    '\n'
    'Not done for you, because neither is safe to guess — the checkout directory\n'
    'cannot be renamed from inside itself, and only you know where this should\n'
    'push:\n'
    '  cd .. && mv $directory $newName && cd $newName\n'
    '  git remote set-url origin <your repository url>',
  );
}

/// Rewrites ordinary text.
///
/// The derived names go first, because the general rule below refuses to match
/// a name that is glued to an identifier character — which is exactly what
/// `_testing` and `_example` are.
///
/// The general rule then replaces the name only where it stands alone as a
/// token. Without that boundary, renaming a package called `sdk` would rewrite
/// `sdk_client.dart` inside every import while leaving the file on disk
/// untouched, and would corrupt `NAME=my_company_sdk` in the Makefile.
String _rewriteText(String content, String current, String next) {
  final String withDerived = content
      .replaceAll('${current}_testing', '${next}_testing')
      .replaceAll('${current}_example', '${next}_example');
  final RegExp standalone = RegExp('(?<![A-Za-z0-9_])${RegExp.escape(current)}(?![A-Za-z0-9_])');
  return withDerived.replaceAll(standalone, next);
}

/// Rewrites a pubspec by whole lines rather than by substring.
///
/// A pubspec's structure is made of keys the package does not own. A package
/// named `sdk` would otherwise turn `environment:\n  sdk:` into `  <new>:` and
/// `dependencies:\n  flutter:\n    sdk: flutter` into `    <new>: flutter`,
/// destroying the Dart SDK constraint and the Flutter dependency source.
String _rewritePubspec(String content, String current, String next) {
  final List<String> lines = content.split('\n');
  for (int i = 0; i < lines.length; i++) {
    final String line = lines[i];
    if (line == 'name: $current') {
      lines[i] = 'name: $next';
    } else if (line == 'name: ${current}_example') {
      lines[i] = 'name: ${next}_example';
    } else if (line == '  $current:') {
      lines[i] = '  $next:';
    }
  }
  return lines.join('\n');
}

/// Refuses the rename if the result would not be a working package.
///
/// These are cheap assertions against the failure modes a substring rewrite
/// actually produces, checked before anything is written.
void _checkPostConditions(Map<String, String> pending, String current, String next) {
  final String? pubspec = pending['pubspec.yaml'];
  if (pubspec != null) {
    if (!pubspec.contains('name: $next')) {
      _fail('Post-condition failed: pubspec.yaml would not declare name: $next.');
    }
    if (!pubspec.contains('\n  sdk: ')) {
      _fail('Post-condition failed: the Dart SDK constraint in pubspec.yaml would be damaged.');
    }
    if (!pubspec.contains('    sdk: flutter')) {
      _fail('Post-condition failed: the Flutter dependency source in pubspec.yaml would be damaged.');
    }
  }
  for (final MapEntry<String, String> entry in pending.entries) {
    if (entry.value.contains('package:$current/')) {
      _fail('Post-condition failed: ${entry.key} would still import package:$current/.');
    }
  }
}

String _readCurrentName() {
  final File pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    _fail('No pubspec.yaml here. Run this from the package root.');
  }
  for (final String line in pubspec.readAsLinesSync()) {
    if (line.startsWith('name:')) {
      return line.substring('name:'.length).trim();
    }
  }
  _fail('pubspec.yaml has no name: field.');
}

void _validate(String newName, String currentName) {
  if (newName == currentName) {
    _fail('The package is already called "$newName".');
  }
  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(newName)) {
    _fail(
      'Invalid package name "$newName".\n'
      'Pub requires lower_snake_case: a leading lowercase letter, then '
      'lowercase letters, digits or underscores.',
    );
  }
  if (newName.endsWith('_testing')) {
    _fail('"$newName" would collide with the generated testing barrel "${newName}_testing".');
  }
  const Set<String> reserved = <String>{
    'abstract',
    'as',
    'assert',
    'async',
    'await',
    'base',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'covariant',
    'default',
    'deferred',
    'do',
    'dynamic',
    'else',
    'enum',
    'export',
    'extends',
    'extension',
    'external',
    'factory',
    'false',
    'final',
    'finally',
    'for',
    'function',
    'get',
    'hide',
    'if',
    'implements',
    'import',
    'in',
    'interface',
    'is',
    'late',
    'library',
    'mixin',
    'new',
    'null',
    'of',
    'on',
    'operator',
    'part',
    'required',
    'rethrow',
    'return',
    'sealed',
    'set',
    'show',
    'static',
    'super',
    'switch',
    'sync',
    'this',
    'throw',
    'true',
    'try',
    'typedef',
    'var',
    'void',
    'when',
    'while',
    'with',
    'yield',
  };
  if (reserved.contains(newName)) {
    _fail('"$newName" is a Dart reserved word and cannot be a library name.');
  }
  // A package cannot share a name with something it depends on: the import
  // `package:<name>/...` would become ambiguous and pub could not resolve it.
  final Set<String> dependencies = _declaredDependencies()..addAll(<String>{'dart', 'flutter'});
  if (dependencies.contains(newName)) {
    _fail(
      '"$newName" is already the name of a dependency of this package.\n'
      'Sharing the name would make package:$newName/... ambiguous. Pick another.',
    );
  }
}

/// Every package name this pubspec depends on, so a rename cannot collide.
Set<String> _declaredDependencies() {
  final Set<String> names = <String>{};
  bool inDependencies = false;
  for (final String line in File('pubspec.yaml').readAsLinesSync()) {
    if (line.startsWith('dependencies:') || line.startsWith('dev_dependencies:')) {
      inDependencies = true;
      continue;
    }
    if (line.isNotEmpty && !line.startsWith(' ')) {
      inDependencies = false;
      continue;
    }
    final RegExpMatch? match = RegExp(r'^  ([a-z][a-z0-9_]*):').firstMatch(line);
    if (inDependencies && match != null) {
      names.add(match.group(1)!);
    }
  }
  return names;
}

bool _hasUncommittedChanges() {
  final ProcessResult result = Process.runSync('git', <String>['status', '--porcelain']);
  return result.exitCode == 0 && (result.stdout as String).trim().isNotEmpty;
}

List<String> _trackedTextFiles() {
  final ProcessResult result = Process.runSync('git', <String>['ls-files']);
  if (result.exitCode != 0) {
    _fail('git ls-files failed; run this inside the repository.');
  }
  const Set<String> extensions = <String>{'.dart', '.yaml', '.yml', '.md', '.sh', '.json'};
  const Set<String> names = <String>{'Makefile', '.pubignore', '.gitignore'};
  return (result.stdout as String)
      .split('\n')
      .map((String line) => line.trim())
      .where((String line) => line.isNotEmpty)
      .where(
        (String line) => names.contains(line.split('/').last) || extensions.any((String ext) => line.endsWith(ext)),
      )
      .where((String line) => File(line).existsSync())
      .toList();
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(2);
}
