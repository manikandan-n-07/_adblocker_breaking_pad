import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../models/browser_tab.dart';
import '../utils/browser_constants.dart';

class BrowserConfiguration {
  /// Builds InAppWebViewSettings customized for a specific tab
  static InAppWebViewSettings buildSettings(BrowserTab tab) {
    final isSpotify = tab.url.contains('spotify.com');
    final useDesktop = tab.isDesktopMode || isSpotify;

    return InAppWebViewSettings(
      // JavaScript & Content
      javaScriptEnabled: true,
      javaScriptCanOpenWindowsAutomatically: true,
      supportMultipleWindows: false,
      allowsInlineMediaPlayback: true,
      mediaPlaybackRequiresUserGesture: false,

      // Storage & Databases (CRITICAL for Spotify EME / Widevine DRM / Local Authentication)
      domStorageEnabled: true,
      databaseEnabled: true,
      thirdPartyCookiesEnabled: true,
      allowFileAccess: true,
      allowContentAccess: true,

      // Background audio / media playback (keeps playing when app is minimized)
      allowBackgroundAudioPlaying: true,

      // Navigation & Interception
      useShouldOverrideUrlLoading: true,
      useShouldInterceptRequest: true,
      useOnDownloadStart: true,

      // Desktop Mode & User Agent
      // Automatically provide Desktop Chrome User-Agent for Spotify so it doesn't block mobile playback
      userAgent: useDesktop
          ? BrowserConstants.desktopUserAgent
          : BrowserConstants.mobileUserAgent,

      // Cache & Incognito
      incognito: tab.isIncognito,
      cacheEnabled: !tab.isIncognito,
      clearCache: tab.isIncognito,

      // Zoom & Viewport
      useWideViewPort: useDesktop,
      loadWithOverviewMode: useDesktop,
      supportZoom: true,
      builtInZoomControls: useDesktop,
      displayZoomControls: false,

      // Security & DRM streaming
      mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
    );
  }
}
