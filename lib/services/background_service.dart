
import 'package:workmanager/workmanager.dart';
import 'package:get/get.dart';
import 'package:drive_sync_app/services/database_service.dart';
import 'package:drive_sync_app/services/google_drive_service.dart';
import 'package:drive_sync_app/services/notification_service.dart';
import 'package:drive_sync_app/services/upload_manager_service.dart';

const backgroundUploadTask = "backgroundUploadTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == backgroundUploadTask) {
      print("Background task started: $backgroundUploadTask");
      // Re-initialize services for the background isolate
      await Get.putAsync(() => NotificationService().init());
      await Get.putAsync(() => DatabaseService().init());
      Get.put(GoogleDriveService());
      final uploadManager = Get.put(UploadManagerService());
      final notificationService = Get.find<NotificationService>();
      
      try {
        final successCount = await uploadManager.processUploadQueue();
        await notificationService.showUploadCompleteNotification(successCount);
      } catch (e) {
        print("Error in background task: $e");
        return Future.value(false);
      }
    }
    return Future.value(true);
  });
}

class BackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
    await Workmanager().registerPeriodicTask(
      "drive-sync-periodic-task",
      backgroundUploadTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }
}
