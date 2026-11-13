import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Servicio encargado de iniciar y detener automáticamente el backend local
/// (`gym-backend`) cuando SGGI 2.0 se ejecuta en Windows como aplicación instalada.
class BackendLauncherService {
  BackendLauncherService._();
  static final BackendLauncherService instance = BackendLauncherService._();

  Process? _backendProcess;
  bool _starting = false;

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
        debugPrint('[BackendLauncher] Extrayendo backend_bundle.tar en $backendPath...');
        final tarExe = File(r'C:\Windows\System32\tar.exe').existsSync()
            ? r'C:\Windows\System32\tar.exe'
            : 'tar';
        final result = await Process.run(
          tarExe,
          ['-xf', bundleTar.path, '-C', backendPath],
          workingDirectory: backendPath,
        );
        if (result.exitCode == 0 && mainJs.existsSync()) {
          try {
            bundleTar.deleteSync();
          } catch (_) {}
        }
      } catch (e) {
        debugPrint('[BackendLauncher] Error extrayendo backend_bundle.tar: $e');
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
      debugPrint('[BackendLauncher] El backend ya está activo en 127.0.0.1:3000.');
      return;
    }

    _starting = true;
    try {
      final backendDir = await _resolveBackendDirectory();
      if (backendDir == null) {
        debugPrint('[BackendLauncher] No se encontró carpeta de backend compilado (dist/main.js).');
        return;
      }

      final nodeExecutable = _resolveNodeExecutable(backendDir.path);
      final entryPoint = '${backendDir.path}${Platform.pathSeparator}dist${Platform.pathSeparator}main.js';

      debugPrint('[BackendLauncher] Iniciando backend con "$nodeExecutable" desde: ${backendDir.path}');
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

      // Redirigir logs a un archivo en la carpeta del backend para diagnóstico
      final logFile = File('${backendDir.path}${Platform.pathSeparator}backend-runtime.log');
      final logSink = logFile.openWrite(mode: FileMode.append);
      logSink.writeln('\n--- [${DateTime.now().toIso8601String()}] Starting backend ($nodeExecutable $entryPoint) ---');
      _backendProcess!.stdout.listen(
        (data) => logSink.add(data),
        onError: (_) {},
      );
      _backendProcess!.stderr.listen(
        (data) => logSink.add(data),
        onError: (_) {},
      );
      _backendProcess!.exitCode.then((code) async {
        debugPrint('[BackendLauncher] Proceso de backend finalizó con código $code');
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
          debugPrint('[BackendLauncher] Backend listo en 127.0.0.1:3000.');
          break;
        }
      }
    } catch (e) {
      debugPrint('[BackendLauncher] Error al iniciar el backend automáticamente: $e');
    } finally {
      _starting = false;
    }
  }

  /// Detiene el proceso del backend si fue iniciado por esta instancia de SGGI 2.0.
  void stopBackend() {
    final proc = _backendProcess;
    if (proc != null) {
      debugPrint('[BackendLauncher] Deteniendo proceso de backend (PID: ${proc.pid})...');
      proc.kill(ProcessSignal.sigterm);
      _backendProcess = null;
    }
  }
}
