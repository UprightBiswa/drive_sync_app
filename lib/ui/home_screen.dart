import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:drive_sync_app/controllers/home_controller.dart';
import 'package:drive_sync_app/models/tracked_file.dart';
import 'package:drive_sync_app/ui/widgets/action_button.dart';
import 'package:drive_sync_app/ui/widgets/stat_card.dart';
import 'package:drive_sync_app/utils/app_colors.dart';

class HomeScreen extends StatelessWidget {
  final HomeController controller = Get.put(HomeController());

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drive Sync'),
        actions: [
          Obx(() {
            if (controller.currentUser.value != null) {
              return IconButton(
                icon: const Icon(Icons.logout),
                onPressed: controller.handleSignOut,
                tooltip: 'Sign Out',
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUserInfo(),
            const SizedBox(height: 24),
            _buildStatsGrid(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 16),
            _buildActivityIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Obx(() {
      final user = controller.currentUser.value;
      if (user == null) {
        return Center(
          child: ActionButton(
            label: 'Sign in with Google',
            icon: Icons.login,
            onPressed: controller.handleSignIn,
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(user.photoUrl ?? ''),
              radius: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? 'No Name',
                    style: Get.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(user.email, style: Get.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatsGrid() {
    return Obx(
      () => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.8,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          StatCard(
            label: 'Pending',
            count: controller.statusCounts[FileStatus.pending] ?? 0,
            color: AppColors.warning,
            icon: Icons.pending_actions,
          ),
          StatCard(
            label: 'Uploading',
            count: controller.statusCounts[FileStatus.uploading] ?? 0,
            color: AppColors.primary,
            icon: Icons.upload,
          ),
          StatCard(
            label: 'Completed',
            count: controller.statusCounts[FileStatus.completed] ?? 0,
            color: AppColors.success,
            icon: Icons.check_circle,
          ),
          StatCard(
            label: 'Failed',
            count: controller.statusCounts[FileStatus.failed] ?? 0,
            color: AppColors.error,
            icon: Icons.error,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Obx(
      () => Column(
        children: [
          ActionButton(
            label: 'Start File Scan',
            icon: Icons.folder_open,
            onPressed: controller.handleScan,
            isEnabled: controller.currentUser.value != null,
          ),
          const SizedBox(height: 16),
          ActionButton(
            label: 'Upload Now',
            icon: Icons.cloud_upload,
            onPressed: controller.handleUpload,
            isEnabled: controller.currentUser.value != null,
            backgroundColor: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityIndicator() {
    return Obx(() {
      final isScanning = controller.isScanning.value;
      final isUploading = controller.isUploading.value;

      if (!isScanning && !isUploading) {
        return const Center(child: Text('Idle'));
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: 12),
          Text(
            isScanning ? 'Scanning files...' : 'Uploading files...',
            style: Get.textTheme.bodyMedium,
          ),
        ],
      );
    });
  }
}
