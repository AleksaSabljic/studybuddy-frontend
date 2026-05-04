class FileModel {
  final int id;
  final int? taskId;
  final int? uploadedBy;
  final String filename;
  final String originalName;
  final String mimetype;
  final int size;
  final DateTime? createdAt;

  FileModel({
    required this.id,
    this.taskId,
    this.uploadedBy,
    required this.filename,
    required this.originalName,
    required this.mimetype,
    required this.size,
    this.createdAt,
  });

  bool get isImage =>
      mimetype.startsWith('image/');

  bool get isPdf => mimetype == 'application/pdf';

  String get sizeFormatted {
    if (size < 1024) return '${size}B';
    if (size < 1048576) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / 1048576).toStringAsFixed(1)}MB';
  }

  factory FileModel.fromJson(Map<String, dynamic> json) {
    return FileModel(
      id: json['id'],
      taskId: json['task_id'],
      uploadedBy: json['uploaded_by'],
      filename: json['filename'] ?? '',
      originalName: json['original_name'] ?? '',
      mimetype: json['mimetype'] ?? '',
      size: json['size'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}
