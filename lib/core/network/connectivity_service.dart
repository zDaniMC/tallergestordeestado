import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();

  Stream<bool> get onConnectivityChanged => _controller.stream;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  ConnectivityService() {
    _init();
  }

  void _init() {
    // Check initial connectivity
    _checkConnectivity();

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _checkConnectivity();
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final wasConnected = _isConnected;

      _isConnected = results.isNotEmpty &&
          !results.contains(ConnectivityResult.none);

      // Only notify if status changed
      if (wasConnected != _isConnected) {
        _controller.add(_isConnected);

        if (_isConnected) {
          print('🟢 Connection restored');
        } else {
          print('🔴 Connection lost');
        }
      }
    } catch (e) {
      print('Error checking connectivity: $e');
      _isConnected = false;
      _controller.add(false);
    }
  }

  void dispose() {
    _controller.close();
  }
}