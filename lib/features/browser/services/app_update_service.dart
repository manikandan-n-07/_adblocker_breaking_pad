import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../services/download_service.dart';
import '../utils/browser_constants.dart';

class AppReleaseInfo {
  final String tagName;
  final String version;
  final String title;
  final String changelog;
  final String htmlUrl;
  final String? apkDownloadUrl;
  final String? apkFileName;
  final int? apkSize;
  final DateTime? publishedAt;
  final bool isNewer;

  const AppReleaseInfo({
    required this.tagName,
    required this.version,
    required this.title,
    required this.changelog,
    required this.htmlUrl,
    this.apkDownloadUrl,
    this.apkFileName,
    this.apkSize,
    this.publishedAt,
    required this.isNewer,
  });

  String get formattedSize {
    if (apkSize == null || apkSize! <= 0) return '';
    final mb = apkSize! / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

class AppUpdateService {
  static final AppUpdateService instance = AppUpdateService._internal();
  AppUpdateService._internal();

  static const String repoOwner = 'manikandan-n-07';
  static const String repoName = '_adblocker_breaking_pad';
  static const String apiUrl = 'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';
  static const String releasesWebUrl = 'https://github.com/$repoOwner/$repoName/releases';

  AppReleaseInfo? _cachedRelease;
  DateTime? _lastChecked;

  AppReleaseInfo? get cachedRelease => _cachedRelease;
  DateTime? get lastChecked => _lastChecked;

  /// Compares semantic versions (e.g., '1.0.1' > '1.0.0')
  bool isVersionNewer(String latest, String current) {
    try {
      final cleanLatest = latest.replaceAll(RegExp(r'[^0-9.]'), '');
      final cleanCurrent = current.replaceAll(RegExp(r'[^0-9.]'), '');

      final latestParts = cleanLatest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final currentParts = cleanCurrent.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final maxLen = latestParts.length > currentParts.length ? latestParts.length : currentParts.length;

      for (int i = 0; i < maxLen; i++) {
        final l = i < latestParts.length ? latestParts[i] : 0;
        final c = i < currentParts.length ? currentParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
    } catch (_) {}
    return false;
  }

  /// Fetches latest release metadata from GitHub
  Future<AppReleaseInfo?> fetchLatestRelease() async {
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'BREAKING-PAD-Browser/${BrowserConstants.appVersion}',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final tagName = data['tag_name'] as String? ?? '';
        final cleanVersion = tagName.replaceFirst(RegExp(r'^[vV]'), '');
        final title = data['name'] as String? ?? tagName;
        final body = data['body'] as String? ?? 'No release notes provided.';
        final htmlUrl = data['html_url'] as String? ?? releasesWebUrl;

        String? apkUrl;
        String? apkName;
        int? apkSize;

        final assets = data['assets'] as List<dynamic>?;
        if (assets != null) {
          for (final asset in assets) {
            final name = asset['name'] as String? ?? '';
            if (name.toLowerCase().endsWith('.apk')) {
              apkUrl = asset['browser_download_url'] as String?;
              apkName = name;
              apkSize = asset['size'] as int?;
              break;
            }
          }
        }

        final publishedAtStr = data['published_at'] as String?;
        final publishedAt = publishedAtStr != null ? DateTime.tryParse(publishedAtStr) : null;
        final isNewer = isVersionNewer(cleanVersion, BrowserConstants.appVersion);

        final release = AppReleaseInfo(
          tagName: tagName,
          version: cleanVersion,
          title: title,
          changelog: body,
          htmlUrl: htmlUrl,
          apkDownloadUrl: apkUrl,
          apkFileName: apkName ?? 'breaking_pad_v$cleanVersion.apk',
          apkSize: apkSize,
          publishedAt: publishedAt,
          isNewer: isNewer,
        );

        _cachedRelease = release;
        _lastChecked = DateTime.now();
        return release;
      }
    } catch (e) {
      debugPrint('AppUpdateService error: $e');
    }
    return null;
  }

  /// Checks for updates and prompts the user with a monochrome dialog
  Future<void> checkAndPromptUpdate(
    BuildContext context, {
    bool notifyIfLatest = false,
  }) async {
    if (notifyIfLatest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Checking for updates...'),
            ],
          ),
          duration: Duration(seconds: 1),
          backgroundColor: BrowserConstants.surface,
        ),
      );
    }

    final release = await fetchLatestRelease();

    if (!context.mounted) return;

    if (release != null && release.isNewer) {
      _showUpdateDialog(context, release);
    } else if (release != null && !release.isNewer) {
      if (notifyIfLatest) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${BrowserConstants.appName} is up to date (v${BrowserConstants.appVersion})',
            ),
            backgroundColor: BrowserConstants.surface,
          ),
        );
      }
    } else if (notifyIfLatest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not check for updates. Please try again later.'),
          backgroundColor: BrowserConstants.surface,
        ),
      );
    }
  }

  void _showUpdateDialog(BuildContext context, AppReleaseInfo release) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrowserConstants.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white, width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.system_update_alt, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Update Available',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: BrowserConstants.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: BrowserConstants.borderLight),
              ),
              child: Text(
                'v${BrowserConstants.appVersion}  ➔  ${release.tagName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            if (release.formattedSize.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Download size: ${release.formattedSize}',
                style: const TextStyle(color: BrowserConstants.textSecondary, fontSize: 11),
              ),
            ],
            const SizedBox(height: 14),
            const Text(
              'WHAT\'S NEW:',
              style: TextStyle(
                color: BrowserConstants.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: BrowserConstants.border),
                  ),
                  child: Text(
                    release.changelog.trim().isEmpty ? 'Performance improvements and bug fixes.' : release.changelog,
                    style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later', style: TextStyle(color: BrowserConstants.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await _performUpdate(context, release);
            },
            icon: const Icon(Icons.download, size: 18, color: Colors.black),
            label: const Text(
              'Update Now',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performUpdate(BuildContext context, AppReleaseInfo release) async {
    final apkUrl = release.apkDownloadUrl;
    if (apkUrl != null && apkUrl.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Starting download of ${release.apkFileName}...'),
          backgroundColor: BrowserConstants.surface,
        ),
      );

      // Download APK file via browser DownloadService
      await DownloadService.instance.startDownload(
        apkUrl,
        suggestedFilename: release.apkFileName,
      );
    } else {
      // Fallback: open release page in browser
      final uri = Uri.parse(release.htmlUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}
