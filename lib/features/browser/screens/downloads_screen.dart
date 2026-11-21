import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../services/download_service.dart';
import '../utils/browser_constants.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<DownloadTask> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    DownloadService.instance.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    DownloadService.instance.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadHistory() async {
    final list = await DownloadService.instance.getDownloadHistory();
    if (mounted) {
      setState(() {
        _history = list;
        _isLoading = false;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final activeDownloads = DownloadService.instance.activeDownloads;

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
          'Downloads',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : (activeDownloads.isEmpty && _history.isEmpty)
              ? const Center(
                  child: Text(
                    'No downloaded files',
                    style: TextStyle(color: BrowserConstants.textSecondary, fontSize: 14),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Active Downloads Section
                    if (activeDownloads.isNotEmpty) ...[
                      const Text(
                        'ACTIVE DOWNLOADS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...activeDownloads.map((task) => _buildActiveDownloadCard(task)),
                      const SizedBox(height: 16),
                    ],

                    // Download History Section
                    if (_history.isNotEmpty) ...[
                      const Text(
                        'DOWNLOAD HISTORY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: BrowserConstants.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: BrowserConstants.borderLight),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _history.length,
                          separatorBuilder: (_, _) => const Divider(color: BrowserConstants.border, height: 1),
                          itemBuilder: (ctx, index) {
                            final item = _history[index];
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: BrowserConstants.surfaceLight,
                                child: Icon(Icons.insert_drive_file_outlined, color: Colors.white, size: 20),
                              ),
                              title: Text(
                                item.filename,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${_formatBytes(item.size)} • ${DateFormat.MMMd().add_jm().format(item.downloadedAt)}',
                                style: const TextStyle(color: BrowserConstants.textSecondary, fontSize: 12),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.open_in_new, size: 18, color: Colors.white),
                                onPressed: () async {
                                  final result = await DownloadService.instance.openFile(item.filePath);
                                  if (result.type != ResultType.done && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Cannot open file: ${result.message}')),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }

  Widget _buildActiveDownloadCard(DownloadTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BrowserConstants.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BrowserConstants.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.downloading, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.filename,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(task.progress * 100).toInt()}%',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: task.progress > 0 ? task.progress : null,
            backgroundColor: BrowserConstants.surfaceLight,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }
}
