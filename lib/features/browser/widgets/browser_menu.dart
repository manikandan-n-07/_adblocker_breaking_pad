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
import '../services/pip_service.dart';
import '../services/theme_service.dart';
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
    ThemeService.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
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
    final isDark = ThemeService.instance.isDark;
    final sheetBg = isDark ? BrowserConstants.surface : BrowserConstants.lightSurface;
    final borderTopColor = isDark ? Colors.white : Colors.black;
    final dragHandleColor = isDark ? BrowserConstants.borderLight : BrowserConstants.lightBorderLight;
    final quickBg = isDark ? Colors.black : BrowserConstants.lightBackground;
    final quickBorderColor = isDark ? BrowserConstants.borderLight : BrowserConstants.lightBorderLight;
    final iconColor = isDark ? Colors.white : Colors.black;
    final textColor = isDark ? Colors.white : Colors.black;
    final dividerColor = isDark ? BrowserConstants.border : BrowserConstants.lightBorder;
    final pipSupported = PiPService.instance.isPiPSupported;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: borderTopColor, width: 1.5)),
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
              color: dragHandleColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Quick Action Icons Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: quickBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: quickBorderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAction(
                  icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  label: _isBookmarked ? 'Saved' : 'Bookmark',
                  iconColor: iconColor,
                  onTap: _toggleBookmark,
                ),
                _buildQuickAction(
                  icon: Icons.copy,
                  label: 'Copy URL',
                  iconColor: iconColor,
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
                  iconColor: iconColor,
                  onTap: () {
                    Navigator.pop(context);
                    widget.tab.webViewController?.reload();
                  },
                ),
                _buildQuickAction(
                  icon: Icons.shield,
                  label: 'Shield',
                  iconColor: iconColor,
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

          // Dark / Light Mode Toggle
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: iconColor,
              size: 22,
            ),
            title: Text(
              isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              style: TextStyle(color: textColor, fontSize: 15),
            ),
            trailing: Switch(
              value: isDark,
              onChanged: (_) async {
                await ThemeService.instance.toggle();
              },
            ),
          ),

          Divider(color: dividerColor, height: 8),

          // PiP Button (if supported)
          if (pipSupported)
            _buildMenuItem(
              icon: Icons.picture_in_picture_alt,
              title: 'Picture-in-Picture',
              iconColor: iconColor,
              textColor: textColor,
              onTap: () async {
                Navigator.pop(context);
                await PiPService.instance.enterPiP();
              },
            ),

          _buildMenuItem(
            icon: Icons.add_box_outlined,
            title: 'New Tab',
            iconColor: iconColor,
            textColor: textColor,
            onTap: () {
              Navigator.pop(context);
              widget.controller.addNewTab();
            },
          ),
          _buildMenuItem(
            icon: Icons.visibility_off_outlined,
            title: 'New Private Tab',
            iconColor: iconColor,
            textColor: textColor,
            onTap: () {
              Navigator.pop(context);
              widget.controller.addNewTab(isIncognito: true);
            },
          ),
          Divider(color: dividerColor, height: 16),

          _buildMenuItem(
            icon: Icons.bookmarks_outlined,
            title: 'Bookmarks',
            iconColor: iconColor,
            textColor: textColor,
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
            iconColor: iconColor,
            textColor: textColor,
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
            iconColor: iconColor,
            textColor: textColor,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DownloadsScreen()),
              );
            },
          ),

          Divider(color: dividerColor, height: 16),

          // Desktop Site Toggle
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: Icon(Icons.desktop_mac_outlined, color: iconColor, size: 22),
            title: Text('Desktop Site', style: TextStyle(color: textColor, fontSize: 15)),
            trailing: Switch(
              value: widget.tab.isDesktopMode,
              onChanged: (_) {
                widget.controller.toggleDesktopMode();
                setState(() {});
              },
            ),
          ),

          _buildMenuItem(
            icon: Icons.system_update_outlined,
            title: 'Check for Updates',
            iconColor: iconColor,
            textColor: textColor,
            onTap: () {
              Navigator.pop(context);
              AppUpdateService.instance.checkAndPromptUpdate(context, notifyIfLatest: true);
            },
          ),
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            iconColor: iconColor,
            textColor: textColor,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => BrowserSettingsScreen(controller: widget.controller)),
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
    required Color iconColor,
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
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: iconColor, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color iconColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(title, style: TextStyle(color: textColor, fontSize: 15)),
      onTap: onTap,
    );
  }
}
