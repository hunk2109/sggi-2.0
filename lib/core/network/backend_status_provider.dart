import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import 'backend_launcher_service.dart';

enum BackendConnectionState {
  checking,
  online,
  offline,
}

class BackendStatus {
  final BackendConnectionState state;
  final DateTime? lastChecked;
  final String? errorMessage;
  final String? diagnosticTooltip;
  final int? responseTimeMs;

  const BackendStatus({
    this.state = BackendConnectionState.checking,
    this.lastChecked,
    this.errorMessage,
    this.diagnosticTooltip,
    this.responseTimeMs,
  });

  bool get isOnline => state == BackendConnectionState.online;
  bool get isChecking => state == BackendConnectionState.checking;
  bool get isOffline => state == BackendConnectionState.offline;

  BackendStatus copyWith({
    BackendConnectionState? state,
    DateTime? lastChecked,
    String? errorMessage,
    String? diagnosticTooltip,
    int? responseTimeMs,
  }) {
    return BackendStatus(
      state: state ?? this.state,
      lastChecked: lastChecked ?? this.lastChecked,
      errorMessage: errorMessage,
      diagnosticTooltip: diagnosticTooltip ?? this.diagnosticTooltip,
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

  String _formatConnectionError(Object error) {
    if (error is DioException) {
      final inner = error.error?.toString();
      if (inner != null && inner.isNotEmpty) {
        return inner;
      }
      return error.message ?? error.type.name;
    }
    return error.toString();
  }

  Future<void> checkHealth() async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await _dio.get(ApiConstants.health);
      stopwatch.stop();
      if (response.statusCode == 200) {
        final logPath = BackendLauncherService.instance.logFilePath;
        state = BackendStatus(
          state: BackendConnectionState.online,
          lastChecked: DateTime.now(),
          responseTimeMs: stopwatch.elapsedMilliseconds,
          diagnosticTooltip:
              'Backend activo en ${ApiConstants.baseUrl} (${stopwatch.elapsedMilliseconds} ms)'
              '${logPath != null ? '\nLog: $logPath' : ''}',
        );
      } else {
        final errText = 'HTTP ${response.statusCode}';
        final diag = BackendLauncherService.instance.getDiagnosticSummary(connectionError: errText);
        state = BackendStatus(
          state: BackendConnectionState.offline,
          lastChecked: DateTime.now(),
          errorMessage: errText,
          diagnosticTooltip: diag.isNotEmpty ? diag : errText,
        );
      }
    } catch (e) {
      stopwatch.stop();
      final errText = _formatConnectionError(e);
      unawaited(BackendLauncherService.instance.ensureBackendRunning());
      final diag = BackendLauncherService.instance.getDiagnosticSummary(connectionError: errText);
      state = BackendStatus(
        state: BackendConnectionState.offline,
        lastChecked: DateTime.now(),
        errorMessage: errText,
        diagnosticTooltip: diag.isNotEmpty ? diag : errText,
      );
    }
  }
}

final backendStatusProvider = NotifierProvider<BackendStatusNotifier, BackendStatus>(() {
  return BackendStatusNotifier();
});
