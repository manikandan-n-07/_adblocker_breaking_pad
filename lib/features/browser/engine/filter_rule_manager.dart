import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/filter_rule.dart';
import 'adguard_filter_rules.dart';
import 'cosmetic_filter.dart';
import 'filter_list_parser.dart';

class FilterRuleManager extends ChangeNotifier {
  static const String _prefAdBlocking = 'pref_ad_blocking_enabled';
  static const String _prefTrackerBlocking = 'pref_tracker_blocking_enabled';
  static const String _prefYouTubeBlocking = 'pref_youtube_blocking_enabled';
  static const String _prefPopupBlocking = 'pref_popup_blocking_enabled';
  static const String _prefCosmeticFiltering = 'pref_cosmetic_filtering_enabled';
  static const String _prefAllowlist = 'pref_filter_allowlist';
  static const String _prefCustomRules = 'pref_filter_custom_rules';
  static const String _prefLastUpdate = 'pref_filter_last_update';

  bool _isAdBlockingEnabled = true;
  bool _isTrackerBlockingEnabled = true;
  bool _isYouTubeBlockingEnabled = true;
  bool _isPopupBlockingEnabled = true;
  bool _isCosmeticFilteringEnabled = true;

  final Set<String> _allowlist = {};
  final List<FilterRule> _customRules = [];

  // Active compiled in-memory rules
  final Set<String> _adDomains = {};
  final Set<String> _trackerDomains = {};
  final Set<String> _popupDomains = {};
  final List<RegExp> _adUrlRegexes = [];
  final List<RegExp> _trackerUrlRegexes = [];
  final List<RegExp> _youtubeUrlRegexes = [];
  final List<String> _cosmeticSelectors = [];

  DateTime? _lastUpdate;

  bool get isAdBlockingEnabled => _isAdBlockingEnabled;
  bool get isTrackerBlockingEnabled => _isTrackerBlockingEnabled;
  bool get isYouTubeBlockingEnabled => _isYouTubeBlockingEnabled;
  bool get isPopupBlockingEnabled => _isPopupBlockingEnabled;
  bool get isCosmeticFilteringEnabled => _isCosmeticFilteringEnabled;
  Set<String> get allowlist => Set.unmodifiable(_allowlist);
  List<FilterRule> get customRules => List.unmodifiable(_customRules);
  DateTime? get lastUpdate => _lastUpdate;

  Set<String> get adDomains => _adDomains;
  Set<String> get trackerDomains => _trackerDomains;
  Set<String> get popupDomains => _popupDomains;
  List<RegExp> get adUrlRegexes => _adUrlRegexes;
  List<RegExp> get trackerUrlRegexes => _trackerUrlRegexes;
  List<RegExp> get youtubeUrlRegexes => _youtubeUrlRegexes;
  List<String> get cosmeticSelectors => _cosmeticSelectors;

