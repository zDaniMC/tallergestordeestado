import 'package:sqflite/sqflite.dart';
import '../models/queue_operation_model.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/app_logger.dart';

class QueueLocalDataSource {
  final DatabaseHelper _dbHelper;

  QueueLocalDataSource(this._dbHelper);

  Future<void> enqueueOperation(QueueOperation operation) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(
        'queue_operations',
        operation.toDatabase(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      AppLogger.sync('Enqueued operation: ${operation.op.name} - ${operation.entityId}');
    } catch (e) {
      AppLogger.error('Error enqueuing operation', e);
      rethrow;
    }
  }

  Future<List<QueueOperation>> getPendingOperations() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'queue_operations',
        where: 'completed = ?',
        whereArgs: [0],
        orderBy: 'created_at ASC',
      );

      AppLogger.sync('Retrieved ${maps.length} pending operations');
      return maps.map((map) => QueueOperation.fromDatabase(map)).toList();
    } catch (e) {
      AppLogger.error('Error getting pending operations', e);
      rethrow;
    }
  }

  Future<void> markOperationCompleted(String id) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        'queue_operations',
        {'completed': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
      AppLogger.sync('Marked operation as completed: $id');
    } catch (e) {
      AppLogger.error('Error marking operation completed', e);
      rethrow;
    }
  }

  Future<void> updateOperationAttempt(
      String id,
      int attemptCount,
      String? error,
      ) async {
    try {
      final db = await _dbHelper.database;
      await db.update(
        'queue_operations',
        {
          'attempt_count': attemptCount,
          'last_error': error,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      AppLogger.sync('Updated operation attempt: $id (attempt $attemptCount)');
    } catch (e) {
      AppLogger.error('Error updating operation attempt', e);
      rethrow;
    }
  }

  Future<void> deleteOperation(String id) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        'queue_operations',
        where: 'id = ?',
        whereArgs: [id],
      );
      AppLogger.sync('Deleted operation: $id');
    } catch (e) {
      AppLogger.error('Error deleting operation', e);
      rethrow;
    }
  }

  Future<void> clearCompletedOperations() async {
    try {
      final db = await _dbHelper.database;
      final count = await db.delete(
        'queue_operations',
        where: 'completed = ?',
        whereArgs: [1],
      );
      AppLogger.sync('Cleared $count completed operations');
    } catch (e) {
      AppLogger.error('Error clearing completed operations', e);
      rethrow;
    }
  }

  Future<int> getPendingOperationsCount() async {
    try {
      final db = await _dbHelper.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM queue_operations WHERE completed = 0',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      AppLogger.error('Error getting pending operations count', e);
      return 0;
    }
  }
}