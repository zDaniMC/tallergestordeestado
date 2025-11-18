import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../../core/database/database_helper.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/utils/constants.dart';
import '../../data/local/task_local_datasource.dart';
import '../../data/local/queue_local_datasource.dart';
import '../../data/remote/task_remote_datasource.dart';
import '../../data/repositories/task_repository_impl.dart';

// Core dependencies
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

// Data sources
final taskLocalDataSourceProvider = Provider<TaskLocalDataSource>((ref) {
  return TaskLocalDataSource(ref.watch(databaseHelperProvider));
});

final queueLocalDataSourceProvider = Provider<QueueLocalDataSource>((ref) {
  return QueueLocalDataSource(ref.watch(databaseHelperProvider));
});

final taskRemoteDataSourceProvider = Provider<TaskRemoteDataSource>((ref) {
  return TaskRemoteDataSource(baseUrl: AppConstants.apiBaseUrl);
});

// Repository
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepositoryImpl(
    localDataSource: ref.watch(taskLocalDataSourceProvider),
    queueDataSource: ref.watch(queueLocalDataSourceProvider),
    remoteDataSource: ref.watch(taskRemoteDataSourceProvider),
  );
});

// Task filter
enum TaskFilter { all, pending, completed }

final taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);

// Task list state
final taskListProvider = FutureProvider<List<Task>>((ref) async {
  final repository = ref.watch(taskRepositoryProvider);
  final filter = ref.watch(taskFilterProvider);

  final tasks = await repository.getAllTasks();

  switch (filter) {
    case TaskFilter.all:
      return tasks;
    case TaskFilter.pending:
      return tasks.where((task) => !task.completed).toList();
    case TaskFilter.completed:
      return tasks.where((task) => task.completed).toList();
  }
});

// Task actions
final taskActionsProvider = Provider<TaskActions>((ref) {
  return TaskActions(
    repository: ref.watch(taskRepositoryProvider),
    onTaskChanged: () {
      ref.invalidate(taskListProvider);
    },
  );
});

class TaskActions {
  final TaskRepository repository;
  final VoidCallback onTaskChanged;

  TaskActions({
    required this.repository,
    required this.onTaskChanged,
  });

  Future<void> createTask(String title) async {
    await repository.createTask(title);
    onTaskChanged();
  }

  Future<void> toggleTaskCompletion(Task task) async {
    await repository.updateTask(task.copyWith(completed: !task.completed));
    onTaskChanged();
  }

  Future<void> updateTask(Task task) async {
    await repository.updateTask(task);
    onTaskChanged();
  }

  Future<void> deleteTask(String id) async {
    await repository.deleteTask(id);
    onTaskChanged();
  }

  Future<void> refresh() async {
    await repository.getAllTasks(forceRefresh: true);
    onTaskChanged();
  }
}

typedef VoidCallback = void Function();