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
  final _pool = Pool(4);

  Future<int> processUploadQueue() async {
    if (isUploading.value || _driveService.currentUser.value == null) {
      debugPrint(
        "Upload process skipped: already running or user not logged in.",
      );
      return 0;
    }

    int successCount = 0;
    isUploading.value = true;
    try {
      final pendingFiles = await _dbService.getFilesByStatus(
        FileStatus.pending,
      );
      if (pendingFiles.isEmpty) {
        debugPrint("No pending files to upload.");
        return 0;
      }

      debugPrint("Starting upload for ${pendingFiles.length} files.");
      await for (final success in _pool.forEach(
        pendingFiles,
        _uploadSingleFile,
      )) {
        if (success) successCount++;
      }
    } catch (e, s) {
      debugPrint("Error processing upload queue: $e\n$s");
    } finally {
      isUploading.value = false;
      debugPrint("Upload queue finished. Successes: $successCount");
    }
    return successCount;
  }

  // **NEW:** Method to handle re-uploading failed files.
  Future<void> reuploadFailedFiles() async {
    final failedFiles = await _dbService.getFilesByStatus(FileStatus.failed);
    for (var file in failedFiles) {
      await _dbService.updateFileStatus(file.id, FileStatus.pending);
    }
    await processUploadQueue();
  }

  Future<bool> _uploadSingleFile(TrackedFile trackedFile) async {
    try {
      await _dbService.updateFileStatus(trackedFile.id, FileStatus.uploading);

      final file = File(trackedFile.path);
      if (!await file.exists()) {
        debugPrint("Upload failed: File does not exist at ${trackedFile.path}");
        await _dbService.updateFileStatus(trackedFile.id, FileStatus.failed);
        return false;
      }

      final success = await _driveService.uploadFile(file);
      await _dbService.updateFileStatus(
        trackedFile.id,
        success ? FileStatus.completed : FileStatus.failed,
      );
      return success;
    } catch (e, s) {
      // **DETAILED LOGGING**
      debugPrint("Critical error uploading ${trackedFile.path}: $e\n$s");
      await _dbService.updateFileStatus(trackedFile.id, FileStatus.failed);
      return false;
    }
  }
}
