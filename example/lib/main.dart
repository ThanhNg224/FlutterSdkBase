import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sdk_base_example/app/app.dart';
import 'package:flutter_sdk_base_example/app/providers/app_providers.dart';
import 'package:flutter_sdk_base_example/core/observability/app_error_bindings.dart';

void main() {
  final ProviderContainer container = ProviderContainer();
  final AppErrorBindings bindings = AppErrorBindings(
    reporter: container.read(appErrorReporterProvider),
  );
  bindings.install();
  // The scope owns the container for the lifetime of the host application;
  // keeping the binding local avoids a mutable global observability holder.
  runApp(UncontrolledProviderScope(container: container, child: const HostApp()));
}
