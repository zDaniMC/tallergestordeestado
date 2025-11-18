class Task {
  final String id;
  final String title;
  final bool completed;
  final DateTime updatedAt;
  final DateTime? syncedAt;
  final bool deleted;

  Task({
    required this.id,
    required this.title,
    required this.completed,
    required this.updatedAt,
    this.syncedAt,
    this.deleted = false,
  });

  Task copyWith({
    String? id,
    String? title,
    bool? completed,
    DateTime? updatedAt,
    DateTime? syncedAt,
    bool? deleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      deleted: deleted ?? this.deleted,
    );
  }

  bool get isSynced {
    if (syncedAt == null) return false;
    return syncedAt!.isAfter(updatedAt.subtract(const Duration(seconds: 1)));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Task(id: $id, title: $title, completed: $completed, synced: $isSynced)';
  }
}