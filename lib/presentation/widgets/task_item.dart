import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/task.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskItem({
    Key? key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    final isSynced = task.isSynced;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: task.completed ? 1 : 2,
      child: ListTile(
        leading: Checkbox(
          value: task.completed,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.completed ? TextDecoration.lineThrough : null,
            color: task.completed ? Colors.grey : null,
            fontWeight: task.completed ? FontWeight.normal : FontWeight.w500,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(
                isSynced ? Icons.cloud_done : Icons.cloud_queue,
                size: 14,
                color: isSynced ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                dateFormat.format(task.updatedAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.edit,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: onEdit,
              tooltip: 'Edit task',
            ),
            IconButton(
              icon: const Icon(
                Icons.delete,
                size: 20,
                color: Colors.red,
              ),
              onPressed: onDelete,
              tooltip: 'Delete task',
            ),
          ],
        ),
      ),
    );
  }
}