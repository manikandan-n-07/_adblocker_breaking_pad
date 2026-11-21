import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../engine/adguard_engine.dart';
import '../services/filter_update_service.dart';
import '../utils/browser_constants.dart';

class PrivacyDashboardScreen extends StatefulWidget {
  const PrivacyDashboardScreen({super.key});

  @override
  State<PrivacyDashboardScreen> createState() => _PrivacyDashboardScreenState();
}

class _PrivacyDashboardScreenState extends State<PrivacyDashboardScreen> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final engine = AdGuardEngine.instance;

    return ListenableBuilder(
      listenable: engine,
      builder: (builderContext, _) {
        final stats = engine.statistics;
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
            title: const Row(
              children: [
                Icon(Icons.shield, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text(
                  'Privacy Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
                tooltip: 'Reset Statistics',
                onPressed: () async {
                  await stats.clearStatistics();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Statistics cleared')),
                    );
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Main Shield Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: BrowserConstants.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: BrowserConstants.surfaceLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white),
                      ),
                      child: const Icon(
                        Icons.verified_user,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${stats.totalBlocked}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Total Threats & Ads Blocked Locally',
                      style: TextStyle(
                        color: BrowserConstants.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Categories Grid
              const Text(
                'FILTER CATEGORIES',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard(
                    title: 'Ads Filtered',
                    count: '${stats.adsBlocked}',
                    icon: Icons.block,
                    enabled: ruleManager.isAdBlockingEnabled,
                    onToggle: (v) => ruleManager.setAdBlocking(v),
                  ),
                  _buildStatCard(
                    title: 'Trackers Filtered',
                    count: '${stats.trackersBlocked}',
                    icon: Icons.track_changes,
                    enabled: ruleManager.isTrackerBlockingEnabled,
                    onToggle: (v) => ruleManager.setTrackerBlocking(v),
                  ),
                  _buildStatCard(
                    title: 'YouTube Ads Mitigated',
                    count: '${stats.youtubeBlocked}',
                    icon: Icons.play_circle_outline,
                    enabled: ruleManager.isYouTubeBlockingEnabled,
                    onToggle: (v) => ruleManager.setYouTubeBlocking(v),
                  ),
                  _buildStatCard(
                    title: 'Popups Blocked',
                    count: '${stats.popupsBlocked}',
                    icon: Icons.open_in_new_off,
                    enabled: ruleManager.isPopupBlockingEnabled,
                    onToggle: (v) => ruleManager.setPopupBlocking(v),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Filter Update Status Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BrowserConstants.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: BrowserConstants.borderLight),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sync, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Local Filter Engine',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            ruleManager.lastUpdate != null
                                ? 'Updated: ${DateFormat.yMMMd().add_jm().format(ruleManager.lastUpdate!)}'
                                : 'Using built-in AdGuard engine rules',
                            style: const TextStyle(
                              color: BrowserConstants.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isUpdating
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              setState(() => _isUpdating = true);
                              final success = await FilterUpdateService.updateFilterRules(ruleManager);
                              if (!mounted) return;
                              setState(() => _isUpdating = false);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Filter rules updated successfully!'
                                        : 'Offline or server error. Retaining local rules.',
                                  ),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      child: _isUpdating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Text('Update', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Allowlisted Websites
              if (ruleManager.allowlist.isNotEmpty) ...[
                const Text(
                  'EXCLUDED SITES (ALLOWLIST)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: BrowserConstants.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BrowserConstants.borderLight),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ruleManager.allowlist.length,
                    separatorBuilder: (_, _) => const Divider(color: BrowserConstants.border, height: 1),
                    itemBuilder: (ctx, index) {
                      final domain = ruleManager.allowlist.elementAt(index);
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.language, size: 20, color: Colors.white),
                        title: Text(domain, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.white),
                          onPressed: () {
                            ruleManager.toggleDomainAllowlist(domain);
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Real Live Activity Log
              const Text(
                'RECENT ENGINE ACTIVITY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 10),

              if (stats.recentBlocked.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: BrowserConstants.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BrowserConstants.borderLight),
                  ),
                  child: const Center(
                    child: Text(
                      'No threats blocked yet. Browse to observe live engine filtering.',
                      style: TextStyle(color: BrowserConstants.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: BrowserConstants.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: BrowserConstants.borderLight),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: stats.recentBlocked.length,
                    separatorBuilder: (_, _) => const Divider(color: BrowserConstants.border, height: 1),
                    itemBuilder: (ctx, index) {
                      final item = stats.recentBlocked[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.shield_outlined,
                          size: 20,
                          color: Colors.white,
                        ),
                        title: Text(
                          item.domain.isEmpty ? item.url : item.domain,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${item.category.name.toUpperCase()} • ${DateFormat.Hms().format(item.timestamp)}',
                          style: const TextStyle(color: BrowserConstants.textSecondary, fontSize: 11),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: BrowserConstants.surfaceLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: BrowserConstants.borderLight),
                          ),
                          child: const Text(
                            'BLOCKED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required bool enabled,
    required ValueChanged<bool> onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BrowserConstants.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrowserConstants.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              Switch(
                value: enabled,
                activeThumbColor: Colors.white,
                onChanged: onToggle,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: BrowserConstants.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
