import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';
import '../../core/utils/app_logger.dart';

class TaskRemoteDataSource {
  final String baseUrl;
  final http.Client client;

  TaskRemoteDataSource({
    required this.baseUrl,
    http.Client? client,
  }) : client = client ?? http.Client();

  Future<List<TaskModel>> getAllTasks() async {
    try {
      AppLogger.network('GET $baseUrl/tasks');

      final response = await client
          .get(
        Uri.parse('$baseUrl/tasks'),
        headers: {'Content-Type': 'application/json'},
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        AppLogger.success('Fetched ${jsonList.length} tasks from API');
        return jsonList.map((json) => TaskModel.fromJson(json)).toList();
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Failed to fetch tasks: ${response.body}',
        );
      }
    } catch (e) {
      AppLogger.error('Error fetching tasks from API', e);
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: 'Network error: $e',
      );
    }
  }

  Future<TaskModel> getTaskById(String id) async {
    try {
      AppLogger.network('GET $baseUrl/tasks/$id');

      final response = await client
          .get(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: {'Content-Type': 'application/json'},
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        AppLogger.success('Fetched task $id from API');
        return TaskModel.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw ApiException(
          statusCode: 404,
          message: 'Task not found',
        );
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Failed to fetch task: ${response.body}',
        );
      }
    } catch (e) {
      AppLogger.error('Error fetching task $id from API', e);
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: 'Network error: $e',
      );
    }
  }

  Future<TaskModel> createTask(
      TaskModel task, {
        String? idempotencyKey,
      }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
      };

      AppLogger.network('POST $baseUrl/tasks');

      final response = await client
          .post(
        Uri.parse('$baseUrl/tasks'),
        headers: headers,
        body: json.encode(task.toJson()),
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.success('Created task ${task.id} on API');
        return TaskModel.fromJson(json.decode(response.body));
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Failed to create task: ${response.body}',
        );
      }
    } catch (e) {
      AppLogger.error('Error creating task on API', e);
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: 'Network error: $e',
      );
    }
  }

  Future<TaskModel> updateTask(
      TaskModel task, {
        String? idempotencyKey,
      }) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
      };

      AppLogger.network('PUT $baseUrl/tasks/${task.id}');

      final response = await client
          .put(
        Uri.parse('$baseUrl/tasks/${task.id}'),
        headers: headers,
        body: json.encode(task.toJson()),
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        AppLogger.success('Updated task ${task.id} on API');
        return TaskModel.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw ApiException(
          statusCode: 404,
          message: 'Task not found',
        );
      } else {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Failed to update task: ${response.body}',
        );
      }
    } catch (e) {
      AppLogger.error('Error updating task ${task.id} on API', e);
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: 'Network error: $e',
      );
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      AppLogger.network('DELETE $baseUrl/tasks/$id');

      final response = await client
          .delete(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: {'Content-Type': 'application/json'},
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Failed to delete task: ${response.body}',
        );
      }

      AppLogger.success('Deleted task $id from API');
    } catch (e) {
      AppLogger.error('Error deleting task $id from API', e);
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: 0,
        message: 'Network error: $e',
      );
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';

  bool get isNetworkError => statusCode == 0;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isServerError => statusCode >= 500;
}