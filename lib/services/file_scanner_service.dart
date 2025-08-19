import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:drive_sync_app/services/database_service.dart';

// This function MUST be a top-level function to be used with compute()
Future<List<String>> _scanFilesIsolate(String rootPath) async {
  final dir = Directory(rootPath);
  final List<String> paths = [];
  if (await dir.exists()) {
    await for (var entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        paths.add(entity.path);
      }
    }
  }
  return paths;
}

class FileScannerService {
  final DatabaseService _dbService = Get.find();
  final RxBool isScanning = false.obs;

  Future<void> startScan() async {
    if (isScanning.value) return;

    isScanning.value = true;
    try {
      // Use compute to run the heavy scanning task in a separate isolate
      final List<String> filePaths = await compute(
        _scanFilesIsolate,
        "/storage/emulated/0/",
      );
      await _dbService.insertFiles(filePaths);
      Get.snackbar(
        'Scan Complete',
        '${filePaths.length} files found and indexed.',
      );
    } catch (e) {
      Get.snackbar('Scan Error', 'Failed to scan files: $e');
    } finally {
      isScanning.value = false;
    }
  }
}
