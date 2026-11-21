import 'package:flutter/foundation.dart';
import '../models/bookmark.dart';
import 'browser_storage_service.dart';

class BookmarkService extends ChangeNotifier {
  static final BookmarkService instance = BookmarkService._internal();
  BookmarkService._internal();

  /// Adds a new bookmark
  Future<Bookmark?> addBookmark({
    required String title,
    required String url,
    String folder = 'Favorites',
    String? favicon,
  }) async {
    if (url.isEmpty || url == 'about:blank') return null;

    try {
      final db = await BrowserStorageService.instance.database;
      final cleanTitle = title.trim().isEmpty ? url : title.trim();
      final bookmark = Bookmark(
        title: cleanTitle,
        url: url,
        folder: folder,
        createdAt: DateTime.now(),
        favicon: favicon,
      );

      final id = await db.insert('bookmarks', bookmark.toMap());
      notifyListeners();
      return bookmark.copyWith(id: id);
    } catch (e) {
      debugPrint('BookmarkService addBookmark error: $e');
      return null;
    }
  }

  /// Checks if a given URL is currently bookmarked
  Future<bool> isBookmarked(String url) async {
    if (url.isEmpty) return false;
    try {
      final db = await BrowserStorageService.instance.database;
      final result = await db.query(
        'bookmarks',
        where: 'url = ?',
        whereArgs: [url],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Retrieves bookmarks with optional filtering query
  Future<List<Bookmark>> getBookmarks({String? query}) async {
    try {
      final db = await BrowserStorageService.instance.database;
      String? where;
      List<dynamic>? whereArgs;

      if (query != null && query.trim().isNotEmpty) {
        where = 'title LIKE ? OR url LIKE ? OR folder LIKE ?';
        final pattern = '%${query.trim()}%';
        whereArgs = [pattern, pattern, pattern];
      }

      final maps = await db.query(
        'bookmarks',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'createdAt DESC',
      );

      return maps.map((m) => Bookmark.fromMap(m)).toList();
    } catch (e) {
      debugPrint('BookmarkService getBookmarks error: $e');
      return [];
    }
  }

  /// Updates an existing bookmark
  Future<void> updateBookmark(Bookmark bookmark) async {
    if (bookmark.id == null) return;
    try {
      final db = await BrowserStorageService.instance.database;
      await db.update(
        'bookmarks',
        bookmark.toMap(),
        where: 'id = ?',
        whereArgs: [bookmark.id],
      );
      notifyListeners();
    } catch (e) {
      debugPrint('BookmarkService updateBookmark error: $e');
    }
  }

  /// Removes a bookmark by ID
  Future<void> removeBookmark(int id) async {
    try {
      final db = await BrowserStorageService.instance.database;
      await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
      notifyListeners();
    } catch (e) {
      debugPrint('BookmarkService removeBookmark error: $e');
    }
  }

  /// Removes a bookmark by URL
  Future<void> removeBookmarkByUrl(String url) async {
    try {
      final db = await BrowserStorageService.instance.database;
      await db.delete('bookmarks', where: 'url = ?', whereArgs: [url]);
      notifyListeners();
    } catch (e) {
      debugPrint('BookmarkService removeBookmarkByUrl error: $e');
    }
  }
}
