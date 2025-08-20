import 'package:flutter/material.dart';
import 'package:drive_sync_app/models/tracked_file.dart';
import 'package:drive_sync_app/utils/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

class FileStatusTile extends StatelessWidget {
  final TrackedFile file;

  const FileStatusTile({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    final iconData = _getIconForStatus(file.status);
    final color = _getColorForStatus(file.status);
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: ListTile(
        leading: Icon(iconData, color: color),
        title: Text(
          path.basename(file.path), // Show only file name
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          'Scanned: ${DateFormat.yMd().add_jm().format(file.createdAt)}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  IconData _getIconForStatus(FileStatus status) {
    switch (status) {
      case FileStatus.pending:
        return Icons.pending_actions_outlined;
      case FileStatus.uploading:
        return Icons.upload_file_outlined;
      case FileStatus.completed:
        return Icons.check_circle_outline;
      case FileStatus.failed:
        return Icons.error_outline;
    }
  }

  Color _getColorForStatus(FileStatus status) {
     switch (status) {
      case FileStatus.pending:
        return AppColors.warning;
      case FileStatus.uploading:
        return AppColors.primary;
      case FileStatus.completed:
        return AppColors.success;
      case FileStatus.failed:
        return AppColors.error;
    }
  }
}