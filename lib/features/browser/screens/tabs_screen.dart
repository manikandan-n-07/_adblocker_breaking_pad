import 'package:flutter/material.dart';
import '../utils/browser_constants.dart';
import '../webview/browser_controller.dart';
import '../widgets/browser_tab_card.dart';

class TabsScreen extends StatefulWidget {
  final BrowserController controller;

  const TabsScreen({
    super.key,
    required this.controller,
  });

  @override
  State<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {
  bool _showIncognito = false;

  @override
  void initState() {
    super.initState();
    final cur = widget.controller.currentTab;
    if (cur != null && cur.isIncognito) {
      _showIncognito = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final allTabs = widget.controller.tabs;
        final filteredIndices = <int>[];
        for (int i = 0; i < allTabs.length; i++) {
          if (allTabs[i].isIncognito == _showIncognito) {
            filteredIndices.add(i);
          }
        }

        final regularCount = widget.controller.regularTabsCount;
        final incognitoCount = widget.controller.privateTabsCount;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: BrowserConstants.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Regular tabs switcher button
                InkWell(
                  onTap: () => setState(() => _showIncognito = false),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: !_showIncognito ? BrowserConstants.surfaceLight : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !_showIncognito ? Colors.white : Colors.transparent,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tab, size: 18, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          '$regularCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Incognito tabs switcher button
                InkWell(
                  onTap: () => setState(() => _showIncognito = true),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _showIncognito ? BrowserConstants.surfaceLight : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _showIncognito ? Colors.white : Colors.transparent,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.visibility_off,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$incognitoCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                color: BrowserConstants.surface,
                onSelected: (val) {
                  if (val == 'close_all') {
                    widget.controller.closeAllTabs(incognitoOnly: _showIncognito);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'close_all',
                    child: Text(
                      _showIncognito ? 'Close All Private Tabs' : 'Close All Tabs',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: filteredIndices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.tab_unselected,
                        size: 56,
                        color: Colors.white38,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _showIncognito ? 'No open private tabs' : 'No open tabs',
                        style: const TextStyle(color: BrowserConstants.textSecondary, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          widget.controller.addNewTab(isIncognito: _showIncognito);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.add, color: Colors.black),
                        label: Text(_showIncognito ? 'New Private Tab' : 'New Tab', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: filteredIndices.length,
                  itemBuilder: (ctx, index) {
                    final originalIndex = filteredIndices[index];
                    final tab = allTabs[originalIndex];
                    final isSelected = originalIndex == widget.controller.currentTabIndex;

                    return BrowserTabCard(
                      tab: tab,
                      isSelected: isSelected,
                      onTap: () {
                        widget.controller.switchTab(originalIndex);
                        Navigator.pop(context);
                      },
                      onClose: () {
                        widget.controller.closeTab(originalIndex);
                      },
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            tooltip: 'New Tab',
            onPressed: () {
              widget.controller.addNewTab(isIncognito: _showIncognito);
              Navigator.pop(context);
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
