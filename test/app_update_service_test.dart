import 'package:browser/features/browser/services/app_update_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUpdateService Version Comparison Tests', () {
    final service = AppUpdateService.instance;

    test('Detects newer patch version', () {
      expect(service.isVersionNewer('1.0.4', '1.0.3'), isTrue);
      expect(service.isVersionNewer('v1.0.4', '1.0.3'), isTrue);
      expect(service.isVersionNewer('1.0.4', 'v1.0.3'), isTrue);
      expect(service.isVersionNewer('v1.0.4', 'v1.0.3'), isTrue);
    });

    test('Detects newer minor and major versions', () {
      expect(service.isVersionNewer('1.1.0', '1.0.9'), isTrue);
      expect(service.isVersionNewer('2.0.0', '1.9.9'), isTrue);
      expect(service.isVersionNewer('1.10.0', '1.9.0'), isTrue);
    });

    test('Detects older or same versions as not newer', () {
      expect(service.isVersionNewer('1.0.3', '1.0.3'), isFalse);
      expect(service.isVersionNewer('v1.0.3', '1.0.3'), isFalse);
      expect(service.isVersionNewer('1.0.2', '1.0.3'), isFalse);
      expect(service.isVersionNewer('1.0.0', '1.0.4'), isFalse);
      expect(service.isVersionNewer('0.9.9', '1.0.0'), isFalse);
    });

    test('Handles versions with build numbers or non-numeric suffixes', () {
      expect(service.isVersionNewer('1.0.4+4', '1.0.3+3'), isTrue);
      expect(service.isVersionNewer('1.0.4-beta', '1.0.3'), isTrue);
      expect(service.isVersionNewer('1.0.3', '1.0.3+3'), isFalse);
    });
  });
}
