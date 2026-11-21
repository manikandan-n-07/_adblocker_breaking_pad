import 'package:flutter/material.dart';
import '../engine/adguard_engine.dart';
import '../models/browser_tab.dart';
import '../screens/privacy_dashboard_screen.dart';
import '../utils/browser_constants.dart';
import '../utils/url_helper.dart';

class ProtectionShieldSheet extends StatefulWidget {
  final BrowserTab tab;

  const ProtectionShieldSheet({
    super.key,
    required this.tab,
  });

  static void show(BuildContext context, BrowserTab tab) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ProtectionShieldSheet(tab: tab),
    );
  }

  @override
  State<ProtectionShieldSheet> createState() => _ProtectionShieldSheetState();
}

class _ProtectionShieldSheetState extends State<ProtectionShieldSheet> {
  @override
  Widget build(BuildContext context) {
    final engine = AdGuardEngine.instance;
    final domain = UrlHelper.extractDomain(widget.tab.url);
    final isAllowlisted = domain.isNotEmpty && engine.ruleManager.isDomainAllowlisted(domain);
    final isProtectionActive = engine.ruleManager.isAdBlockingEnabled && !isAllowlisted;

    return Container(
      decoration: const BoxDecoration(
        color: BrowserConstants.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Colors.white, width: 1.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: BrowserConstants.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: BrowserConstants.surfaceLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white),
                ),
                child: Icon(
                  isProtectionActive ? Icons.shield : Icons.shield_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      domain.isEmpty ? 'This Page' : domain,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isProtectionActive ? 'Protected by AdGuard Engine' : 'Protection Disabled on Site',
                      style: const TextStyle(
                        color: BrowserConstants.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Statistics on this tab
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BrowserConstants.borderLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Tab Blocked', '${widget.tab.blockedCount}'),
                Container(width: 1, height: 35, color: BrowserConstants.borderLight),
                _buildStatItem('Total Ads', '${engine.statistics.adsBlocked}'),
                Container(width: 1, height: 35, color: BrowserConstants.borderLight),
                _buildStatItem('Trackers', '${engine.statistics.trackersBlocked}'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Switch for Per-Site Protection
          if (domain.isNotEmpty)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Protection on this website',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
              subtitle: Text(
                isProtectionActive
                    ? 'Ads, trackers and cosmetic elements are filtered'
                    : 'Site is whitelisted; ads are permitted',
                style: const TextStyle(color: BrowserConstants.textSecondary, fontSize: 12),
              ),
              value: !isAllowlisted,
              activeThumbColor: Colors.white,
              onChanged: (bool enabled) async {
                await engine.ruleManager.toggleDomainAllowlist(domain);
                widget.tab.webViewController?.reload();
                setState(() {});
              },
            ),

          const SizedBox(height: 12),

          // Open Full Privacy Dashboard button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyDashboardScreen()),
                );
              },
              icon: const Icon(Icons.dashboard_outlined, size: 20, color: Colors.black),
              label: const Text('Open Privacy Dashboard', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: BrowserConstants.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
