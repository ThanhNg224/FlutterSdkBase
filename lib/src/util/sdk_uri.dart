/// URI helpers shared by SDK services.
abstract final class SdkUri {
  /// Appends [path] to [base] without discarding the base's own path.
  ///
  /// `Uri.resolve` would turn `https://host/v1` + `health` into
  /// `https://host/health`, silently dropping the API version. This does not.
  static Uri join(Uri base, String path) {
    final String basePath = base.path.endsWith('/') ? base.path.substring(0, base.path.length - 1) : base.path;
    final String suffix = path.startsWith('/') ? path : '/$path';
    return base.replace(path: '$basePath$suffix');
  }
}
