class UrlHelper {
  static final RegExp _ipRegex = RegExp(
    r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(?::\d+)?$',
  );

  static final RegExp _domainRegex = RegExp(
    r'^(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(?::\d+)?(?:/.*)?$',
    caseSensitive: false,
  );

  static final RegExp _localhostRegex = RegExp(
    r'^localhost(?::\d+)?(?:/.*)?$',
    caseSensitive: false,
  );

  /// Converts a user search query or raw address into a valid navigable URL.
  static String sanitizeOrSearchUrl(
    String input, {
    String searchEngineTemplate = 'https://www.google.com/search?q={query}',
  }) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 'about:blank';

    // Internal scheme support
    if (trimmed.startsWith('about:') ||
        trimmed.startsWith('chrome://') ||
        trimmed.startsWith('file://') ||
        trimmed.startsWith('data:') ||
        trimmed.startsWith('javascript:')) {
      return trimmed;
    }

    // Already has standard http/https scheme
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    // Check if input contains whitespace -> definitely a search query
    if (trimmed.contains(' ')) {
      final encoded = Uri.encodeComponent(trimmed);
      return searchEngineTemplate.replaceAll('{query}', encoded);
    }

    // Check if looks like domain or IP or localhost
    if (_domainRegex.hasMatch(trimmed) ||
        _ipRegex.hasMatch(trimmed) ||
        _localhostRegex.hasMatch(trimmed)) {
      return 'https://$trimmed';
    }

    // Default to search query
    final encoded = Uri.encodeComponent(trimmed);
    return searchEngineTemplate.replaceAll('{query}', encoded);
  }

  /// Extracts the base domain name (e.g., "youtube.com" from "https://m.youtube.com/watch?v=123")
  static String extractDomain(String rawUrl) {
    if (rawUrl.isEmpty) return '';
    try {
      final uri = Uri.parse(rawUrl);
      var host = uri.host.toLowerCase();
      if (host.startsWith('www.')) {
        host = host.substring(4);
      }
      return host;
    } catch (_) {
      return '';
    }
  }

  /// Checks if URL uses secure HTTPS
  static bool isSecure(String rawUrl) {
    try {
      final uri = Uri.parse(rawUrl);
      return uri.scheme.toLowerCase() == 'https';
    } catch (_) {
      return false;
    }
  }

  /// Returns clean favicon URL for a given domain or URL using Google Favicon API
  static String getFaviconUrl(String rawUrl) {
    final domain = extractDomain(rawUrl);
    if (domain.isEmpty) return '';
    return 'https://www.google.com/s2/favicons?domain=$domain&sz=64';
  }

  /// Check if the scheme is an external protocol (e.g. mailto, tel, sms, intent, market)
  static bool isExternalScheme(String rawUrl) {
    try {
      final uri = Uri.parse(rawUrl);
      final scheme = uri.scheme.toLowerCase();
      return scheme == 'mailto' ||
          scheme == 'tel' ||
          scheme == 'sms' ||
          scheme == 'market' ||
          scheme == 'intent' ||
          scheme == 'whatsapp' ||
          scheme == 'tg';
    } catch (_) {
      return false;
    }
  }
}
