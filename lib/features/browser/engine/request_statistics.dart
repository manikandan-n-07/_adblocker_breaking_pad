import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/blocked_request.dart';
import '../models/filter_rule.dart';

class RequestStatistics extends ChangeNotifier {
  static const String _prefTotal = 'adblock_stats_total';
  static const String _prefAds = 'adblock_stats_ads';
  static const String _prefTrackers = 'adblock_stats_trackers';
  static const String _prefYouTube = 'adblock_stats_youtube';
  static const String _prefPopups = 'adblock_stats_popups';

  int _totalBlocked = 0;
  int _adsBlocked = 0;
  int _trackersBlocked = 0;
  int _youtubeBlocked = 0;
  int _popupsBlocked = 0;

  final List<BlockedRequest> _recentBlocked = [];
  static const int maxRecentLogs = 50;
  bool _saveScheduled = false;

  int get totalBlocked => _totalBlocked;
  int get adsBlocked => _adsBlocked;
  int get trackersBlocked => _trackersBlocked;
  int get youtubeBlocked => _youtubeBlocked;
  int get popupsBlocked => _popupsBlocked;
  List<BlockedRequest> get recentBlocked => List.unmodifiable(_recentBlocked);

  /// Initialize statistics from local persistent storage
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _totalBlocked = prefs.getInt(_prefTotal) ?? 0;
      _adsBlocked = prefs.getInt(_prefAds) ?? 0;
      _trackersBlocked = prefs.getInt(_prefTrackers) ?? 0;
      _youtubeBlocked = prefs.getInt(_prefYouTube) ?? 0;
      _popupsBlocked = prefs.getInt(_prefPopups) ?? 0;
      notifyListeners();
    } catch (e) {
      debugPrint('RequestStatistics init error: $e');
    }
  }

  /// Record an actual blocked request
  void recordBlockedRequest({
    required String url,
    required String domain,
    required FilterCategory category,
    required String ruleMatched,
  }) {
    _totalBlocked++;
    switch (category) {
      case FilterCategory.ads:
        _adsBlocked++;
        break;
      case FilterCategory.trackers:
        _trackersBlocked++;
        break;
      case FilterCategory.youtube:
        _youtubeBlocked++;
        break;
      case FilterCategory.popups:
        _popupsBlocked++;
        break;
      case FilterCategory.cosmetic:
      case FilterCategory.custom:
        _adsBlocked++;
        break;
    }

    final request = BlockedRequest(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      url: url,
      domain: domain,
      category: category,
      timestamp: DateTime.now(),
      ruleMatched: ruleMatched,
    );

    _recentBlocked.insert(0, request);
    if (_recentBlocked.length > maxRecentLogs) {
      _recentBlocked.removeLast();
    }

    _scheduleSave();
    notifyListeners();
  }

  void _scheduleSave() {
    if (_saveScheduled) return;
    _saveScheduled = true;
    Future.delayed(const Duration(seconds: 2), () {
      _saveScheduled = false;
      _saveToStorage();
    });
  }

  /// Reset all statistics
  Future<void> clearStatistics() async {
    _totalBlocked = 0;
    _adsBlocked = 0;
    _trackersBlocked = 0;
    _youtubeBlocked = 0;
    _popupsBlocked = 0;
    _recentBlocked.clear();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefTotal, 0);
      await prefs.setInt(_prefAds, 0);
      await prefs.setInt(_prefTrackers, 0);
      await prefs.setInt(_prefYouTube, 0);
      await prefs.setInt(_prefPopups, 0);
    } catch (_) {}

    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefTotal, _totalBlocked);
      await prefs.setInt(_prefAds, _adsBlocked);
      await prefs.setInt(_prefTrackers, _trackersBlocked);
      await prefs.setInt(_prefYouTube, _youtubeBlocked);
      await prefs.setInt(_prefPopups, _popupsBlocked);
    } catch (_) {}
  }
}