  Future<void> init() async {
    await _loadPreferences();
    await _loadDefaultRules();
    _recompileRules();
    notifyListeners();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isAdBlockingEnabled = prefs.getBool(_prefAdBlocking) ?? true;
      _isTrackerBlockingEnabled = prefs.getBool(_prefTrackerBlocking) ?? true;
      _isYouTubeBlockingEnabled = prefs.getBool(_prefYouTubeBlocking) ?? true;
      _isPopupBlockingEnabled = prefs.getBool(_prefPopupBlocking) ?? true;
      _isCosmeticFilteringEnabled = prefs.getBool(_prefCosmeticFiltering) ?? true;

      final allowlistList = prefs.getStringList(_prefAllowlist) ?? [];
      _allowlist.addAll(allowlistList.map((e) => e.toLowerCase()));

      final customRulesJson = prefs.getStringList(_prefCustomRules) ?? [];
      _customRules.clear();
      for (final ruleJson in customRulesJson) {
        try {
          _customRules.add(FilterRule.fromMap(jsonDecode(ruleJson)));
        } catch (_) {}
      }

      final lastUpdateStr = prefs.getString(_prefLastUpdate);
      if (lastUpdateStr != null) {
        _lastUpdate = DateTime.tryParse(lastUpdateStr);
      }
    } catch (e) {
      debugPrint('FilterRuleManager loadPreferences error: $e');
    }
  }

  Future<void> _loadDefaultRules() async {
    // Seed domain sets from AdGuardFilterRules
    _adDomains.addAll(AdGuardFilterRules.defaultAdDomains);
    _trackerDomains.addAll(AdGuardFilterRules.defaultTrackerDomains);
    _popupDomains.addAll(AdGuardFilterRules.defaultPopupDomains);

    // Seed default regex patterns
    for (final pattern in AdGuardFilterRules.defaultAdUrlPatterns) {
      _adUrlRegexes.add(RegExp(RegExp.escape(pattern), caseSensitive: false));
    }
    for (final pattern in AdGuardFilterRules.defaultTrackerUrlPatterns) {
      _trackerUrlRegexes.add(RegExp(RegExp.escape(pattern), caseSensitive: false));
    }
    for (final pattern in AdGuardFilterRules.defaultYouTubeAdPatterns) {
      _youtubeUrlRegexes.add(AdGuardFilterRules.wildcardToRegex(pattern));
    }

    // Try loading bundled asset JSON
    try {
      final jsonString = await rootBundle.loadString('assets/filters/default_rules.json');
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      if (data['cosmeticSelectors'] is List) {
        for (final sel in data['cosmeticSelectors']) {
          if (sel is String && !_cosmeticSelectors.contains(sel)) {
            _cosmeticSelectors.add(sel);
          }
        }
      }

      // Merge extended hard-coded selectors (covers Indian news sites, sticky ads, etc.)
      for (final sel in CosmeticFilter.getExtendedSelectors()) {
        if (!_cosmeticSelectors.contains(sel)) {
          _cosmeticSelectors.add(sel);
        }
      }

      final categories = data['categories'] as Map<String, dynamic>?;
      if (categories != null) {
        if (categories['ads']?['domains'] is List) {
          for (final d in categories['ads']['domains']) {
            _adDomains.add(d.toString().toLowerCase());
          }
        }
        if (categories['trackers']?['domains'] is List) {
          for (final d in categories['trackers']['domains']) {
            _trackerDomains.add(d.toString().toLowerCase());
          }
        }
      }
    } catch (e) {
      debugPrint('Default rules asset load notice: $e');
      // Fallback cosmetic selectors — use the full extended set
      for (final sel in CosmeticFilter.getExtendedSelectors()) {
        if (!_cosmeticSelectors.contains(sel)) {
          _cosmeticSelectors.add(sel);
        }
      }
    }
  }

  void _recompileRules() {
    // Process custom rules into active sets
    for (final rule in _customRules) {
      if (!rule.enabled) continue;

      if (rule.ruleType == FilterRuleType.cosmeticHide) {
        if (!_cosmeticSelectors.contains(rule.rawPattern)) {
          _cosmeticSelectors.add(rule.rawPattern);
        }
      } else if (rule.ruleType == FilterRuleType.networkBlock) {
        if (rule.targetDomain != null) {
          switch (rule.category) {
            case FilterCategory.trackers:
              _trackerDomains.add(rule.targetDomain!.toLowerCase());
              break;
            case FilterCategory.popups:
              _popupDomains.add(rule.targetDomain!.toLowerCase());
              break;
            default:
              _adDomains.add(rule.targetDomain!.toLowerCase());
          }
        } else if (rule.isRegex) {
          try {
            final reg = RegExp(rule.rawPattern, caseSensitive: false);
            _adUrlRegexes.add(reg);
          } catch (_) {}
        }
      }
    }
  }

  // Toggles
  Future<void> setAdBlocking(bool enabled) async {
    _isAdBlockingEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefAdBlocking, enabled);
    notifyListeners();
  }

  Future<void> setTrackerBlocking(bool enabled) async {
    _isTrackerBlockingEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefTrackerBlocking, enabled);
    notifyListeners();
  }

  Future<void> setYouTubeBlocking(bool enabled) async {
    _isYouTubeBlockingEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefYouTubeBlocking, enabled);
    notifyListeners();
  }

  Future<void> setPopupBlocking(bool enabled) async {
    _isPopupBlockingEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefPopupBlocking, enabled);
    notifyListeners();
  }

  Future<void> setCosmeticFiltering(bool enabled) async {
    _isCosmeticFilteringEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefCosmeticFiltering, enabled);
    notifyListeners();
  }

  // Allowlist controls
  bool isDomainAllowlisted(String domain) {
    final lower = domain.toLowerCase();
    if (_allowlist.contains(lower)) return true;
    for (final allowed in _allowlist) {
      if (lower == allowed || lower.endsWith('.$allowed')) {
        return true;
      }
    }
    return false;
  }

  Future<void> toggleDomainAllowlist(String domain) async {
    final lower = domain.toLowerCase();
    if (_allowlist.contains(lower)) {
      _allowlist.remove(lower);
    } else {
      _allowlist.add(lower);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefAllowlist, _allowlist.toList());
    notifyListeners();
  }

  // Custom Rules
  Future<void> addCustomRule(String rawRule) async {
    final parsed = FilterListParser.parseRule(rawRule);
    if (parsed != null) {
      _customRules.add(parsed);
      await _saveCustomRules();
      _recompileRules();
      notifyListeners();
    }
  }

  Future<void> removeCustomRule(String id) async {
    _customRules.removeWhere((r) => r.id == id);
    await _saveCustomRules();
    _recompileRules();
    notifyListeners();
  }

  Future<void> _saveCustomRules() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _customRules.map((r) => jsonEncode(r.toMap())).toList();
    await prefs.setStringList(_prefCustomRules, list);
  }

  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefAdBlocking);
    await prefs.remove(_prefTrackerBlocking);
    await prefs.remove(_prefYouTubeBlocking);
    await prefs.remove(_prefPopupBlocking);
    await prefs.remove(_prefCosmeticFiltering);
    await prefs.remove(_prefAllowlist);
    await prefs.remove(_prefCustomRules);

    _isAdBlockingEnabled = true;
    _isTrackerBlockingEnabled = true;
    _isYouTubeBlockingEnabled = true;
    _isPopupBlockingEnabled = true;
    _isCosmeticFilteringEnabled = true;
    _allowlist.clear();
    _customRules.clear();

    _loadDefaultRules();
    _recompileRules();
    notifyListeners();
  }
}
