import 'package:flutter/material.dart';

/// Displays one read-only host diagnostic value.
final class DiagnosticTile extends StatelessWidget {
  /// Creates a diagnostic tile with [label] and [value].
  const DiagnosticTile({required this.label, required this.value, super.key});

  /// The diagnostic label.
  final String label;

  /// The diagnostic value.
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(label),
    subtitle: Text(value),
  );
}
