import '../../domain/entities/task.dart';

class TaskModel extends Task {
  TaskModel({
    required super.id,
    required super.title,
    required super.completed,
    required super.updatedAt,
    super.syncedAt,
    super.deleted,
  });

  // From JSON (API response)
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      completed: json['completed'] as bool,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      syncedAt: json['syncedAt'] != null
          ? DateTime.parse(json['syncedAt'] as String)
          : null,
      deleted: json['deleted'] as bool? ?? false,
    );
  }

  // To JSON (API request)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
      'updatedAt': updatedAt.toIso8601String(),
      if (syncedAt != null) 'syncedAt': syncedAt!.toIso8601String(),
      'deleted': deleted,
    };
  }

  // From SQLite
  factory TaskModel.fromDatabase(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      completed: (map['completed'] as int) == 1,
      updatedAt: DateTime.parse(map['updated_at'] as String),
      syncedAt: map['synced_at'] != null
          ? DateTime.parse(map['synced_at'] as String)
          : null,
      deleted: (map['deleted'] as int) == 1,
    );
  }

  // To SQLite
  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'title': title,
      'completed': completed ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
      'deleted': deleted ? 1 : 0,
    };
  }

  Task toEntity() {
    return Task(
      id: id,
      title: title,
      completed: completed,
      updatedAt: updatedAt,
      syncedAt: syncedAt,
      deleted: deleted,
    );
  }

  factory TaskModel.fromEntity(Task task) {
    return TaskModel(
      id: task.id,
      title: task.title,
      completed: task.completed,
      updatedAt: task.updatedAt,
      syncedAt: task.syncedAt,
      deleted: task.deleted,
    );
  }

  @override
  TaskModel copyWith({
    String? id,
    String? title,
    bool? completed,
    DateTime? updatedAt,
    DateTime? syncedAt,
    bool? deleted,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      deleted: deleted ?? this.deleted,
    );
  }
}