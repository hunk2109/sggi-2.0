import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/backend_launcher_service.dart';
import '../network/backend_status_provider.dart';

class BackendStatusBadge extends ConsumerWidget {
  const BackendStatusBadge({super.key});

  void _showDiagnosticsDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, dialogRef, _) {
          final status = dialogRef.watch(backendStatusProvider);
          final launcher = BackendLauncherService.instance;
          final logs = launcher.recentLogs;
          final logText = logs.isNotEmpty
              ? logs.join('\n')
              : (status.diagnosticTooltip ?? 'Sin eventos registrados aún.');

          return AlertDialog(
            backgroundColor: const Color(0xFF111827),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
            title: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: status.isOnline
                        ? const Color(0xFF107C41)
                        : status.isChecking
                            ? Colors.amber
                            : Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Diagnóstico del Backend Local',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 680,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (status.errorMessage != null && status.isOffline) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
                      ),
                      child: SelectableText(
                        'Error de conexión: ${status.errorMessage}',
                        style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (launcher.logFilePath != null) ...[
                    SelectableText(
                      'Archivo de log: ${launcher.logFilePath}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Container(
                    height: 280,
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF090D16),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        logText,
                        style: const TextStyle(
                          fontFamily: 'Consolas',
                          fontSize: 11.5,
                          color: Color(0xFFD1D5DB),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: logText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Log copiado al portapapeles')),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copiar Log'),
              ),
              TextButton.icon(
                onPressed: () async {
                  await launcher.ensureBackendRunning();
                  await dialogRef.read(backendStatusProvider.notifier).checkHealth();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reintentar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backendStatus = ref.watch(backendStatusProvider);
    final tooltipText = backendStatus.diagnosticTooltip ??
        (backendStatus.isOnline
            ? 'Backend activo en localhost:3000'
            : backendStatus.isChecking
                ? 'Verificando conexión con el backend...'
                : 'Backend desconectado. Haz clic para ver el log.');

    return Tooltip(
      message: '$tooltipText\n\n(Haz clic para ver el log completo y reintentar)',
      waitDuration: const Duration(milliseconds: 150),
      showDuration: const Duration(seconds: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        height: 1.35,
      ),
      child: InkWell(
        onTap: () {
          ref.read(backendStatusProvider.notifier).checkHealth();
          _showDiagnosticsDialog(context, ref);
        },
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: backendStatus.isOnline
                      ? const Color(0xFF107C41)
                      : backendStatus.isChecking
                          ? Colors.amber
                          : Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                backendStatus.isOnline
                    ? 'Backend: localhost:3000 (Activo)'
                    : backendStatus.isChecking
                        ? 'Backend: Conectando...'
                        : 'Backend: Desconectado (ver error)',
                style: TextStyle(
                  color: backendStatus.isOnline
                      ? Colors.white70
                      : backendStatus.isChecking
                          ? Colors.amber.shade200
                          : Colors.red.shade300,
                  fontSize: 13,
                  fontWeight: backendStatus.isOnline ? FontWeight.normal : FontWeight.w600,
                ),
              ),
              if (backendStatus.isOffline) ...[
                const SizedBox(width: 6),
                Icon(Icons.info_outline, size: 14, color: Colors.red.shade300),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
