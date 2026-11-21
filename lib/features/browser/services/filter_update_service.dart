import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../engine/filter_list_parser.dart';
import '../engine/filter_rule_manager.dart';
import '../models/filter_rule.dart';

class FilterUpdateService {
  static const String defaultFilterUrl =
      'https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters/filter_2_Base/filter.txt';

  /// Updates filter lists from remote source.
  /// Gracefully fails if offline, retaining last working local rules.
  static Future<bool> updateFilterRules(FilterRuleManager manager, {String? customUrl}) async {
    final targetUrl = customUrl ?? defaultFilterUrl;
    try {
      final response = await http.get(Uri.parse(targetUrl)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final rules = FilterListParser.parseRuleList(response.body);

        for (final rule in rules) {
          if (rule.ruleType == FilterRuleType.cosmeticHide) {
            if (!manager.cosmeticSelectors.contains(rule.rawPattern)) {
              manager.cosmeticSelectors.add(rule.rawPattern);
            }
          } else if (rule.targetDomain != null) {
            manager.adDomains.add(rule.targetDomain!.toLowerCase());
          }
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pref_filter_last_update', DateTime.now().toIso8601String());
        debugPrint('Successfully updated ${rules.length} filter rules.');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('FilterUpdateService network update notice (retaining local rules): $e');
      return false;
    }
  }
}
