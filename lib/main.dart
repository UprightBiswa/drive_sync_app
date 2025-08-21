import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:drive_sync_app/services/background_service.dart';
import 'package:drive_sync_app/services/database_service.dart';
import 'package:drive_sync_app/services/file_scanner_service.dart';
import 'package:drive_sync_app/services/google_drive_service.dart';
import 'package:drive_sync_app/services/permission_service.dart';
import 'package:drive_sync_app/services/upload_manager_service.dart';
import 'package:drive_sync_app/ui/home_screen.dart';
import 'package:drive_sync_app/utils/app_theme.dart';

import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await BackgroundService.initialize();

  await initServices();

  runApp(const MyApp());
}

Future<void> initServices() async {
  Get.put(PermissionService());
  await Get.putAsync(() => NotificationService().init());
  await Get.putAsync(() => DatabaseService().init());
  Get.put(GoogleDriveService());
  Get.put(FileScannerService());
  Get.put(UploadManagerService());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Drive Sync',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}
