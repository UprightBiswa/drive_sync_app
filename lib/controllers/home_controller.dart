// =============================================================
// FILE: lib/controllers/home_controller.dart
// =============================================================
import 'package:get/get.dart';
import 'package:drive_sync_app/models/tracked_file.dart';
import 'package:drive_sync_app/services/database_service.dart';
import 'package:drive_sync_app/services/file_scanner_service.dart';
import 'package:drive_sync_app/services/google_drive_service.dart';
import 'package:drive_sync_app/services/permission_service.dart';
import 'package:drive_sync_app/services/upload_manager_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class HomeController extends GetxController {
  final PermissionService _permissionService = Get.find();
  final GoogleDriveService _googleDriveService = Get.find();
  final FileScannerService _fileScannerService = Get.find();
  final UploadManagerService _uploadManagerService = Get.find();
  final DatabaseService _dbService = Get.find();

  final Rx<GoogleSignInAccount?> currentUser = Rx<GoogleSignInAccount?>(null);
  final RxBool isScanning = false.obs;
  final RxBool isUploading = false.obs;
  final RxMap<FileStatus, int> statusCounts = RxMap<FileStatus, int>({});
  
  // **NEW:** State to control the file list view.
  final RxBool showFailedOnly = false.obs;
  
  // **UPDATED:** A computed list that reacts to the showFailedOnly state.
  RxList<TrackedFile> allFiles = <TrackedFile>[].obs;

  @override
  void onInit() {
    super.onInit();
    currentUser.bindStream(_googleDriveService.currentUser.stream);
    isScanning.bindStream(_fileScannerService.isScanning.stream);
    isUploading.bindStream(_uploadManagerService.isUploading.stream);
    statusCounts.bindStream(_dbService.getStatusCountsStream());
    
    // **NEW:** The file list now depends on the `showFailedOnly` toggle.
    ever(showFailedOnly, (_) => _updateFileList());
    _updateFileList(); // Initial load

    // Automatically start upload process when user logs in
    ever(currentUser, (account) {
      if (account != null) {
        _uploadManagerService.processUploadQueue();
      }
    });
  }

  // **NEW:** Method to update the file list based on the toggle.
  void _updateFileList() async {
    if (showFailedOnly.value) {
      allFiles.value = await _dbService.getFilesByStatus(FileStatus.failed);
    } else {
      allFiles.bindStream(_dbService.getAllFilesStream());
    }
  }

  // **NEW:** Method to toggle the file list view.
  void toggleShowFailedOnly() {
    showFailedOnly.value = !showFailedOnly.value;
  }

  // **NEW:** Handles the re-upload of failed files.
  void handleReuploadFailed() {
    _uploadManagerService.reuploadFailedFiles();
  }

  // **NEW:** Handles the deletion of all files from the database.
  void handleDeleteAllFiles() {
    _dbService.deleteAllFiles();
    Get.snackbar('Files Deleted', 'All tracked files have been removed from the list.');
  }

  Future<void> handleSignIn() async {
    await _googleDriveService.signIn();
  }

  Future<void> handleSignOut() async {
    await _googleDriveService.signOut();
  }

  Future<void> handlePickAndScan() async {
    final hasStoragePerm = await _permissionService.requestStoragePermission();
    if (!hasStoragePerm) {
      Get.snackbar('Permission Denied', 'Storage permission is required to scan files.');
      return;
    }
    await _permissionService.requestNotificationPermission();
    await _fileScannerService.pickAndScanFolder();
  }

  void handleUpload() {
    if (currentUser.value == null) {
      Get.snackbar('Not Signed In', 'Please sign in to start uploading.');
      return;
    }
    _uploadManagerService.processUploadQueue();
  }
}
