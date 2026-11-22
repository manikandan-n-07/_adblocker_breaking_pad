import 'package:flutter/material.dart';
import '../engine/adguard_engine.dart';
import '../services/app_update_service.dart';
import '../services/history_service.dart';
import '../services/theme_service.dart';
import '../utils/browser_constants.dart';
import '../webview/browser_controller.dart';
import 'privacy_dashboard_screen.dart';

class BrowserSettingsScreen extends StatefulWidget {
  final BrowserController? controller;

  const BrowserSettingsScreen({super.key, this.controller});

  @override
  State<BrowserSettingsScreen> createState() => _BrowserSettingsScreenState();
}

class _BrowserSettingsScreenState extends State<BrowserSettingsScreen> {
  final engine = AdGuardEngine.instance;
  late final BrowserController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? BrowserController();
    _controller.init();
    _controller.addListener(_onControllerChange);
    ThemeService.instance.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    ThemeService.instance.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  void _showHomepageDialog(BrowserController controller) {
    final textController = TextEditingController(text: controller.homepage);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrowserConstants.surface,
        title: const Text('Change Homepage', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: textController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Leave empty for Home Screen, or enter URL',
            hintStyle: TextStyle(color: BrowserConstants.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: BrowserConstants.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = textController.text.trim();
              await controller.setHomepage(newUrl);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSearchEngineDialog(BrowserController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrowserConstants.surface,
        title: const Text('Search Engine', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: BrowserConstants.searchEngines.keys.map((engineName) {
            final isSelected = controller.searchEngine == engineName;
            return ListTile(
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: Colors.white,
              ),
              title: Text(engineName, style: const TextStyle(color: Colors.white)),
              onTap: () async {
                await controller.setSearchEngine(engineName);
                if (ctx.mounted) Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAddCustomRuleDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrowserConstants.surface,
        title: const Text('Add Filter Rule', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Supports AdGuard syntax (e.g. ||badads.com^ or ##.ad-banner)',
              style: TextStyle(color: BrowserConstants.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '||example.com^',
                hintStyle: TextStyle(color: BrowserConstants.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: BrowserConstants.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final rule = textController.text.trim();
              if (rule.isNotEmpty) {
                await engine.ruleManager.addCustomRule(rule);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            child: const Text('Add Rule', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrowserConstants.surface,
        title: const Text('Clear Browsing Data', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will clear history, cookies, cached filter data and bookmarks.',
          style: TextStyle(color: BrowserConstants.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: BrowserConstants.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await HistoryService.instance.clearAll();
              await engine.statistics.clearStatistics();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Browsing data cleared')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            child: const Text('Clear All', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([engine, ThemeService.instance]),
      builder: (context, _) {
        final ruleManager = engine.ruleManager;
        final isDark = ThemeService.instance.isDark;
        final bgColor = isDark ? Colors.black : BrowserConstants.lightBackground;
        final appBarBg = isDark ? BrowserConstants.surface : BrowserConstants.lightSurface;
        final iconColor = isDark ? Colors.white : Colors.black;
        final textColor = isDark ? Colors.white : Colors.black;
        final subtitleColor = isDark ? BrowserConstants.textSecondary : BrowserConstants.lightTextSecondary;
        final dividerColor = isDark ? BrowserConstants.border : BrowserConstants.lightBorder;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: appBarBg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: iconColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Settings',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // 0. Appearance Section
              _buildSectionHeader('APPEARANCE', textColor: textColor),
              SwitchListTile(
                secondary: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: iconColor,
                ),
                title: Text('Dark Mode', style: TextStyle(color: textColor)),
                subtitle: Text(
                  isDark ? 'Currently using dark theme' : 'Currently using light theme',
                  style: TextStyle(color: subtitleColor),
                ),
                value: isDark,
                onChanged: (_) => ThemeService.instance.toggle(),
              ),
              Divider(color: dividerColor),

              // 1. General Section
              _buildSectionHeader('GENERAL', textColor: textColor),
              ListTile(
                leading: Icon(Icons.search, color: iconColor),
                title: Text('Search Engine', style: TextStyle(color: textColor)),
                subtitle: Text(_controller.searchEngine, style: TextStyle(color: subtitleColor)),
                trailing: Icon(Icons.chevron_right, color: iconColor),
                onTap: () => _showSearchEngineDialog(_controller),
              ),
              ListTile(
                leading: Icon(Icons.home_outlined, color: iconColor),
                title: Text('Homepage', style: TextStyle(color: textColor)),
                subtitle: Text(
                  _controller.homepage.isEmpty ? 'Home Screen (Speed Dial)' : _controller.homepage,
                  style: TextStyle(color: subtitleColor),
                ),
                trailing: Icon(Icons.chevron_right, color: iconColor),
                onTap: () => _showHomepageDialog(_controller),
              ),
              Divider(color: dividerColor),

              // 2. AdGuard Engine & Protection Section
              _buildSectionHeader('ADGUARD SHIELD PROTECTION', textColor: textColor),
              ListTile(
                leading: Icon(Icons.dashboard_outlined, color: iconColor),
                title: Text('Privacy Dashboard', style: TextStyle(color: textColor)),
                subtitle: Text('View live statistics and filter status', style: TextStyle(color: subtitleColor)),
                trailing: Icon(Icons.chevron_right, color: iconColor),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyDashboardScreen()),
                  );
                },
              ),
              SwitchListTile(
                secondary: Icon(Icons.block, color: iconColor),
                title: Text('Ad Blocking', style: TextStyle(color: textColor)),
                subtitle: Text('Filter ads and banners at the network layer', style: TextStyle(color: subtitleColor)),
                value: ruleManager.isAdBlockingEnabled,
                onChanged: (v) => ruleManager.setAdBlocking(v),
              ),
              SwitchListTile(
                secondary: Icon(Icons.track_changes, color: iconColor),
                title: Text('Tracker Protection', style: TextStyle(color: textColor)),
                subtitle: Text('Block third-party tracking scripts & telemetry', style: TextStyle(color: subtitleColor)),
                value: ruleManager.isTrackerBlockingEnabled,
                onChanged: (v) => ruleManager.setTrackerBlocking(v),
              ),
              SwitchListTile(
                secondary: Icon(Icons.play_circle_outline, color: iconColor),
                title: Text('YouTube Ad Mitigation', style: TextStyle(color: textColor)),
                subtitle: Text('Auto-skip and mute video advertisements', style: TextStyle(color: subtitleColor)),
                value: ruleManager.isYouTubeBlockingEnabled,
                onChanged: (v) => ruleManager.setYouTubeBlocking(v),
              ),
              SwitchListTile(
                secondary: Icon(Icons.open_in_new_off, color: iconColor),
                title: Text('Popup Protection', style: TextStyle(color: textColor)),
                subtitle: Text('Block popups and unsolicited redirects', style: TextStyle(color: subtitleColor)),
                value: ruleManager.isPopupBlockingEnabled,
                onChanged: (v) => ruleManager.setPopupBlocking(v),
              ),
              SwitchListTile(
                secondary: Icon(Icons.brush_outlined, color: iconColor),
                title: Text('Cosmetic Filtering', style: TextStyle(color: textColor)),
                subtitle: Text('Collapse empty ad containers and overlays', style: TextStyle(color: subtitleColor)),
                value: ruleManager.isCosmeticFilteringEnabled,
                onChanged: (v) => ruleManager.setCosmeticFiltering(v),
              ),
              ListTile(
                leading: Icon(Icons.add_circle_outline, color: iconColor),
                title: Text('Add Custom Filter Rule', style: TextStyle(color: textColor)),
                subtitle: Text('Add user-defined URL or cosmetic rule', style: TextStyle(color: subtitleColor)),
                onTap: _showAddCustomRuleDialog,
              ),
              Divider(color: dividerColor),

              // 3. Privacy & Data Section
              _buildSectionHeader('PRIVACY & DATA', textColor: textColor),
              ListTile(
                leading: Icon(Icons.delete_outline, color: iconColor),
                title: Text('Clear Browsing Data', style: TextStyle(color: textColor)),
                subtitle: Text('History, cached rules, stats', style: TextStyle(color: subtitleColor)),
                onTap: _showClearDataDialog,
              ),
              Divider(color: dividerColor),

              // 4. About & Version Section
              _buildSectionHeader('ABOUT & UPDATES', textColor: textColor),
              ListTile(
                leading: Icon(Icons.info_outline, color: iconColor),
                title: Text('About BREAKING PAD Browser', style: TextStyle(color: textColor)),
                subtitle: Text('Version ${BrowserConstants.appVersion} • Standalone Local Engine', style: TextStyle(color: subtitleColor)),
              ),
              ListTile(
                leading: Icon(Icons.system_update_outlined, color: iconColor),
                title: Text('Check for Updates', style: TextStyle(color: textColor)),
                subtitle: Text('Check GitHub releases for latest version', style: TextStyle(color: subtitleColor)),
                trailing: Icon(Icons.chevron_right, color: iconColor),
                onTap: () => AppUpdateService.instance.checkAndPromptUpdate(context, notifyIfLatest: true),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
