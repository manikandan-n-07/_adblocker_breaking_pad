import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'browser_storage_service.dart';

enum DownloadStatus { pending, downloading, completed, failed }

class DownloadTask {
  final int? id;
  final String filename;
  final String url;
  final String filePath;
  final int size;
  final DateTime downloadedAt;
  DownloadStatus status;
  double progress;

  DownloadTask({
    this.id,
    required this.filename,
    required this.url,
    required this.filePath,
    this.size = 0,
    required this.downloadedAt,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'filename': filename,
      'url': url,
      'filePath': filePath,
      'size': size,
      'downloadedAt': downloadedAt.millisecondsSinceEpoch,
      'status': status.name,
    };
  }

  factory DownloadTask.fromMap(Map<String, dynamic> map) {
    return DownloadTask(
      id: map['id'] as int?,
      filename: map['filename'] as String,
      url: map['url'] as String,
      filePath: map['filePath'] as String,
      size: map['size'] as int? ?? 0,
      downloadedAt: DateTime.fromMillisecondsSinceEpoch(map['downloadedAt'] as int),
      status: DownloadStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DownloadStatus.completed,
      ),
      progress: (map['status'] == 'completed') ? 1.0 : 0.0,
    );
  }
}

class DownloadService extends ChangeNotifier {
  static final DownloadService instance = DownloadService._internal();
  DownloadService._internal();

  final List<DownloadTask> _activeDownloads = [];
  List<DownloadTask> get activeDownloads => List.unmodifiable(_activeDownloads);

  /// Starts downloading a file from a URL.
  Future<void> startDownload(String url, {String? suggestedFilename}) async {
    try {
      final uri = Uri.parse(url);
      var filename = suggestedFilename;
      if (filename == null || filename.isEmpty) {
        filename = p.basename(uri.path);
        if (filename.isEmpty || !filename.contains('.')) {
          filename = 'download_${DateTime.now().millisecondsSinceEpoch}.bin';
        }
      }

      Directory? baseDir;
      if (Platform.isAndroid) {
        baseDir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      } else {
        baseDir = await getApplicationDocumentsDirectory();
      }

      final filePath = p.join(baseDir.path, filename);

      final task = DownloadTask(
        filename: filename,
        url: url,
        filePath: filePath,
        downloadedAt: DateTime.now(),
        status: DownloadStatus.downloading,
        progress: 0.0,
      );

      _activeDownloads.insert(0, task);
      notifyListeners();

      // Perform download
      final client = http.Client();
      final request = http.Request('GET', uri);
      request.headers['User-Agent'] =
          'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.6367.113 Mobile Safari/537.36';
      request.followRedirects = true;
      request.maxRedirects = 10;
      final response = await client.send(request);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final totalLength = response.contentLength ?? 0;
        int receivedBytes = 0;
        final file = File(filePath);
        final sink = file.openWrite();

        await response.stream.listen(
          (chunk) {
            sink.add(chunk);
            receivedBytes += chunk.length;
            if (totalLength > 0) {
              task.progress = receivedBytes / totalLength;
              notifyListeners();
            }
          },
          onDone: () async {
            await sink.close();
            task.status = DownloadStatus.completed;
            task.progress = 1.0;
            _saveDownloadRecord(task, receivedBytes);
            notifyListeners();
          },
          onError: (e) async {
            await sink.close();
            task.status = DownloadStatus.failed;
            notifyListeners();
          },
          cancelOnError: true,
        ).asFuture();
      } else {
        task.status = DownloadStatus.failed;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DownloadService startDownload error: $e');
    }
  }

  Future<void> _saveDownloadRecord(DownloadTask task, int size) async {
    try {
      final db = await BrowserStorageService.instance.database;
      await db.insert('downloads', {
        'filename': task.filename,
        'url': task.url,
        'filePath': task.filePath,
        'size': size,
        'downloadedAt': task.downloadedAt.millisecondsSinceEpoch,
        'status': task.status.name,
      });
    } catch (e) {
      debugPrint('Download record save error: $e');
    }
  }

  /// Get download history from database
  Future<List<DownloadTask>> getDownloadHistory() async {
    try {
      final db = await BrowserStorageService.instance.database;
      final maps = await db.query('downloads', orderBy: 'downloadedAt DESC');
      return maps.map((m) => DownloadTask.fromMap(m)).toList();
    } catch (e) {
      debugPrint('getDownloadHistory error: $e');
      return [];
    }
  }

  /// Opens a downloaded file using platform default intent
  Future<OpenResult> openFile(String filePath) async {
    return await OpenFilex.open(filePath);
  }
}
