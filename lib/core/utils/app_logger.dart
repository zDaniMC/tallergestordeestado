import 'package:flutter/foundation.dart';

class AppLogger {
  static const String _prefix = '[TodoApp]';

  static void info(String message) {
    if (kDebugMode) {
      print('$_prefix ℹ️ $message');
    }
  }

  static void success(String message) {
    if (kDebugMode) {
      print('$_prefix ✅ $message');
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      print('$_prefix ⚠️ $message');
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('$_prefix ❌ $message');
      if (error != null) {
        print('$_prefix Error: $error');
      }
      if (stackTrace != null) {
        print('$_prefix StackTrace: $stackTrace');
      }
    }
  }

  static void debug(String message) {
    if (kDebugMode) {
      print('$_prefix 🐛 $message');
    }
  }

  static void network(String message) {
    if (kDebugMode) {
      print('$_prefix 🌐 $message');
    }
  }

  static void database(String message) {
    if (kDebugMode) {
      print('$_prefix 💾 $message');
    }
  }

  static void sync(String message) {
    if (kDebugMode) {
      print('$_prefix 🔄 $message');
    }
  }
}