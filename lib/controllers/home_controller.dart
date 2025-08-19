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

  // Reactive state variables
  final Rx<GoogleSignInAccount?> currentUser = Rx<GoogleSignInAccount?>(null);
  final RxBool isScanning = false.obs;
  final RxBool isUploading = false.obs;
  final RxMap<FileStatus, int> statusCounts = RxMap<FileStatus, int>({
    FileStatus.pending: 0,
    FileStatus.uploading: 0,
    FileStatus.completed: 0,
    FileStatus.failed: 0,
  });

  @override
  void onInit() {
    super.onInit();
    // Bind controller state to service state
    currentUser.bindStream(_googleDriveService.currentUser.stream);
    isScanning.bindStream(_fileScannerService.isScanning.stream);
    isUploading.bindStream(_uploadManagerService.isUploading.stream);
    statusCounts.bindStream(_dbService.getStatusCountsStream());

    // Automatically start upload process when user logs in
    ever(currentUser, (account) {
      if (account != null) {
        _uploadManagerService.processUploadQueue();
      }
    });
  }

  Future<void> handleSignIn() async {
    await _googleDriveService.signIn();
  }

  Future<void> handleSignOut() async {
    await _googleDriveService.signOut();
  }

  Future<void> handleScan() async {
    final hasPermission = await _permissionService.requestStoragePermission();
    if (hasPermission) {
      await _fileScannerService.startScan();
    } else {
      Get.snackbar(
        'Permission Denied',
        'Storage permission is required to scan files.',
      );
    }
  }

  void handleUpload() {
    if (currentUser.value == null) {
      Get.snackbar('Not Signed In', 'Please sign in to start uploading.');
      return;
    }
    _uploadManagerService.processUploadQueue();
  }
}
