import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestStoragePermission() async {
    // For Android 11+
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }
    
    var status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      return true;
    }

    // Fallback for older Android versions
    if (await Permission.storage.isGranted) {
      return true;
    }
    status = await Permission.storage.request();
    return status.isGranted;
  }
}