import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class BrowserStorageService {
  static final BrowserStorageService instance = BrowserStorageService._internal();
  BrowserStorageService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final path = p.join(docsDir.path, 'breaking_pad_browser.db');

      return await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE history (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT,
              url TEXT NOT NULL,
              visitedAt INTEGER NOT NULL,
              favicon TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE bookmarks (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT,
              url TEXT NOT NULL,
              folder TEXT DEFAULT 'Favorites',
              createdAt INTEGER NOT NULL,
              favicon TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE downloads (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              filename TEXT NOT NULL,
              url TEXT NOT NULL,
              filePath TEXT NOT NULL,
              size INTEGER DEFAULT 0,
              downloadedAt INTEGER NOT NULL,
              status TEXT NOT NULL
            )
          ''');
        },
      );
    } catch (e) {
      debugPrint('BrowserStorageService database init warning: $e');
      // In-memory database fallback for environments where path_provider is restricted
      return await openDatabase(inMemoryDatabasePath, version: 1,
          onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            url TEXT NOT NULL,
            visitedAt INTEGER NOT NULL,
            favicon TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE bookmarks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            url TEXT NOT NULL,
            folder TEXT DEFAULT 'Favorites',
            createdAt INTEGER NOT NULL,
            favicon TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE downloads (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            filename TEXT NOT NULL,
            url TEXT NOT NULL,
            filePath TEXT NOT NULL,
            size INTEGER DEFAULT 0,
            downloadedAt INTEGER NOT NULL,
            status TEXT NOT NULL
          )
        ''');
      });
    }
  }
}
