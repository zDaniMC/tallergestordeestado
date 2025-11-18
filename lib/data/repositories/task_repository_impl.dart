import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../models/task_model.dart';
import '../models/queue_operation_model.dart';
import '../local/task_local_datasource.dart';
import '../local/queue_local_datasource.dart';
import '../remote/task_remote_datasource.dart';
import '../../core/utils/app_logger.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource _localDataSource;
  final QueueLocalDataSource _queueDataSource;
  final TaskRemoteDataSource _remoteDataSource;
  final Uuid _uuid = const Uuid();

  TaskRepositoryImpl({
    required TaskLocalDataSource localDataSource,
    required QueueLocalDataSource queueDataSource,
    required TaskRemoteDataSource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _queueDataSource = queueDataSource,
        _remoteDataSource = remoteDataSource;

  @override
  Future<List<Task>> getAllTasks({bool forceRefresh = false}) async {
    try {
      // Always return local data first (offline-first)
      final localTasks = await _localDataSource.getAllTasks();

      if (forceRefresh) {
        // Try to fetch from API in background
        try {
          AppLogger.sync('Refreshing tasks from API...');
          final remoteTasks = await _remoteDataSource.getAllTasks();

          // Merge with local tasks using Last-Write-Wins
          await _mergeTasks(remoteTasks);

          // Return updated local tasks
          final updatedTasks = await _localDataSource.getAllTasks();
          AppLogger.success('Tasks refreshed successfully');
          return updatedTasks.map((model) => model.toEntity()).toList();
        } catch (e) {
          // If API fails, still return local data
          AppLogger.warning('Failed to refresh from API, using local data: $e');
        }
      }

      return localTasks.map((model) => model.toEntity()).toList();
    } catch (e) {
      AppLogger.error('Error getting all tasks', e);
      rethrow;
    }
  }

  @override
  Future<Task?> getTaskById(String id) async {
    try {
      final taskModel = await _localDataSource.getTaskById(id);
      return taskModel?.toEntity();
    } catch (e) {
      AppLogger.error('Error getting task by id: $id', e);
      rethrow;
    }
  }

  @override
  Future<Task> createTask(String title) async {
    try {
      final now = DateTime.now();
      final taskId = _uuid.v4();

      final task = TaskModel(
        id: taskId,
        title: title,
        completed: false,
        updatedAt: now,
      );

      // Save locally first
      await _localDataSource.insertTask(task);
      AppLogger.success('Task created locally: $taskId');

      // Enqueue operation for sync
      await _enqueueOperation(
        entityId: taskId,
        op: OperationType.CREATE,
        payload: task,
      );

      return task.toEntity();
    } catch (e) {
      AppLogger.error('Error creating task', e);
      rethrow;
    }
  }

  @override
  Future<Task> updateTask(Task task) async {
    try {
      final updatedTask = TaskModel.fromEntity(task).copyWith(
        updatedAt: DateTime.now(),
      );

      // Update locally
      await _localDataSource.updateTask(updatedTask);
      AppLogger.success('Task updated locally: ${task.id}');

      // Enqueue operation for sync
      await _enqueueOperation(
        entityId: task.id,
        op: OperationType.UPDATE,
        payload: updatedTask,
      );

      return updatedTask.toEntity();
    } catch (e) {
      AppLogger.error('Error updating task', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    try {
      // Soft delete locally
      await _localDataSource.deleteTask(id);
      AppLogger.success('Task deleted locally: $id');

      // Enqueue operation for sync
      await _enqueueOperation(
        entityId: id,
        op: OperationType.DELETE,
        payload: TaskModel(
          id: id,
          title: '',
          completed: false,
          updatedAt: DateTime.now(),
          deleted: true,
        ),
      );
    } catch (e) {
      AppLogger.error('Error deleting task', e);
      rethrow;
    }
  }

  @override
  Future<void> syncPendingOperations() async {
    try {
      final pendingOps = await _queueDataSource.getPendingOperations();

      if (pendingOps.isEmpty) {
        AppLogger.info('No pending operations to sync');
        return;
      }

      AppLogger.sync('Syncing ${pendingOps.length} pending operations...');

      for (final operation in pendingOps) {
        try {
          await _executeSyncOperation(operation);
          await _queueDataSource.markOperationCompleted(operation.id);

          // Mark task as synced
          if (operation.op != OperationType.DELETE) {
            await _localDataSource.markAsSynced(
              operation.entityId,
              DateTime.now(),
            );
          } else {
            // Hard delete after successful sync
            await _localDataSource.hardDeleteTask(operation.entityId);
          }

          AppLogger.success('Synced operation: ${operation.op.name} - ${operation.entityId}');
        } catch (e) {
          AppLogger.error('Failed to sync operation ${operation.id}', e);

          // Update attempt count with exponential backoff
          final newAttemptCount = operation.attemptCount + 1;

          // Give up after 5 attempts
          if (newAttemptCount >= 5) {
            AppLogger.warning('Max retry attempts reached for operation ${operation.id}');
            await _queueDataSource.markOperationCompleted(operation.id);
          } else {
            await _queueDataSource.updateOperationAttempt(
              operation.id,
              newAttemptCount,
              e.toString(),
            );
          }
        }
      }

      // Clean up old completed operations
      await _queueDataSource.clearCompletedOperations();
      AppLogger.success('Sync completed successfully');
    } catch (e) {
      AppLogger.error('Error during sync', e);
      rethrow;
    }
  }

  @override
  Stream<int> get pendingOperationsCount async* {
    while (true) {
      try {
        yield await _queueDataSource.getPendingOperationsCount();
      } catch (e) {
        AppLogger.error('Error getting pending operations count', e);
        yield 0;
      }
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  // Private helper methods

  Future<void> _enqueueOperation({
    required String entityId,
    required OperationType op,
    required TaskModel payload,
  }) async {
    final operation = QueueOperation(
      id: _uuid.v4(),
      entity: 'task',
      entityId: entityId,
      op: op,
      payload: json.encode(payload.toJson()),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _queueDataSource.enqueueOperation(operation);
  }

  Future<void> _executeSyncOperation(QueueOperation operation) async {
    final taskJson = json.decode(operation.payload);
    final task = TaskModel.fromJson(taskJson);

    switch (operation.op) {
      case OperationType.CREATE:
        await _remoteDataSource.createTask(
          task,
          idempotencyKey: operation.id,
        );
        break;
      case OperationType.UPDATE:
        await _remoteDataSource.updateTask(
          task,
          idempotencyKey: operation.id,
        );
        break;
      case OperationType.DELETE:
        await _remoteDataSource.deleteTask(operation.entityId);
        break;
    }
  }

  Future<void> _mergeTasks(List<TaskModel> remoteTasks) async {
    for (final remoteTask in remoteTasks) {
      final localTask = await _localDataSource.getTaskById(remoteTask.id);

      if (localTask == null) {
        // New task from server
        await _localDataSource.insertTask(remoteTask.copyWith(
          syncedAt: DateTime.now(),
        ));
        AppLogger.info('Added new task from server: ${remoteTask.id}');
      } else {
        // Conflict resolution: Last-Write-Wins
        if (remoteTask.updatedAt.isAfter(localTask.updatedAt)) {
          // Server version is newer
          await _localDataSource.updateTask(remoteTask.copyWith(
            syncedAt: DateTime.now(),
          ));
          AppLogger.info('Updated task with server version: ${remoteTask.id}');
        } else {
          AppLogger.info('Kept local version (newer): ${localTask.id}');
        }
        // If local is newer, keep it (will be synced later)
      }
    }
  }
}