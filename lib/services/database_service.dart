import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path/path.dart';
import 'package:drive_sync_app/models/tracked_file.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  late Database _db;
  late StoreRef<int, Map<String, dynamic>> _store;

  Future<DatabaseService> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = join(appDir.path, 'drive_sync_app.db');
    _db = await databaseFactoryIo.openDatabase(dbPath);
    _store = intMapStoreFactory.store('files');
    return this;
  }

  // Batch insert files for performance
  Future<void> insertFiles(List<String> filePaths) async {
    final existingPaths = (await _store.find(
      _db,
    )).map((snapshot) => snapshot.value['path'] as String).toSet();

    final newFiles = filePaths
        .where((path) => !existingPaths.contains(path))
        .map(
          (path) => TrackedFile(
            id: 0, // Sembast will assign an ID
            path: path,
            status: FileStatus.pending,
            createdAt: DateTime.now(),
          ).toJson(),
        )
        .toList();

    if (newFiles.isNotEmpty) {
      await _store.addAll(_db, newFiles);
    }
  }

  Future<List<TrackedFile>> getFilesByStatus(FileStatus status) async {
    final finder = Finder(filter: Filter.equals('status', status.toString()));
    final snapshots = await _store.find(_db, finder: finder);
    return snapshots
        .map((snapshot) => TrackedFile.fromJson(snapshot.key, snapshot.value))
        .toList();
  }

   // **NEW:** A method to delete all files from the database.
  Future<void> deleteAllFiles() async {
    await _store.delete(_db);
  }


  Future<int> countFilesByStatus(FileStatus status) async {
    final finder = Finder(filter: Filter.equals('status', status.toString()));
    // **FIXED**: Using the modern, recommended query API for counting.
    return await _store.query(finder: finder).count(_db);
  }

  // NEW: Stream for the UI file list
  Stream<List<TrackedFile>> getAllFilesStream() {
    // Sort by creation time, newest first
    final finder = Finder(sortOrders: [SortOrder('createdAt', false)]);
    return _store.query(finder: finder).onSnapshots(_db).map((snapshots) {
      return snapshots
          .map((snapshot) => TrackedFile.fromJson(snapshot.key, snapshot.value))
          .toList();
    });
  }

  Future<void> updateFileStatus(int id, FileStatus status) async {
    await _store.record(id).update(_db, {'status': status.toString()});
  }

  // Stream for reactive UI updates
  Stream<Map<FileStatus, int>> getStatusCountsStream() {
    return _store.query().onSnapshots(_db).map((snapshots) {
      final counts = <FileStatus, int>{
        FileStatus.pending: 0,
        FileStatus.uploading: 0,
        FileStatus.completed: 0,
        FileStatus.failed: 0,
      };
      for (var snapshot in snapshots) {
        final status = FileStatus.values.firstWhere(
          (e) => e.toString() == snapshot.value['status'],
        );
        counts[status] = (counts[status] ?? 0) + 1;
      }
      return counts;
    });
  }
}
