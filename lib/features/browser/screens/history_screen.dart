import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/browser_history_entry.dart';
import '../services/history_service.dart';
import '../utils/browser_constants.dart';
import '../utils/url_helper.dart';

class HistoryScreen extends StatefulWidget {
  final ValueChanged<String>? onSelectHistory;

  const HistoryScreen({super.key, this.onSelectHistory});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<BrowserHistoryEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    HistoryService.instance.addListener(_loadHistory);
  }

  @override
  void dispose() {
    HistoryService.instance.removeListener(_loadHistory);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final query = _searchController.text.trim();
    final results = await HistoryService.instance.getHistory(
      query: query.isEmpty ? null : query,
    );
    if (mounted) {
      setState(() {
        _entries = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
              tooltip: 'Clear Browsing History',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: BrowserConstants.surface,
                    title: const Text('Clear Browsing History', style: TextStyle(color: Colors.white)),
                    content: const Text(
                      'Are you sure you want to delete all browsing history?',
                      style: TextStyle(color: BrowserConstants.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel', style: TextStyle(color: BrowserConstants.textSecondary)),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await HistoryService.instance.clearAll();
                        },
                        child: const Text('Clear All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _loadHistory(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search history',
                hintStyle: const TextStyle(color: BrowserConstants.textSecondary),
                prefixIcon: const Icon(Icons.search, size: 20, color: Colors.white),
                filled: true,
                fillColor: BrowserConstants.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _entries.isEmpty
              ? const Center(
                  child: Text(
                    'No history found',
                    style: TextStyle(color: BrowserConstants.textSecondary, fontSize: 14),
                  ),
                )
              : ListView.separated(
                  itemCount: _entries.length,
                  separatorBuilder: (_, _) => const Divider(color: BrowserConstants.border, height: 1),
                  itemBuilder: (ctx, index) {
                    final item = _entries[index];
                    final domain = UrlHelper.extractDomain(item.url);

                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: BrowserConstants.surfaceLight,
                        radius: 18,
                        child: Icon(Icons.history, size: 18, color: Colors.white),
                      ),
                      title: Text(
                        item.title.isEmpty ? domain : item.title,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${item.url} • ${DateFormat.MMMd().add_jm().format(item.visitedAt)}',
                        style: const TextStyle(color: BrowserConstants.textSecondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 16, color: Colors.white),
                        onPressed: () {
                          if (item.id != null) {
                            HistoryService.instance.deleteEntry(item.id!);
                          }
                        },
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSelectHistory?.call(item.url);
                      },
                    );
                  },
                ),
    );
  }
}
