import 'dart:io';
import 'package:get/get.dart';
import 'package:pool/pool.dart';
import 'package:drive_sync_app/models/tracked_file.dart';
import 'package:drive_sync_app/services/database_service.dart';
import 'package:drive_sync_app/services/google_drive_service.dart';

class UploadManagerService {
  final DatabaseService _dbService = Get.find();
  final GoogleDriveService _driveService = Get.find();
  final RxBool isUploading = false.obs;

  // Create a pool to limit concurrent uploads to 4
  final _pool = Pool(4);

  Future<void> processUploadQueue() async {
    if (isUploading.value || _driveService.currentUser.value == null) {
      print("Upload process already running or user not logged in.");
      return;
    }

    isUploading.value = true;
    try {
      final pendingFiles = await _dbService.getFilesByStatus(
        FileStatus.pending,
      );
      if (pendingFiles.isEmpty) {
        print("No pending files to upload.");
        return;
      }

      print("Starting upload for ${pendingFiles.length} files.");

      final uploadTasks = <Future>[];
      for (final file in pendingFiles) {
        uploadTasks.add(_pool.withResource(() => _uploadSingleFile(file)));
      }

      // Wait for all tasks in the pool to complete
      await Future.wait(uploadTasks);
    } catch (e) {
      print("Error processing upload queue: $e");
    } finally {
      isUploading.value = false;
      print("Upload queue processing finished.");
    }
  }

  Future<void> _uploadSingleFile(TrackedFile trackedFile) async {
    try {
      await _dbService.updateFileStatus(trackedFile.id, FileStatus.uploading);

      final file = File(trackedFile.path);
      if (!await file.exists()) {
        await _dbService.updateFileStatus(trackedFile.id, FileStatus.failed);
        return;
      }

      final success = await _driveService.uploadFile(file);
      final newStatus = success ? FileStatus.completed : FileStatus.failed;
      await _dbService.updateFileStatus(trackedFile.id, newStatus);
    } catch (e) {
      print("Failed to upload file ${trackedFile.path}: $e");
      await _dbService.updateFileStatus(trackedFile.id, FileStatus.failed);
    }
  }
}
