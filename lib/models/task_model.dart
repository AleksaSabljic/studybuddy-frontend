class TaskModel {
  final int id;
  final String title;
  final String? description;
  final int? createdBy;
  final int? assignedTo;
  final String? createdByName;
  final String? assignedToName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // For offline support
  bool isPendingSync;
  String? localId; // used before server assigns real ID

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.createdBy,
    this.assignedTo,
    this.createdByName,
    this.assignedToName,
    this.createdAt,
    this.updatedAt,
    this.isPendingSync = false,
    this.localId,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      createdBy: json['created_by'],
      assignedTo: json['assigned_to'],
      createdByName: json['created_by_name'],
      assignedToName: json['assigned_to_name'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      isPendingSync: json['is_pending_sync'] == 1,
      localId: json['local_id'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'created_by': createdBy,
        'assigned_to': assignedTo,
        'created_by_name': createdByName,
        'assigned_to_name': assignedToName,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'is_pending_sync': isPendingSync ? 1 : 0,
        'local_id': localId,
      };

  TaskModel copyWith({
    String? title,
    String? description,
    int? assignedTo,
    String? assignedToName,
    bool? isPendingSync,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      createdByName: createdByName,
      assignedToName: assignedToName ?? this.assignedToName,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isPendingSync: isPendingSync ?? this.isPendingSync,
      localId: localId,
    );
  }
}
