import 'package:flutter/foundation.dart';
import '../models/browser_history_entry.dart';
import 'browser_storage_service.dart';

class HistoryService extends ChangeNotifier {
  static final HistoryService instance = HistoryService._internal();
  HistoryService._internal();

  /// Adds a visit to history unless in incognito mode
  Future<void> addEntry({
    required String title,
    required String url,
    String? favicon,
    bool isIncognito = false,
  }) async {
    if (isIncognito) return; // Do not record history in private browsing mode
    if (url.isEmpty || url == 'about:blank') return;

    try {
      final db = await BrowserStorageService.instance.database;
      final cleanTitle = title.trim().isEmpty ? url : title.trim();
      final entry = BrowserHistoryEntry(
        title: cleanTitle,
        url: url,
        visitedAt: DateTime.now(),
        favicon: favicon,
      );

      await db.insert('history', entry.toMap());
      notifyListeners();
    } catch (e) {
      debugPrint('HistoryService addEntry error: $e');
    }
  }

  /// Retrieves history entries sorted by date descending, optional search query
  Future<List<BrowserHistoryEntry>> getHistory({String? query, int limit = 100}) async {
    try {
      final db = await BrowserStorageService.instance.database;
      String? where;
      List<dynamic>? whereArgs;

      if (query != null && query.trim().isNotEmpty) {
        where = 'title LIKE ? OR url LIKE ?';
        final pattern = '%${query.trim()}%';
        whereArgs = [pattern, pattern];
      }

      final maps = await db.query(
        'history',
        where: where,
        whereArgs: whereArgs,
        orderBy: 'visitedAt DESC',
        limit: limit,
      );

      return maps.map((m) => BrowserHistoryEntry.fromMap(m)).toList();
    } catch (e) {
      debugPrint('HistoryService getHistory error: $e');
      return [];
    }
  }

  /// Deletes a specific history entry
  Future<void> deleteEntry(int id) async {
    try {
      final db = await BrowserStorageService.instance.database;
      await db.delete('history', where: 'id = ?', whereArgs: [id]);
      notifyListeners();
    } catch (e) {
      debugPrint('HistoryService deleteEntry error: $e');
    }
  }

  /// Clears all history
  Future<void> clearAll() async {
    try {
      final db = await BrowserStorageService.instance.database;
      await db.delete('history');
      notifyListeners();
    } catch (e) {
      debugPrint('HistoryService clearAll error: $e');
    }
  }
}
