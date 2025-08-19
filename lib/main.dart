
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

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background service
  await BackgroundService.initialize();

  // Initialize all GetX services
  await initServices();

  runApp(const MyApp());
}

// Dependency injection for all our services
Future<void> initServices() async {
  Get.put(PermissionService());
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
