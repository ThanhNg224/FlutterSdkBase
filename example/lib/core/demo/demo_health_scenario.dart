/// Deterministic health response selected by the demo host.
enum DemoHealthScenario {
  /// Returns a successful `{"status":"ok"}` response.
  healthy,

  /// Returns an HTTP 401 response.
  unauthorized,
}
