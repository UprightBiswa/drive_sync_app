import 'package:workmanager/workmanager.dart';
import 'package:get/get.dart';
import 'package:drive_sync_app/services/database_service.dart';
import 'package:drive_sync_app/services/google_drive_service.dart';
import 'package:drive_sync_app/services/upload_manager_service.dart';

const backgroundUploadTask = "backgroundUploadTask";

// This top-level function is the entry point for the background task.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == backgroundUploadTask) {
      print("Background task started: $backgroundUploadTask");
      // We need to re-initialize services for the background isolate
      await Get.putAsync(() => DatabaseService().init());
      Get.put(GoogleDriveService());
      final uploadManager = Get.put(UploadManagerService());

      try {
        await uploadManager.processUploadQueue();
      } catch (e) {
        print("Error in background task: $e");
        return Future.value(false); // Indicate failure
      }
    }
    return Future.value(true); // Indicate success
  });
}

class BackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
    await Workmanager().registerPeriodicTask(
      "drive-sync-periodic-task",
      backgroundUploadTask,
      frequency: const Duration(minutes: 15), // Minimum frequency
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }
}
