import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import '../engine/adguard_engine.dart';
import '../utils/url_helper.dart';

class BrowserNavigation {
  /// Evaluates URL requests before loading (shouldOverrideUrlLoading)
  static Future<NavigationActionPolicy> handleNavigationAction(
    InAppWebViewController controller,
    NavigationAction navigationAction,
  ) async {
    final uri = navigationAction.request.url;
    if (uri == null) return NavigationActionPolicy.ALLOW;

    final urlString = uri.toString();

    // Check external scheme (mailto, tel, sms, intent, etc.)
    if (UrlHelper.isExternalScheme(urlString)) {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('Failed to launch external scheme: $e');
      }
      return NavigationActionPolicy.CANCEL;
    }

    // Network AdGuard evaluation for main frame navigations
    final isBlocked = AdGuardEngine.instance.networkFilter
        .shouldBlockUrl(urlString, pageUrl: urlString)
        .isBlocked;

    if (isBlocked) {
      return NavigationActionPolicy.CANCEL;
    }

    return NavigationActionPolicy.ALLOW;
  }

  /// Handles SSL certificate validation requests.
  static Future<ServerTrustAuthResponse?> handleReceivedServerTrustAuthRequest(
    InAppWebViewController controller,
    URLAuthenticationChallenge challenge,
  ) async {
    return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
  }
}
