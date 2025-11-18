enum OperationType {
  CREATE,
  UPDATE,
  DELETE,
}

class QueueOperation {
  final String id;
  final String entity;
  final String entityId;
  final OperationType op;
  final String payload;
  final int createdAt;
  final int attemptCount;
  final String? lastError;
  final bool completed;

  QueueOperation({
    required this.id,
    required this.entity,
    required this.entityId,
    required this.op,
    required this.payload,
    required this.createdAt,
    this.attemptCount = 0,
    this.lastError,
    this.completed = false,
  });

  factory QueueOperation.fromDatabase(Map<String, dynamic> map) {
    return QueueOperation(
      id: map['id'] as String,
      entity: map['entity'] as String,
      entityId: map['entity_id'] as String,
      op: OperationType.values.firstWhere(
            (e) => e.name == map['op'],
      ),
      payload: map['payload'] as String,
      createdAt: map['created_at'] as int,
      attemptCount: map['attempt_count'] as int,
      lastError: map['last_error'] as String?,
      completed: (map['completed'] as int) == 1,
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'entity': entity,
      'entity_id': entityId,
      'op': op.name,
      'payload': payload,
      'created_at': createdAt,
      'attempt_count': attemptCount,
      'last_error': lastError,
      'completed': completed ? 1 : 0,
    };
  }

  QueueOperation copyWith({
    int? attemptCount,
    String? lastError,
    bool? completed,
  }) {
    return QueueOperation(
      id: id,
      entity: entity,
      entityId: entityId,
      op: op,
      payload: payload,
      createdAt: createdAt,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
      completed: completed ?? this.completed,
    );
  }

  @override
  String toString() {
    return 'QueueOperation(id: $id, op: ${op.name}, entityId: $entityId, attempts: $attemptCount)';
  }
}