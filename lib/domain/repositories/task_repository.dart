import '../entities/task.dart';

abstract class TaskRepository {
  /// Get all tasks from local storage
  /// If [forceRefresh] is true, fetches from API and merges with local
  Future<List<Task>> getAllTasks({bool forceRefresh = false});

  /// Get a single task by ID
  Future<Task?> getTaskById(String id);

  /// Create a new task
  Future<Task> createTask(String title);

  /// Update an existing task
  Future<Task> updateTask(Task task);

  /// Delete a task
  Future<void> deleteTask(String id);

  /// Sync all pending operations with the server
  Future<void> syncPendingOperations();

  /// Stream of pending operations count
  Stream<int> get pendingOperationsCount;
}