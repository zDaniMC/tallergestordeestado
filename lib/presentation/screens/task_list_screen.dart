import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/task_provider.dart';
import '../providers/sync_provider.dart';
import '../widgets/task_item.dart';
import '../widgets/task_form_dialog.dart';
import '../../domain/entities/task.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskListProvider);
    final syncState = ref.watch(syncStateProvider);
    final filter = ref.watch(taskFilterProvider);
    final taskActions = ref.read(taskActionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          // Connection indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              syncState.isConnected ? Icons.wifi : Icons.wifi_off,
              color: syncState.isConnected ? Colors.green : Colors.red,
            ),
          ),
          // Sync indicator
          if (syncState.pendingOperations > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Chip(
                  avatar: syncState.isSyncing
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                      : const Icon(Icons.cloud_upload, size: 16, color: Colors.white),
                  label: Text('${syncState.pendingOperations}'),
                  backgroundColor: syncState.isSyncing
                      ? Colors.orange
                      : Colors.blue,
                  labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await taskActions.refresh();
              ref.read(syncStateProvider.notifier).sync();
            },
            tooltip: 'Refresh and sync',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: filter == TaskFilter.all,
                    onSelected: (_) =>
                    ref.read(taskFilterProvider.notifier).state =
                        TaskFilter.all,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Pending'),
                    selected: filter == TaskFilter.pending,
                    onSelected: (_) =>
                    ref.read(taskFilterProvider.notifier).state =
                        TaskFilter.pending,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Completed'),
                    selected: filter == TaskFilter.completed,
                    onSelected: (_) =>
                    ref.read(taskFilterProvider.notifier).state =
                        TaskFilter.completed,
                  ),
                ],
              ),
            ),
          ),
          // Sync error banner
          if (syncState.hasError)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      syncState.lastError ?? 'Unknown error',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () =>
                        ref.read(syncStateProvider.notifier).clearError(),
                    color: Colors.red.shade700,
                  ),
                ],
              ),
            ),
          // Task list
          Expanded(
            child: tasksAsync.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return _buildEmptyState(filter);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await taskActions.refresh();
                    ref.read(syncStateProvider.notifier).sync();
                  },
                  child: ListView.builder(
                    itemCount: tasks.length,
                    padding: const EdgeInsets.only(bottom: 80),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return TaskItem(
                        task: task,
                        onToggle: () => taskActions.toggleTaskCompletion(task),
                        onEdit: () => _showEditDialog(context, ref, task),
                        onDelete: () => _showDeleteConfirmation(
                          context,
                          ref,
                          task,
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading tasks',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(taskListProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  Widget _buildEmptyState(TaskFilter filter) {
    String message;
    String subtitle;
    IconData icon;

    switch (filter) {
      case TaskFilter.all:
        message = 'No tasks yet';
        subtitle = 'Tap the + button to create your first task';
        icon = Icons.task_alt;
        break;
      case TaskFilter.pending:
        message = 'No pending tasks';
        subtitle = 'All tasks are completed!';
        icon = Icons.check_circle_outline;
        break;
      case TaskFilter.completed:
        message = 'No completed tasks';
        subtitle = 'Complete some tasks to see them here';
        icon = Icons.radio_button_unchecked;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final title = await TaskFormDialog.show(
      context: context,
      title: 'New Task',
      confirmButtonText: 'Create',
    );

    if (title != null && title.isNotEmpty) {
      try {
        await ref.read(taskActionsProvider).createTask(title);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task created successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating task: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showEditDialog(
      BuildContext context,
      WidgetRef ref,
      Task task,
      ) async {
    final newTitle = await TaskFormDialog.show(
      context: context,
      initialTitle: task.title,
      title: 'Edit Task',
      confirmButtonText: 'Save',
    );

    if (newTitle != null && newTitle.isNotEmpty && newTitle != task.title) {
      try {
        await ref.read(taskActionsProvider).updateTask(
          task.copyWith(title: newTitle),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task updated successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating task: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context,
      WidgetRef ref,
      Task task,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text(
          'Are you sure you want to delete "${task.title}"?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(taskActionsProvider).deleteTask(task.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task deleted successfully'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting task: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}