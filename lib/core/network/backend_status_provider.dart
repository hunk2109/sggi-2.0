import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';

enum BackendConnectionState {
  checking,
  online,
  offline,
}

class BackendStatus {
  final BackendConnectionState state;
  final DateTime? lastChecked;
  final String? errorMessage;
  final int? responseTimeMs;

  const BackendStatus({
    this.state = BackendConnectionState.checking,
    this.lastChecked,
    this.errorMessage,
    this.responseTimeMs,
  });

  bool get isOnline => state == BackendConnectionState.online;
  bool get isChecking => state == BackendConnectionState.checking;
  bool get isOffline => state == BackendConnectionState.offline;

  BackendStatus copyWith({
    BackendConnectionState? state,
    DateTime? lastChecked,
    String? errorMessage,
    int? responseTimeMs,
  }) {
    return BackendStatus(
      state: state ?? this.state,
      lastChecked: lastChecked ?? this.lastChecked,
      errorMessage: errorMessage,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
    );
  }
}

class BackendStatusNotifier extends Notifier<BackendStatus> {
  Timer? _timer;
  late final Dio _dio;

  @override
  BackendStatus build() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      ),
    );

    // Ejecutar chequeo inicial
    Future.microtask(() => checkHealth());

    // Chequeo periódico cada 5 segundos
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      checkHealth();
    });

    ref.onDispose(() {
      _timer?.cancel();
    });

    return const BackendStatus(state: BackendConnectionState.checking);
  }

  Future<void> checkHealth() async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _dio.get(ApiConstants.health);
      stopwatch.stop();
      if (response.statusCode == 200) {
        state = BackendStatus(
          state: BackendConnectionState.online,
          lastChecked: DateTime.now(),
          responseTimeMs: stopwatch.elapsedMilliseconds,
        );
      } else {
        state = BackendStatus(
          state: BackendConnectionState.offline,
          lastChecked: DateTime.now(),
          errorMessage: 'HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      stopwatch.stop();
      state = BackendStatus(
        state: BackendConnectionState.offline,
        lastChecked: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }
}

final backendStatusProvider = NotifierProvider<BackendStatusNotifier, BackendStatus>(() {
  return BackendStatusNotifier();
});
