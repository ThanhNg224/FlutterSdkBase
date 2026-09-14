import 'package:flutter/material.dart';
import 'package:flutter_sdk_base/flutter_sdk_base.dart';
import 'package:flutter_sdk_base/flutter_sdk_base_testing.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'flutter_sdk_base example',
    theme: ThemeData(colorSchemeSeed: const Color(0xFF1E56A0), useMaterial3: true),
    home: const HealthPage(),
  );
}

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  // A real host points this at its own API and supplies a real key. The fake
  // transport keeps this example runnable with no backend.
  late final FakeSdkHttpTransport _transport = FakeSdkHttpTransport();
  late final SdkClient _sdk = SdkClient(
    config: SdkConfig(
      baseUri: Uri.parse('https://api.example.com'),
      apiKey: 'example-key',
    ),
    transport: _transport,
  );

  String _message = 'Tap check to call the SDK.';
  bool _isBusy = false;

  @override
  void dispose() {
    _sdk.close();
    super.dispose();
  }

  Future<void> _check({required int statusCode, required String body}) async {
    setState(() {
      _isBusy = true;
    });
    _transport.enqueueJson(body, statusCode: statusCode);

    try {
      final SdkHealth health = await _sdk.health.check();
      setState(() => _message = 'API reports "${health.status}" at ${health.checkedAt}.');
    } on SdkException catch (error) {
      setState(() => _message = _copyFor(error.failure));
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  // Host-owned copy. The SDK deliberately never produces user-facing text.
  String _copyFor(SdkFailure failure) => switch (failure.code) {
    SdkErrorCodes.unauthorized => 'Your API key was rejected.',
    SdkErrorCodes.rateLimited => 'Too many requests — try again shortly.',
    SdkErrorCodes.server => 'The service is having trouble. Try again.',
    SdkErrorCodes.timeout => 'That took too long. Check your connection.',
    SdkErrorCodes.transport => 'We could not reach the service.',
    _ => 'Something went wrong (${failure.code}).',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('SDK health')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(_message, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isBusy ? null : () => _check(statusCode: 200, body: '{"status":"ok"}'),
              child: const Text('Check health'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isBusy ? null : () => _check(statusCode: 401, body: '{}'),
              child: const Text('Simulate rejected key'),
            ),
          ],
        ),
      ),
    ),
  );
}
