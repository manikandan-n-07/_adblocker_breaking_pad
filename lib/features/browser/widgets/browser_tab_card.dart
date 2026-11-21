import 'package:flutter/material.dart';
import '../models/browser_tab.dart';
import '../utils/browser_constants.dart';
import '../utils/url_helper.dart';

class BrowserTabCard extends StatelessWidget {
  final BrowserTab tab;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const BrowserTabCard({
    super.key,
    required this.tab,
    required this.isSelected,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final domain = UrlHelper.extractDomain(tab.url);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: BrowserConstants.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : BrowserConstants.borderLight,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Favicon + Title + Close button
            Row(
              children: [
                Icon(
                  tab.isIncognito ? Icons.visibility_off : Icons.language,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tab.title.isEmpty ? (domain.isEmpty ? 'New Tab' : domain) : tab.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(color: BrowserConstants.border),
                    ),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
            const Spacer(),

            // Thumbnail / Body preview
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tab.isIncognito ? Icons.privacy_tip_outlined : Icons.public,
                    size: 36,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    domain.isEmpty ? 'New Tab' : domain,
                    style: const TextStyle(
                      color: BrowserConstants.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Spacer(),

            // Footer: Blocked badge
            if (tab.blockedCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: BrowserConstants.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: BrowserConstants.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield, size: 11, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${tab.blockedCount} blocked',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
