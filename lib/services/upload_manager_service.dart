import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:pool/pool.dart';
import 'package:drive_sync_app/models/tracked_file.dart';
import 'package:drive_sync_app/services/database_service.dart';
import 'package:drive_sync_app/services/google_drive_service.dart';

class UploadManagerService {
  final DatabaseService _dbService = Get.find();
  final GoogleDriveService _driveService = Get.find();

  final RxBool isUploading = false.obs;
  final _pool = Pool(8); // 8 concurrent uploads
  final int maxRetry = 3; // Retry failed uploads up to 3 times

  /// Stream for progress updates
  final RxInt uploadedCount = 0.obs;
  final RxInt totalFiles = 0.obs;

  /// Main method to start upload queue
  Future<int> processUploadQueue() async {
    if (isUploading.value || _driveService.currentUser.value == null) {
      debugPrint("Upload skipped: already running or not signed in.");
      return 0;
    }

    isUploading.value = true;
    uploadedCount.value = 0;

    final pendingFiles = await _dbService.getFilesByStatus(FileStatus.pending);
    totalFiles.value = pendingFiles.length;

    if (pendingFiles.isEmpty) {
      debugPrint("No pending files to upload.");
      isUploading.value = false;
      return 0;
    }

    debugPrint("Starting upload for ${pendingFiles.length} files.");

    int successCount = 0;

    try {
      // Use pool for parallel uploads, offloaded to isolates
      await for (final success in _pool.forEach(
        pendingFiles,
        (file) => _uploadFileInIsolate(file),
      )) {
        if (success) successCount++;
        uploadedCount.value++;
      }
    } catch (e, s) {
      debugPrint("Error in upload queue: $e\n$s");
    } finally {
      isUploading.value = false;
      debugPrint("Upload finished. Success: $successCount / ${pendingFiles.length}");
    }

    return successCount;
  }

  /// Re-upload failed files
  Future<void> reuploadFailedFiles() async {
    final failedFiles = await _dbService.getFilesByStatus(FileStatus.failed);
    for (var file in failedFiles) {
      await _dbService.updateFileStatus(file.id, FileStatus.pending);
    }
    await processUploadQueue();
  }

  /// Upload a single file in a separate isolate
  Future<bool> _uploadFileInIsolate(TrackedFile trackedFile) async {
    return compute(_uploadSingleFileIsolate, trackedFile.toMap());
  }
}

/// Top-level function to run in isolate
Future<bool> _uploadSingleFileIsolate(Map<String, dynamic> fileMap) async {
  final dbService = Get.find<DatabaseService>();
  final driveService = Get.find<GoogleDriveService>();

  final trackedFile = TrackedFile.fromMap(fileMap);
  int attempt = 0;
  while (attempt < 3) {
    attempt++;
    try {
      await dbService.updateFileStatus(trackedFile.id, FileStatus.uploading);

      final file = File(trackedFile.path);
      if (!await file.exists()) {
        await dbService.updateFileStatus(trackedFile.id, FileStatus.failed);
        return false;
      }

      final success = await driveService.uploadFile(file);

      await dbService.updateFileStatus(
        trackedFile.id,
        success ? FileStatus.completed : FileStatus.failed,
      );

      if (success) return true;
    } catch (e, s) {
      debugPrint("Error uploading ${trackedFile.path} (attempt $attempt): $e\n$s");
      if (attempt >= 3) {
        await dbService.updateFileStatus(trackedFile.id, FileStatus.failed);
        return false;
      }
    }
  }
  return false;
}
