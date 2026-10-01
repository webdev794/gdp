/// The website this app talks to — the only place its address lives.
///
/// When the client's own domain is ready, either change the default below or
/// build with:  flutter build apk --dart-define=SITE_URL=https://client-domain.com
/// (no trailing slash; include a sub-path such as /gdp if the site uses one).
class AppConfig {
  /// Store name used until Admin -> Store settings loads (the live name comes
  /// from there). Change it here for a rebrand; native app names are listed in
  /// flutter_app/README.md.
  static const String storeName = 'TUDEE SHOPPING CENTER';

  static const String siteUrl = String.fromEnvironment(
    'SITE_URL',
    defaultValue: 'https://testcaresortwork.co.in/gdp',
  );

  static String get apiUrl => '$siteUrl/api';

  /// Scheme + host only, e.g. https://testcaresortwork.co.in
  static String get origin => Uri.parse(siteUrl).origin;

  /// Absolute URL for a path the API returns ("/api/media/file/..." or "img/x.png").
  static String media(String path) {
    if (path.isEmpty || path.startsWith('http')) return path;
    return '$siteUrl${path.startsWith('/') ? '' : '/'}$path';
  }
}
