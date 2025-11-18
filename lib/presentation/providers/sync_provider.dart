import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/task_repository.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/utils/app_logger.dart';
import 'task_provider.dart';

// Sync state
final syncStateProvider = StateNotifierProvider<SyncStateNotifier, SyncState>((ref) {
  return SyncStateNotifier(
    repository: ref.watch(taskRepositoryProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
  );
});

class SyncState {
  final bool isSyncing;
  final int pendingOperations;
  final String? lastError;
  final DateTime? lastSyncTime;
  final bool isConnected;

  SyncState({
    this.isSyncing = false,
    this.pendingOperations = 0,
    this.lastError,
    this.lastSyncTime,
    this.isConnected = true,
  });

  SyncState copyWith({
    bool? isSyncing,
    int? pendingOperations,
    String? lastError,
    DateTime? lastSyncTime,
    bool? isConnected,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingOperations: pendingOperations ?? this.pendingOperations,
      lastError: lastError,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  bool get hasError => lastError != null;
  bool get canSync => isConnected && !isSyncing && pendingOperations > 0;
}

class SyncStateNotifier extends StateNotifier<SyncState> {
  final TaskRepository repository;
  final ConnectivityService connectivityService;
  StreamSubscription? _connectivitySubscription;
  StreamSubscription? _pendingOpsSubscription;

  SyncStateNotifier({
    required this.repository,
    required this.connectivityService,
  }) : super(SyncState()) {
    _init();
  }

  void _init() {
    // Initial connectivity state
    state = state.copyWith(isConnected: connectivityService.isConnected);

    // Listen to connectivity changes
    _connectivitySubscription = connectivityService.onConnectivityChanged.listen((isConnected) {
      AppLogger.info('Connectivity changed: ${isConnected ? "Online" : "Offline"}');
      state = state.copyWith(isConnected: isConnected);

      if (isConnected && state.pendingOperations > 0) {
        AppLogger.info('Auto-syncing after connection restored');
        sync();
      }
    });

    // Update pending operations count
    _pendingOpsSubscription = repository.pendingOperationsCount.listen((count) {
      state = state.copyWith(pendingOperations: count);
    });
  }

  Future<void> sync() async {
    if (state.isSyncing) {
      AppLogger.warning('Sync already in progress');
      return;
    }

    if (!state.isConnected) {
      state = state.copyWith(
        lastError: 'No internet connection',
      );
      AppLogger.warning('Cannot sync: No internet connection');
      return;
    }

    if (state.pendingOperations == 0) {
      AppLogger.info('No pending operations to sync');
      return;
    }

    state = state.copyWith(isSyncing: true, lastError: null);
    AppLogger.sync('Starting sync...');

    try {
      await repository.syncPendingOperations();
      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
        lastError: null,
      );
      AppLogger.success('Sync completed successfully');
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        lastError: e.toString(),
      );
      AppLogger.error('Sync failed', e);
    }
  }

  void clearError() {
    state = state.copyWith(lastError: null);
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _pendingOpsSubscription?.cancel();
    super.dispose();
  }
}