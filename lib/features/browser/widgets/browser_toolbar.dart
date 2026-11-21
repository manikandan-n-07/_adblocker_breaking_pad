import 'package:flutter/material.dart';
import '../models/browser_tab.dart';
import '../utils/browser_constants.dart';
import 'browser_address_bar.dart';

class BrowserToolbar extends StatelessWidget {
  final BrowserTab tab;
  final ValueChanged<String> onNavigate;
  final VoidCallback onReload;
  final VoidCallback onStop;

  const BrowserToolbar({
    super.key,
    required this.tab,
    required this.onNavigate,
    required this.onReload,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // Private mode badge if incognito
          if (tab.isIncognito)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: BrowserConstants.surfaceLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: BrowserConstants.border),
                ),
                child: const Icon(
                  Icons.visibility_off,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),

          // Address Bar
          Expanded(
            child: BrowserAddressBar(
              tab: tab,
              onNavigate: onNavigate,
              onReload: onReload,
              onStop: onStop,
            ),
          ),
        ],
      ),
    );
  }
}
