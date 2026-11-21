import 'package:flutter/material.dart';
import '../engine/adguard_engine.dart';
import '../services/app_update_service.dart';
import '../services/history_service.dart';
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
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
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
      listenable: engine,
      builder: (context, _) {
        final ruleManager = engine.ruleManager;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: BrowserConstants.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // 1. General Section
              _buildSectionHeader('GENERAL'),
              ListTile(
                leading: const Icon(Icons.search, color: Colors.white),
                title: const Text('Search Engine', style: TextStyle(color: Colors.white)),
                subtitle: Text(_controller.searchEngine, style: const TextStyle(color: BrowserConstants.textSecondary)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white),
                onTap: () => _showSearchEngineDialog(_controller),
              ),
              ListTile(
                leading: const Icon(Icons.home_outlined, color: Colors.white),
                title: const Text('Homepage', style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  _controller.homepage.isEmpty ? 'Home Screen (Speed Dial)' : _controller.homepage,
                  style: const TextStyle(color: BrowserConstants.textSecondary),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white),
                onTap: () => _showHomepageDialog(_controller),
              ),
              const Divider(color: BrowserConstants.border),

              // 2. AdGuard Engine & Protection Section
              _buildSectionHeader('ADGUARD SHIELD PROTECTION'),
              ListTile(
                leading: const Icon(Icons.dashboard_outlined, color: Colors.white),
                title: const Text('Privacy Dashboard', style: TextStyle(color: Colors.white)),
                subtitle: const Text('View live statistics and filter status', style: TextStyle(color: BrowserConstants.textSecondary)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyDashboardScreen()),
                  );
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.block, color: Colors.white),
                title: const Text('Ad Blocking', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Filter ads and banners at the network layer', style: TextStyle(color: BrowserConstants.textSecondary)),
                value: ruleManager.isAdBlockingEnabled,
                activeThumbColor: Colors.white,
                onChanged: (v) => ruleManager.setAdBlocking(v),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.track_changes, color: Colors.white),
                title: const Text('Tracker Protection', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Block third-party tracking scripts & telemetry', style: TextStyle(color: BrowserConstants.textSecondary)),
                value: ruleManager.isTrackerBlockingEnabled,
                activeThumbColor: Colors.white,
                onChanged: (v) => ruleManager.setTrackerBlocking(v),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.play_circle_outline, color: Colors.white),
                title: const Text('YouTube Ad Mitigation', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Auto-skip and mute video advertisements', style: TextStyle(color: BrowserConstants.textSecondary)),
                value: ruleManager.isYouTubeBlockingEnabled,
                activeThumbColor: Colors.white,
                onChanged: (v) => ruleManager.setYouTubeBlocking(v),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.open_in_new_off, color: Colors.white),
                title: const Text('Popup Protection', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Block popups and unsolicited redirects', style: TextStyle(color: BrowserConstants.textSecondary)),
                value: ruleManager.isPopupBlockingEnabled,
                activeThumbColor: Colors.white,
                onChanged: (v) => ruleManager.setPopupBlocking(v),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.brush_outlined, color: Colors.white),
                title: const Text('Cosmetic Filtering', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Collapse empty ad containers and overlays', style: TextStyle(color: BrowserConstants.textSecondary)),
                value: ruleManager.isCosmeticFilteringEnabled,
                activeThumbColor: Colors.white,
                onChanged: (v) => ruleManager.setCosmeticFiltering(v),
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: Colors.white),
                title: const Text('Add Custom Filter Rule', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Add user-defined URL or cosmetic rule', style: TextStyle(color: BrowserConstants.textSecondary)),
                onTap: _showAddCustomRuleDialog,
              ),
              const Divider(color: BrowserConstants.border),

              // 3. Privacy & Data Section
              _buildSectionHeader('PRIVACY & DATA'),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.white),
                title: const Text('Clear Browsing Data', style: TextStyle(color: Colors.white)),
                subtitle: const Text('History, cached rules, stats', style: TextStyle(color: BrowserConstants.textSecondary)),
                onTap: _showClearDataDialog,
              ),
              const Divider(color: BrowserConstants.border),

              // 4. About & Version Section
              _buildSectionHeader('ABOUT & UPDATES'),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.white),
                title: const Text('About BREAKING PAD Browser', style: TextStyle(color: Colors.white)),
                subtitle: Text('Version ${BrowserConstants.appVersion} • Standalone Local Engine', style: const TextStyle(color: BrowserConstants.textSecondary)),
              ),
              ListTile(
                leading: const Icon(Icons.system_update_outlined, color: Colors.white),
                title: const Text('Check for Updates', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Check GitHub releases for latest version', style: TextStyle(color: BrowserConstants.textSecondary)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white),
                onTap: () => AppUpdateService.instance.checkAndPromptUpdate(context, notifyIfLatest: true),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
