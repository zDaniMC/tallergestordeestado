import 'package:sqflite/sqflite.dart';
import '../models/task_model.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/app_logger.dart';

class TaskLocalDataSource {
  final DatabaseHelper _dbHelper;

  TaskLocalDataSource(this._dbHelper);

  Future<List<TaskModel>> getAllTasks() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'tasks',
        where: 'deleted = ?',
        whereArgs: [0],
        orderBy: 'updated_at DESC',
      );

      AppLogger.database('Retrieved ${maps.length} tasks from local storage');
      return maps.map((map) => TaskModel.fromDatabase(map)).toList();
    } catch (e) {
      AppLogger.error('Error getting all tasks', e);
      rethrow;
    }
  }

  Future<TaskModel?> getTaskById(String id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'tasks',
        where: 'id = ? AND deleted = ?',
        whereArgs: [id, 0],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return TaskModel.fromDatabase(maps.first);
    } catch (e) {
      AppLogger.error('Error getting task by id: $id', e);
      rethrow;
    }
  }

  Future<void> insertTask(TaskModel task) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(
        'tasks',
        task.toDatabase(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      AppLogger.database('Inserted task: ${task.id}');
    } catch (e) {
      AppLogger.error('Error inserting task', e);
      rethrow;
    }
  }

  Future<void> updateTask(TaskModel task) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        'tasks',
        task.toDatabase(),
        where: 'id = ?',
        whereArgs: [task.id],
      );
      AppLogger.database('Updated task: ${task.id}');
    } catch (e) {
      AppLogger.error('Error updating task', e);
      rethrow;
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      final db = await _dbHelper.database;
      // Soft delete
      await db.update(
        'tasks',
        {
          'deleted': 1,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      AppLogger.database('Soft deleted task: $id');
    } catch (e) {
      AppLogger.error('Error deleting task', e);
      rethrow;
    }
  }

  Future<void> hardDeleteTask(String id) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        'tasks',
        where: 'id = ?',
        whereArgs: [id],
      );
      AppLogger.database('Hard deleted task: $id');
    } catch (e) {
      AppLogger.error('Error hard deleting task', e);
      rethrow;
    }
  }

  Future<void> markAsSynced(String id, DateTime syncedAt) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        'tasks',
        {'synced_at': syncedAt.toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      AppLogger.database('Marked task as synced: $id');
    } catch (e) {
      AppLogger.error('Error marking task as synced', e);
      rethrow;
    }
  }

  Future<List<TaskModel>> getUnsyncedTasks() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'tasks',
        where: 'synced_at IS NULL OR updated_at > synced_at',
      );

      AppLogger.database('Found ${maps.length} unsynced tasks');
      return maps.map((map) => TaskModel.fromDatabase(map)).toList();
    } catch (e) {
      AppLogger.error('Error getting unsynced tasks', e);
      rethrow;
    }
  }

  Future<void> clearAllTasks() async {
    try {
      final db = await _dbHelper.database;
      await db.delete('tasks');
      AppLogger.database('Cleared all tasks');
    } catch (e) {
      AppLogger.error('Error clearing all tasks', e);
      rethrow;
    }
  }
}