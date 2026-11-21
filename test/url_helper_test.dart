import 'package:flutter_test/flutter_test.dart';
import 'package:browser/features/browser/utils/url_helper.dart';

void main() {
  group('UrlHelper Tests', () {
    test('Prefixes https to plain domains', () {
      expect(UrlHelper.sanitizeOrSearchUrl('flutter.dev'), equals('https://flutter.dev'));
      expect(UrlHelper.sanitizeOrSearchUrl('example.com'), equals('https://example.com'));
      expect(UrlHelper.sanitizeOrSearchUrl('sub.domain.co.uk'), equals('https://sub.domain.co.uk'));
    });

    test('Preserves existing http and https protocols', () {
      expect(UrlHelper.sanitizeOrSearchUrl('http://example.com'), equals('http://example.com'));
      expect(UrlHelper.sanitizeOrSearchUrl('https://example.com'), equals('https://example.com'));
    });

    test('Converts multi-word queries to Google search URL', () {
      final result = UrlHelper.sanitizeOrSearchUrl('flutter mobile browser');
      expect(result, equals('https://www.google.com/search?q=flutter%20mobile%20browser'));
    });

    test('Converts plain words with special characters to search query', () {
      final result = UrlHelper.sanitizeOrSearchUrl('hello world!');
      expect(result.startsWith('https://www.google.com/search?q='), isTrue);
    });

    test('Extracts base domain cleanly', () {
      expect(UrlHelper.extractDomain('https://www.google.com/search?q=test'), equals('google.com'));
      expect(UrlHelper.extractDomain('https://m.youtube.com/watch?v=123'), equals('m.youtube.com'));
      expect(UrlHelper.extractDomain('http://localhost:8080/app'), equals('localhost'));
    });

    test('Detects HTTPS security accurately', () {
      expect(UrlHelper.isSecure('https://secure-bank.com'), isTrue);
      expect(UrlHelper.isSecure('http://insecure.com'), isFalse);
    });

    test('Detects external protocol schemes', () {
      expect(UrlHelper.isExternalScheme('mailto:test@example.com'), isTrue);
      expect(UrlHelper.isExternalScheme('tel:+1234567890'), isTrue);
      expect(UrlHelper.isExternalScheme('sms:+1234567890'), isTrue);
      expect(UrlHelper.isExternalScheme('market://details?id=com.example'), isTrue);
      expect(UrlHelper.isExternalScheme('https://www.google.com'), isFalse);
    });
  });
}
