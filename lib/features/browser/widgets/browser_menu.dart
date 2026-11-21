import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/browser_tab.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/browser_settings_screen.dart';
import '../screens/downloads_screen.dart';
import '../screens/history_screen.dart';
import '../screens/privacy_dashboard_screen.dart';
import '../services/app_update_service.dart';
import '../services/bookmark_service.dart';
import '../utils/browser_constants.dart';
import '../webview/browser_controller.dart';

class BrowserMenu extends StatefulWidget {
  final BrowserTab tab;
  final BrowserController controller;

  const BrowserMenu({
    super.key,
    required this.tab,
    required this.controller,
  });

  static void show(BuildContext context, BrowserTab tab, BrowserController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => BrowserMenu(tab: tab, controller: controller),
    );
  }

  @override
  State<BrowserMenu> createState() => _BrowserMenuState();
}

class _BrowserMenuState extends State<BrowserMenu> {
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _checkBookmark();
  }

  Future<void> _checkBookmark() async {
    final bookmarked = await BookmarkService.instance.isBookmarked(widget.tab.url);
    if (mounted) {
      setState(() {
        _isBookmarked = bookmarked;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isBookmarked) {
      await BookmarkService.instance.removeBookmarkByUrl(widget.tab.url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bookmark removed'), duration: Duration(seconds: 1)),
        );
      }
    } else {
      await BookmarkService.instance.addBookmark(
        title: widget.tab.title.isEmpty ? widget.tab.url : widget.tab.title,
        url: widget.tab.url,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Page bookmarked!'), duration: Duration(seconds: 1)),
        );
      }
    }
    _checkBookmark();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: BrowserConstants.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white, width: 1.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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

          // Quick Action Icons Row (Bookmark, Share, Copy URL, Reload)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BrowserConstants.borderLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAction(
                  icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  label: _isBookmarked ? 'Saved' : 'Bookmark',
                  onTap: _toggleBookmark,
                ),
                _buildQuickAction(
                  icon: Icons.copy,
                  label: 'Copy URL',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.tab.url));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('URL copied to clipboard!'), duration: Duration(seconds: 1)),
                    );
                  },
                ),
                _buildQuickAction(
                  icon: Icons.refresh,
                  label: 'Reload',
                  onTap: () {
                    Navigator.pop(context);
                    widget.tab.webViewController?.reload();
                  },
                ),
                _buildQuickAction(
                  icon: Icons.shield,
                  label: 'Shield',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrivacyDashboardScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Main Menu Items
          _buildMenuItem(
            icon: Icons.add_box_outlined,
            title: 'New Tab',
            onTap: () {
              Navigator.pop(context);
              widget.controller.addNewTab();
            },
          ),
          _buildMenuItem(
            icon: Icons.visibility_off_outlined,
            title: 'New Private Tab',
            onTap: () {
              Navigator.pop(context);
              widget.controller.addNewTab(isIncognito: true);
            },
          ),
          const Divider(color: BrowserConstants.border, height: 16),

          _buildMenuItem(
            icon: Icons.bookmarks_outlined,
            title: 'Bookmarks',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookmarksScreen(
                    onSelectBookmark: (url) {
                      widget.controller.navigate(url);
                    },
                  ),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.history,
            title: 'History',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HistoryScreen(
                    onSelectHistory: (url) {
                      widget.controller.navigate(url);
                    },
                  ),
                ),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.download_outlined,
            title: 'Downloads',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DownloadsScreen()),
              );
            },
          ),

          const Divider(color: BrowserConstants.border, height: 16),

          // Desktop Site Toggle
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: const Icon(Icons.desktop_mac_outlined, color: Colors.white, size: 22),
            title: const Text('Desktop Site', style: TextStyle(color: Colors.white, fontSize: 15)),
            trailing: Switch(
              value: widget.tab.isDesktopMode,
              activeThumbColor: Colors.white,
              onChanged: (_) {
                widget.controller.toggleDesktopMode();
                setState(() {});
              },
            ),
          ),

          _buildMenuItem(
            icon: Icons.system_update_outlined,
            title: 'Check for Updates',
            onTap: () {
              Navigator.pop(context);
              AppUpdateService.instance.checkAndPromptUpdate(context, notifyIfLatest: true);
            },
          ),
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BrowserSettingsScreen(controller: widget.controller)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: Colors.white),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(icon, color: Colors.white, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      onTap: onTap,
    );
  }
}
