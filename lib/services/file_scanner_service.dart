import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:drive_sync_app/services/database_service.dart';
import 'package:file_picker/file_picker.dart';
// This function MUST be a top-level function to be used with compute()
Future<List<String>> _scanFilesIsolate(String rootPath) async {
  final dir = Directory(rootPath);
  final List<String> paths = [];
  if (await dir.exists()) {
    try {
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          paths.add(entity.path);
        }
      }
    } on FileSystemException catch (e) {
      // Skip restricted folders
      debugPrint("Skipping folder due to permission: ${e.path}");
    }
  }
  return paths;
}

class FileScannerService {
  final DatabaseService _dbService = Get.find();
  final RxBool isScanning = false.obs;

  Future<void> pickAndScanFolder() async {
    if (isScanning.value) return;

    // Use file_picker to let the user choose a directory
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      isScanning.value = true;
      try {
        final List<String> filePaths = await compute(_scanFilesIsolate, selectedDirectory);
        await _dbService.insertFiles(filePaths);
        Get.snackbar('Scan Complete', '${filePaths.length} files found and indexed.');
      } catch (e) {
        Get.snackbar('Scan Error', 'Failed to scan files: $e');
      } finally {
        isScanning.value = false;
      }
    } else {
      Get.snackbar('Scan Canceled', 'No folder was selected.');
    }
  }
}
