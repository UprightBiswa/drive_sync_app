enum FileStatus { pending, uploading, completed, failed }

class TrackedFile {
  final int id;
  final String path;
  final FileStatus status;
  final DateTime createdAt;

  TrackedFile({
    required this.id,
    required this.path,
    required this.status,
    required this.createdAt,
  });

  // Sembast uses Map<String, dynamic>
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TrackedFile.fromJson(int id, Map<String, dynamic> json) {
    return TrackedFile(
      id: id,
      path: json['path'],
      status: FileStatus.values.firstWhere((e) => e.toString() == json['status']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
  //from map
  factory TrackedFile.fromMap(Map<String, dynamic> map) {
    return TrackedFile(
      id: map['id'],
      path: map['path'],
      status: FileStatus.values.firstWhere((e) => e.toString() == map['status']),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  //tomap
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}