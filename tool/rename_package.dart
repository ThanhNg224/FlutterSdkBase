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

  final List<String> files = _trackedTextFiles();
  final List<String> rewritten = <String>[];

  for (final String path in files) {
    final File file = File(path);
    final String original = file.readAsStringSync();
    if (!original.contains(currentName)) {
      continue;
    }
    rewritten.add(path);
    if (!isDryRun) {
      file.writeAsStringSync(original.replaceAll(currentName, newName));
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

  print(
    '\nNext: run `make verify`, then `cd example && flutter pub get`.\n'
    'The checkout directory and the git remote are unchanged — rename those yourself.',
  );
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
