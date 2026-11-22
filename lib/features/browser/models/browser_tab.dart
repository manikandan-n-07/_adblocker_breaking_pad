import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class BrowserTab {
  final String id;
  String url;
  String title;
  String? favicon;
  bool isLoading;
  double progress;
  bool isDesktopMode;
  bool isIncognito;
  bool canGoBack;
  bool canGoForward;
  InAppWebViewController? webViewController;
  int blockedCount;
  String? errorMessage;
  final DateTime createdAt;

  BrowserTab({
    required this.id,
    this.url = 'https://www.google.com',
    this.title = 'New Tab',
    this.favicon,
    this.isLoading = false,
    this.progress = 0.0,
    this.isDesktopMode = false,
    this.isIncognito = false,
    this.canGoBack = false,
    this.canGoForward = false,
    this.webViewController,
    this.blockedCount = 0,
    this.errorMessage,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  BrowserTab copyWith({
    String? id,
    String? url,
    String? title,
    String? favicon,
    bool? isLoading,
    double? progress,
    bool? isDesktopMode,
    bool? isIncognito,
    bool? canGoBack,
    bool? canGoForward,
    InAppWebViewController? webViewController,
    int? blockedCount,
    String? errorMessage,
  }) {
    final tab = BrowserTab(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      favicon: favicon ?? this.favicon,
      isLoading: isLoading ?? this.isLoading,
      progress: progress ?? this.progress,
      isDesktopMode: isDesktopMode ?? this.isDesktopMode,
      isIncognito: isIncognito ?? this.isIncognito,
      canGoBack: canGoBack ?? this.canGoBack,
      canGoForward: canGoForward ?? this.canGoForward,
      webViewController: webViewController ?? this.webViewController,
      blockedCount: blockedCount ?? this.blockedCount,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt,
    );
    return tab;
  }
}
