import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/browser_tab.dart';
import '../utils/browser_constants.dart';

class BrowserConfiguration {
  /// Builds InAppWebViewSettings customized for a specific tab
  static InAppWebViewSettings buildSettings(BrowserTab tab) {
    return InAppWebViewSettings(
      // JavaScript & Content
      javaScriptEnabled: true,
      javaScriptCanOpenWindowsAutomatically: true,
      supportMultipleWindows: false, // Ensures search result links with target="_blank" open seamlessly
      allowsInlineMediaPlayback: true,
      mediaPlaybackRequiresUserGesture: false,

      // Navigation & Interception
      useShouldOverrideUrlLoading: true,
      useShouldInterceptRequest: true, // Core for Android ad-blocking engine
      useOnDownloadStart: true,

      // Desktop Mode & User Agent
      userAgent: tab.isDesktopMode
          ? BrowserConstants.desktopUserAgent
          : BrowserConstants.mobileUserAgent,

      // Cache & Incognito
      incognito: tab.isIncognito,
      cacheEnabled: !tab.isIncognito,
      clearCache: tab.isIncognito,

      // Zoom & Viewport
      useWideViewPort: tab.isDesktopMode,
      loadWithOverviewMode: tab.isDesktopMode,
      supportZoom: true,
      builtInZoomControls: tab.isDesktopMode,
      displayZoomControls: false,

      // Security
      mixedContentMode: MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
    );
  }
}
