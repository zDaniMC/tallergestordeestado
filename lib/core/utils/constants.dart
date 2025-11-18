class AppConstants {
  // API Configuration
  static const String apiBaseUrl = 'http://10.0.2.2:3000'; // Android emulator
  // static const String apiBaseUrl = 'http://localhost:3000'; // iOS simulator
  // static const String apiBaseUrl = 'http://192.168.1.X:3000'; // Physical device

  static const Duration apiTimeout = Duration(seconds: 10);

  // Database
  static const String databaseName = 'todo_app.db';
  static const int databaseVersion = 1;

  // Sync Configuration
  static const int maxRetryAttempts = 5;
  static const Duration syncInterval = Duration(minutes: 5);
  static const Duration retryBaseDelay = Duration(seconds: 2);

  // UI
  static const Duration snackbarDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 300);

  // Error Messages
  static const String noInternetError = 'No internet connection';
  static const String serverError = 'Server error. Please try again later';
  static const String unknownError = 'An unknown error occurred';
  static const String createTaskError = 'Failed to create task';
  static const String updateTaskError = 'Failed to update task';
  static const String deleteTaskError = 'Failed to delete task';
  static const String syncError = 'Failed to sync tasks';

  // Success Messages
  static const String taskCreated = 'Task created successfully';
  static const String taskUpdated = 'Task updated successfully';
  static const String taskDeleted = 'Task deleted successfully';
  static const String syncCompleted = 'Sync completed successfully';
}