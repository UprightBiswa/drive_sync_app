import 'dart:async';
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
  final RxBool _cancelRequested = false.obs;
  final RxInt uploadedCount = 0.obs;
  final RxInt totalFiles = 0.obs;

  // Concurrency: max 6 uploads at once
  final Pool _pool = Pool(6);

  static const int _maxRetry = 3;
  static const Duration _baseBackoff = Duration(seconds: 2);

  /// Upload queue runner
  Future<int> processUploadQueue() async {
    if (isUploading.value) return 0;
    if (_driveService.currentUser.value == null) return 0;

    isUploading.value = true;
    _cancelRequested.value = false;
    uploadedCount.value = 0;

    try {
      final pending = await _dbService.getFilesByStatus(FileStatus.pending);
      if (pending.isEmpty) return 0;

      totalFiles.value = pending.length;
      int successCount = 0;

      // Run uploads in parallel
      await for (final success in _pool.forEach(pending, _uploadOne)) {
        if (success) successCount++;
        uploadedCount.value++;
        if (_cancelRequested.value) break;
      }

      return successCount;
    } catch (e, s) {
      debugPrint("Upload queue error: $e\n$s");
      return 0;
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> reuploadFailedFiles() async {
    final failed = await _dbService.getFilesByStatus(FileStatus.failed);
    for (final f in failed) {
      await _dbService.updateFileStatus(f.id, FileStatus.pending);
    }
    await processUploadQueue();
  }

  void cancelCurrentUploads() {
    _cancelRequested.value = true;
  }

  /// Upload one file with retry
  Future<bool> _uploadOne(TrackedFile tracked) async {
    if (_cancelRequested.value) return false;

    await _safeSetStatus(tracked.id, FileStatus.uploading);

    final file = File(tracked.path);
    if (!await file.exists()) {
      await _safeSetStatus(tracked.id, FileStatus.failed);
      return false;
    }

    int attempt = 0;
    while (attempt < _maxRetry && !_cancelRequested.value) {
      attempt++;
      try {
        if (_driveService.currentUser.value == null) {
          await _safeSetStatus(tracked.id, FileStatus.pending);
          return false;
        }

        final ok = await _driveService.uploadFile(file);
        if (ok) {
          await _safeSetStatus(tracked.id, FileStatus.completed);
          return true;
        }
      } catch (e) {
        debugPrint("Upload error for ${tracked.path} attempt $attempt: $e");
      }

      if (attempt < _maxRetry) {
        final delay = _baseBackoff * (1 << (attempt - 1)); // 2s,4s,8s
        await Future.delayed(delay);
      }
    }

    await _safeSetStatus(tracked.id, FileStatus.failed);
    return false;
  }

  Future<void> _safeSetStatus(int id, FileStatus status) async {
    try {
      await _dbService.updateFileStatus(id, status);
    } catch (e) {
      debugPrint("DB update error for $id -> $status: $e");
    }
  }
}
