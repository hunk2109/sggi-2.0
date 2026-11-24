import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Servicio encargado de iniciar y detener automáticamente el backend local
/// (`gym-backend`) cuando SGGI 2.0 se ejecuta en Windows como aplicación instalada.
class BackendLauncherService {
  BackendLauncherService._();
  static final BackendLauncherService instance = BackendLauncherService._();

  Process? _backendProcess;
  bool _starting = false;
  String? _lastError;
  String? _logFilePath;
  final List<String> _recentLogs = <String>[];
  static const int _maxLogLines = 80;

  String? get lastError => _lastError;
  String? get logFilePath => _logFilePath;
  List<String> get recentLogs => List<String>.unmodifiable(_recentLogs);
  bool get isStarting => _starting;
  bool get hasRunningChildProcess => _backendProcess != null;

  void _appendLog(String message, {bool isError = false}) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final line = '[$timestamp] $message';
    _recentLogs.add(line);
    if (_recentLogs.length > _maxLogLines) {
      _recentLogs.removeRange(0, _recentLogs.length - _maxLogLines);
    }
    if (isError) {
      _lastError = message;
    }
    debugPrint('[BackendLauncher] $message');
    _writeLineToLauncherLog(line);
  }

  File _resolveLauncherLogFile() {
    if (_logFilePath != null) {
      return File(_logFilePath!);
    }
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final candidates = <String>[
      '$exeDir${Platform.pathSeparator}backend-launcher.log',
      '${Directory.systemTemp.path}${Platform.pathSeparator}sggi-backend-launcher.log',
    ];
    for (final path in candidates) {
      try {
        final f = File(path);
        f.writeAsStringSync('', mode: FileMode.append, flush: true);
        _logFilePath = path;
        return f;
      } catch (_) {}
    }
    _logFilePath = candidates.last;
    return File(_logFilePath!);
  }

  void _writeLineToLauncherLog(String line) {
    try {
      final file = _resolveLauncherLogFile();
      file.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
    } catch (_) {}
  }

  /// Resumen legible para mostrar en el Tooltip / Hover de estado.
  String getDiagnosticSummary({String? connectionError}) {
    final buffer = StringBuffer();
    if (_lastError != null && _lastError!.isNotEmpty) {
      buffer.writeln('Motivo: $_lastError');
    } else if (_starting) {
      buffer.writeln('Estado: Iniciando servidor local...');
    } else if (connectionError != null && connectionError.isNotEmpty) {
      buffer.writeln('Conexión: $connectionError');
    }
    if (_logFilePath != null) {
      buffer.writeln('Log: $_logFilePath');
    }
    if (_recentLogs.isNotEmpty) {
      final tail = _recentLogs.length > 6
          ? _recentLogs.sublist(_recentLogs.length - 6)
          : _recentLogs;
      buffer.writeln('--- Últimos eventos ---');
      for (final line in tail) {
        buffer.writeln(line);
      }
    }
    return buffer.toString().trim();
  }

  /// Verifica si el puerto 3000 ya está respondiendo en localhost.
  Future<bool> isBackendPortOpen({
    String host = '127.0.0.1',
    int port = 3000,
    Duration timeout = const Duration(milliseconds: 350),
  }) async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      await socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Si el instalador dejó `backend_bundle.tar` sin descomprimir (ej. por redirección WOW64),
  /// lo extrae automáticamente usando el tar nativo de Windows.
  Future<void> _ensureBundleExtracted(String backendPath) async {
    final mainJs = File('$backendPath${Platform.pathSeparator}dist${Platform.pathSeparator}main.js');
    final bundleTar = File('$backendPath${Platform.pathSeparator}backend_bundle.tar');
    if (!mainJs.existsSync() && bundleTar.existsSync()) {
      try {
        _appendLog('Extrayendo backend_bundle.tar en $backendPath...');
        final tarExe = File(r'C:\Windows\System32\tar.exe').existsSync()
            ? r'C:\Windows\System32\tar.exe'
            : 'tar';
        final result = await Process.run(
          tarExe,
          ['-xf', bundleTar.path, '-C', backendPath],
          workingDirectory: backendPath,
        );
        if (result.exitCode == 0 && mainJs.existsSync()) {
          _appendLog('backend_bundle.tar extraído correctamente.');
          try {
            bundleTar.deleteSync();
          } catch (_) {}
        } else {
          _appendLog(
            'Error extrayendo backend_bundle.tar (exit=${result.exitCode}): ${result.stderr}',
            isError: true,
          );
        }
      } catch (e) {
        _appendLog('Excepción extrayendo backend_bundle.tar: $e', isError: true);
      }
    }
  }

  /// Resuelve el directorio donde reside el backend empaquetado o de desarrollo.
  Future<Directory?> _resolveBackendDirectory() async {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final candidates = <String>[
      '$exeDir${Platform.pathSeparator}backend',
      r'C:\SGGI 2.0\backend',
      r'C:\develop\gym-backend',
    ];

    for (final path in candidates) {
      await _ensureBundleExtracted(path);
      final mainJs = File('$path${Platform.pathSeparator}dist${Platform.pathSeparator}main.js');
      if (mainJs.existsSync()) {
        return Directory(path);
      }
    }

    _appendLog(
      'No se encontró dist\\main.js en: ${candidates.join(' | ')}',
      isError: true,
    );
    return null;
  }

  /// Resuelve la ruta completa a `node.exe` (empaquetado o del sistema).
  String _resolveNodeExecutable(String backendDirPath) {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final candidates = <String>[
      '$backendDirPath${Platform.pathSeparator}node.exe',
      '$exeDir${Platform.pathSeparator}backend${Platform.pathSeparator}node.exe',
      r'C:\SGGI 2.0\backend\node.exe',
      r'C:\Program Files\nodejs\node.exe',
      r'C:\Program Files (x86)\nodejs\node.exe',
    ];
    for (final path in candidates) {
      if (File(path).existsSync()) {
        return path;
      }
    }
    return 'node';
  }

  /// Inicia el backend en segundo plano (sin ventana de consola) si aún no está corriendo.
  Future<void> ensureBackendRunning() async {
    if (!Platform.isWindows) return;
    if (_starting) return;

    if (await isBackendPortOpen()) {
      _lastError = null;
      return;
    }

    _starting = true;
    try {
      final backendDir = await _resolveBackendDirectory();
      if (backendDir == null) {
        return;
      }

      final nodeExecutable = _resolveNodeExecutable(backendDir.path);
      final entryPoint = '${backendDir.path}${Platform.pathSeparator}dist${Platform.pathSeparator}main.js';

      _appendLog('Iniciando backend: "$nodeExecutable" "$entryPoint" (cwd: ${backendDir.path})');
      _backendProcess = await Process.start(
        nodeExecutable,
        [entryPoint],
        workingDirectory: backendDir.path,
        runInShell: false,
        environment: {
          ...Platform.environment,
          'NODE_ENV': 'production',
        },
      );

      final runtimeLogPath = '${backendDir.path}${Platform.pathSeparator}backend-runtime.log';
      _logFilePath = runtimeLogPath;
      final logFile = File(runtimeLogPath);
      final logSink = logFile.openWrite(mode: FileMode.append);
      logSink.writeln('\n--- [${DateTime.now().toIso8601String()}] Starting backend ($nodeExecutable $entryPoint) ---');

      void handleStream(Stream<List<int>> stream, {required bool isErr}) {
        stream
            .transform(const Utf8Decoder(allowMalformed: true))
            .transform(const LineSplitter())
            .listen(
          (line) {
            logSink.writeln(line);
            final trimmed = line.trim();
            if (trimmed.isNotEmpty) {
              final looksLikeError = isErr ||
                  trimmed.contains('ERROR') ||
                  trimmed.contains('Error:') ||
                  trimmed.contains('ECONNREFUSED') ||
                  trimmed.contains('Access denied');
              _appendLog(trimmed, isError: looksLikeError);
            }
          },
          onError: (_) {},
        );
      }

      handleStream(_backendProcess!.stdout, isErr: false);
      handleStream(_backendProcess!.stderr, isErr: true);

      _backendProcess!.exitCode.then((code) async {
        _appendLog('Proceso de backend finalizó con código $code', isError: code != 0);
        try {
          logSink.writeln('\n--- [${DateTime.now().toIso8601String()}] Backend exited with code $code ---');
          await logSink.flush();
          await logSink.close();
        } catch (_) {}
        _backendProcess = null;
      });

      // Esperar hasta que el puerto 3000 esté listo (máx. 8 segundos)
      for (int i = 0; i < 25; i++) {
        await Future.delayed(const Duration(milliseconds: 320));
        if (await isBackendPortOpen()) {
          _lastError = null;
          _appendLog('Backend listo y escuchando en 127.0.0.1:3000.');
          break;
        }
        if (_backendProcess == null) {
          break;
        }
      }
    } catch (e) {
      _appendLog('Error al iniciar backend: $e', isError: true);
    } finally {
      _starting = false;
    }
  }

  /// Detiene el proceso del backend si fue iniciado por esta instancia de SGGI 2.0.
  void stopBackend() {
    final proc = _backendProcess;
    if (proc != null) {
      _appendLog('Deteniendo proceso de backend (PID: ${proc.pid})...');
      proc.kill(ProcessSignal.sigterm);
      _backendProcess = null;
    }
  }
}
