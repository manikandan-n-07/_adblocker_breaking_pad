import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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

  static const String _prefDismissedUpdateTag = 'pref_dismissed_update_tag';
  static const String _prefDismissedUpdateTime = 'pref_dismissed_update_time';

  AppReleaseInfo? _cachedRelease;
  DateTime? _lastChecked;

  AppReleaseInfo? get cachedRelease => _cachedRelease;
  DateTime? get lastChecked => _lastChecked;

  /// Compares semantic versions (e.g., '1.0.4' > '1.0.3')
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
        if (assets != null && assets.isNotEmpty) {
          // Look for matching APK: prefer version-specific or latest APK
          for (final asset in assets) {
            final name = (asset['name'] as String? ?? '').toLowerCase();
            if (name.endsWith('.apk')) {
              if (name.contains(cleanVersion.toLowerCase()) || name.contains('latest')) {
                apkUrl = asset['browser_download_url'] as String?;
                apkName = asset['name'] as String?;
                apkSize = asset['size'] as int?;
                break;
              } else if (apkUrl == null) {
                apkUrl = asset['browser_download_url'] as String?;
                apkName = asset['name'] as String?;
                apkSize = asset['size'] as int?;
              }
            }
          }
        }

        // Direct fallback asset URL if assets list hasn't populated yet
        if (apkUrl == null && tagName.isNotEmpty) {
          apkUrl = 'https://github.com/$repoOwner/$repoName/releases/download/$tagName/breaking_pad_browser_$tagName.apk';
          apkName = 'breaking_pad_browser_$tagName.apk';
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
          apkFileName: apkName ?? 'breaking_pad_browser_v$cleanVersion.apk',
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

  /// Checks for updates and prompts the user with an update dialog
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
      // If auto-checking on startup, respect 24-hour snooze if user dismissed previously
      if (!notifyIfLatest) {
        final shouldShow = await _shouldPromptAutoUpdate(release.tagName);
        if (!shouldShow) return;
      }

      if (context.mounted) {
        _showUpdateDialog(context, release);
      }
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

  Future<bool> _shouldPromptAutoUpdate(String tagName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissedTag = prefs.getString(_prefDismissedUpdateTag);
      final dismissedTimeMs = prefs.getInt(_prefDismissedUpdateTime);

      if (dismissedTag == tagName && dismissedTimeMs != null) {
        final dismissedTime = DateTime.fromMillisecondsSinceEpoch(dismissedTimeMs);
        if (DateTime.now().difference(dismissedTime).inHours < 24) {
          return false; // Snoozed for 24h
        }
      }
    } catch (_) {}
    return true;
  }

  Future<void> _recordDismissal(String tagName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefDismissedUpdateTag, tagName);
      await prefs.setInt(_prefDismissedUpdateTime, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
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
              decoration: const BoxDecoration(
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
            onPressed: () {
              _recordDismissal(release.tagName);
              Navigator.pop(ctx);
            },
            child: const Text('Later', style: TextStyle(color: BrowserConstants.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _showDownloadAndInstallDialog(context, release);
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

  /// Displays live download progress and triggers APK package installation upon completion
  void _showDownloadAndInstallDialog(BuildContext context, AppReleaseInfo release) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        String status = 'downloading'; // 'downloading', 'completed', 'failed'
        double progress = 0.0;
        int receivedBytes = 0;
        int totalBytes = release.apkSize ?? 0;
        String? downloadedFilePath;
        String? errorMessage;
        bool isCancelled = false;

        http.Client? client;
        IOSink? sink;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            void startDownload() async {
              final downloadUrl = release.apkDownloadUrl;
              if (downloadUrl == null || downloadUrl.isEmpty) {
                setDialogState(() {
                  status = 'failed';
                  errorMessage = 'Direct APK download URL is not available.';
                });
                return;
              }

              try {
                Directory? baseDir;
                if (Platform.isAndroid) {
                  baseDir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
                } else {
                  baseDir = await getApplicationDocumentsDirectory();
                }

                final updateDir = Directory(p.join(baseDir.path, 'updates'));
                if (!await updateDir.exists()) {
                  await updateDir.create(recursive: true);
                }

                final targetFilename = release.apkFileName ?? 'breaking_pad_${release.tagName}.apk';
                final filePath = p.join(updateDir.path, targetFilename);
                final file = File(filePath);
                if (await file.exists()) {
                  try {
                    await file.delete();
                  } catch (_) {}
                }

                client = http.Client();
                final request = http.Request('GET', Uri.parse(downloadUrl));
                request.headers['User-Agent'] = 'BREAKING-PAD-Browser/${BrowserConstants.appVersion}';
                request.headers['Accept'] = 'application/octet-stream, */*';
                request.followRedirects = true;
                request.maxRedirects = 10;

                final response = await client!.send(request);

                if (response.statusCode >= 200 && response.statusCode < 300) {
                  final contentLength = response.contentLength ?? (release.apkSize ?? 0);
                  if (contentLength > 0) {
                    totalBytes = contentLength;
                  }

                  sink = file.openWrite();
                  int currentReceived = 0;

                  await for (final chunk in response.stream) {
                    if (isCancelled) {
                      await sink?.flush();
                      await sink?.close();
                      sink = null;
                      if (await file.exists()) await file.delete();
                      return;
                    }
                    sink!.add(chunk);
                    currentReceived += chunk.length;

                    setDialogState(() {
                      receivedBytes = currentReceived;
                      if (totalBytes > 0) {
                        progress = (currentReceived / totalBytes).clamp(0.0, 1.0);
                      }
                    });
                  }

                  await sink?.flush();
                  await sink?.close();
                  sink = null;

                  if (!isCancelled) {
                    downloadedFilePath = filePath;
                    setDialogState(() {
                      status = 'completed';
                      progress = 1.0;
                    });

                    // Prompt APK installation immediately
                    if (context.mounted) {
                      await installApk(filePath, context: context);
                    } else {
                      await installApk(filePath);
                    }
                  }
                } else {
                  if (!isCancelled) {
                    setDialogState(() {
                      status = 'failed';
                      errorMessage = 'Server returned HTTP ${response.statusCode}';
                    });
                  }
                }
              } catch (e) {
                if (!isCancelled) {
                  setDialogState(() {
                    status = 'failed';
                    errorMessage = e.toString();
                  });
                }
              } finally {
                try {
                  await sink?.close();
                } catch (_) {}
                client?.close();
              }
            }

            // Start download automatically once on dialog creation
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (status == 'downloading' && receivedBytes == 0 && !isCancelled) {
                startDownload();
              }
            });

            String sizeText = '';
            if (totalBytes > 0) {
              final recMb = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
              final totMb = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
              final pct = (progress * 100).toInt();
              sizeText = '$recMb MB / $totMb MB ($pct%)';
            } else if (receivedBytes > 0) {
              final recMb = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
              sizeText = '$recMb MB downloaded';
            }

            return AlertDialog(
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
                      color: status == 'completed'
                          ? Colors.green
                          : (status == 'failed' ? Colors.orange : Colors.white),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      status == 'completed'
                          ? Icons.check
                          : (status == 'failed' ? Icons.warning_amber_rounded : Icons.downloading),
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      status == 'completed'
                          ? 'Ready to Install'
                          : (status == 'failed' ? 'Download Failed' : 'Updating BREAKING PAD'),
                      style: const TextStyle(
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
                  Text(
                    'Version: ${release.tagName}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  if (status == 'downloading') ...[
                    LinearProgressIndicator(
                      value: totalBytes > 0 ? progress : null,
                      backgroundColor: BrowserConstants.surfaceLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Downloading APK...',
                          style: const TextStyle(color: BrowserConstants.textSecondary, fontSize: 12),
                        ),
                        Text(
                          sizeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ] else if (status == 'completed') ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade700),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Download Complete!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Opening Android installer... If prompted, enable "Install unknown apps" for BREAKING PAD to finish updating.',
                            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ] else if (status == 'failed') ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade800),
                      ),
                      child: Text(
                        errorMessage ?? 'Unable to download update. Please try again or download via browser.',
                        style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                if (status == 'downloading') ...[
                  TextButton(
                    onPressed: () {
                      isCancelled = true;
                      client?.close();
                      Navigator.pop(dialogCtx);
                    },
                    child: const Text('Cancel', style: TextStyle(color: BrowserConstants.textSecondary)),
                  ),
                ] else if (status == 'completed') ...[
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text('Done', style: TextStyle(color: BrowserConstants.textSecondary)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (downloadedFilePath != null) {
                        await installApk(downloadedFilePath!, context: context);
                      }
                    },
                    icon: const Icon(Icons.install_mobile, size: 18, color: Colors.black),
                    label: const Text(
                      'Install Now',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ] else if (status == 'failed') ...[
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text('Cancel', style: TextStyle(color: BrowserConstants.textSecondary)),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      final fallbackUrl = release.apkDownloadUrl ?? release.htmlUrl;
                      final uri = Uri.parse(fallbackUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: const Text('Download via Browser', style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setDialogState(() {
                        status = 'downloading';
                        progress = 0.0;
                        receivedBytes = 0;
                        errorMessage = null;
                        isCancelled = false;
                      });
                      startDownload();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Retry', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  /// Launches the native Android package installer for a downloaded APK file
  Future<void> installApk(String filePath, {BuildContext? context}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('Install APK: file does not exist at $filePath');
        return;
      }

      final result = await OpenFilex.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );

      debugPrint('OpenFilex install result: ${result.type} - ${result.message}');

      if (result.type == ResultType.permissionDenied && context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please allow "Install unknown apps" permission for BREAKING PAD to install the update.',
            ),
            duration: Duration(seconds: 5),
            backgroundColor: BrowserConstants.surface,
          ),
        );
      }
    } catch (e) {
      debugPrint('installApk error: $e');
    }
  }
}
