import 'package:flutter/material.dart';
import '../models/browser_tab.dart';
import '../utils/browser_constants.dart';

class BrowserBottomBar extends StatelessWidget {
  final BrowserTab? tab;
  final int tabCount;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onHome;
  final VoidCallback onTabs;
  final VoidCallback onMenu;

  const BrowserBottomBar({
    super.key,
    required this.tab,
    required this.tabCount,
    required this.onBack,
    required this.onForward,
    required this.onHome,
    required this.onTabs,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final canBack = tab?.canGoBack ?? false;
    final canForward = tab?.canGoForward ?? false;

    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: BrowserConstants.surface,
        border: Border(
          top: BorderSide(color: BrowserConstants.border, width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Back Button
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: canBack ? Colors.white : BrowserConstants.textSecondary.withValues(alpha: 0.3),
            ),
            onPressed: canBack ? onBack : null,
          ),

          // Forward Button
          IconButton(
            icon: Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: canForward ? Colors.white : BrowserConstants.textSecondary.withValues(alpha: 0.3),
            ),
            onPressed: canForward ? onForward : null,
          ),

          // Home Button
          IconButton(
            icon: const Icon(
              Icons.home_outlined,
              size: 22,
              color: Colors.white,
            ),
            onPressed: onHome,
          ),

          // Tabs Switcher Counter Button
          InkWell(
            onTap: onTabs,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 1.8),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '$tabCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Menu Button
          IconButton(
            icon: const Icon(
              Icons.more_vert,
              size: 22,
              color: Colors.white,
            ),
            onPressed: onMenu,
          ),
        ],
      ),
    );
  }
}
