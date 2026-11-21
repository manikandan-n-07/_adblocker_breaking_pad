import 'package:flutter/material.dart';
import '../models/bookmark.dart';
import '../services/bookmark_service.dart';
import '../utils/browser_constants.dart';
import '../utils/url_helper.dart';

class BookmarksScreen extends StatefulWidget {
  final ValueChanged<String>? onSelectBookmark;

  const BookmarksScreen({super.key, this.onSelectBookmark});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Bookmark> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    BookmarkService.instance.addListener(_loadBookmarks);
  }

  @override
  void dispose() {
    BookmarkService.instance.removeListener(_loadBookmarks);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookmarks() async {
    final query = _searchController.text.trim();
    final results = await BookmarkService.instance.getBookmarks(
      query: query.isEmpty ? null : query,
    );
    if (mounted) {
      setState(() {
        _bookmarks = results;
        _isLoading = false;
      });
    }
  }

  void _showAddBookmarkDialog([Bookmark? existing]) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final urlController = TextEditingController(text: existing?.url ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrowserConstants.surface,
        title: Text(
          existing != null ? 'Edit Bookmark' : 'Add Bookmark',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: BrowserConstants.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'URL',
                labelStyle: TextStyle(color: BrowserConstants.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: BrowserConstants.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                if (existing != null) {
                  await BookmarkService.instance.updateBookmark(
                    existing.copyWith(title: title, url: url),
                  );
                } else {
                  await BookmarkService.instance.addBookmark(title: title, url: url);
                }
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            child: const Text('Save', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
          'Bookmarks',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Add Bookmark',
            onPressed: () => _showAddBookmarkDialog(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _loadBookmarks(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search bookmarks',
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
          : _bookmarks.isEmpty
              ? const Center(
                  child: Text(
                    'No bookmarks yet',
                    style: TextStyle(color: BrowserConstants.textSecondary, fontSize: 14),
                  ),
                )
              : ListView.separated(
                  itemCount: _bookmarks.length,
                  separatorBuilder: (_, _) => const Divider(color: BrowserConstants.border, height: 1),
                  itemBuilder: (ctx, index) {
                    final item = _bookmarks[index];
                    final domain = UrlHelper.extractDomain(item.url);

                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: BrowserConstants.surfaceLight,
                        radius: 18,
                        child: Icon(Icons.bookmark, size: 18, color: Colors.white),
                      ),
                      title: Text(
                        item.title.isEmpty ? domain : item.title,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        item.url,
                        style: const TextStyle(color: BrowserConstants.textSecondary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18, color: Colors.white),
                        color: BrowserConstants.surface,
                        onSelected: (val) {
                          if (val == 'edit') {
                            _showAddBookmarkDialog(item);
                          } else if (val == 'delete' && item.id != null) {
                            BookmarkService.instance.removeBookmark(item.id!);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit', style: TextStyle(color: Colors.white)),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSelectBookmark?.call(item.url);
                      },
                    );
                  },
                ),
    );
  }
}
