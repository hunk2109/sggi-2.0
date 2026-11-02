import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';

class AccessDbTab extends ConsumerStatefulWidget {
  const AccessDbTab({super.key});

  @override
  ConsumerState<AccessDbTab> createState() => _AccessDbTabState();
}

class _AccessDbTabState extends ConsumerState<AccessDbTab> {
  final _accessDbPathCtrl = TextEditingController();
  final _machineIpCtrl = TextEditingController();
  final _machinePortCtrl = TextEditingController(text: '4370');
  bool _isLoadingAccessPath = false;
  bool _isSavingAccessPath = false;
  bool _isTestingAccessConn = false;
  bool _isUpdatingMachineIp = false;
  bool _isTestingMachineConn = false;
  bool _isMigratingToDatabase = false;
  Map<String, dynamic>? _accessTestResult;
  Map<String, dynamic>? _machineTestResult;
  Map<String, dynamic>? _migrationResult;

  @override
  void initState() {
    super.initState();
    _loadAccessDbPath();
  }

  @override
  void dispose() {
    _accessDbPathCtrl.dispose();
    _machineIpCtrl.dispose();
    _machinePortCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAccessDbPath() async {
    setState(() => _isLoadingAccessPath = true);
    final service = ref.read(settingsServiceProvider);
    final path = await service.getAccessDbPath();
    if (mounted) {
      if (path != null && path.isNotEmpty && !path.startsWith('/api/')) {
        _accessDbPathCtrl.text = path;
      }
      setState(() => _isLoadingAccessPath = false);
    }
  }

  Future<void> _pickAccessDbFile() async {
    String? selectedPath;
    try {
      final files = await FilePicker.pickFiles(
        dialogTitle: 'Seleccionar Base de Datos Access (.mdb / .accdb)',
        type: FileType.custom,
        allowedExtensions: ['mdb', 'accdb'],
      );
      if (files.isNotEmpty && files.first.path != null) {
        selectedPath = files.first.path;
      }
    } catch (_) {
      // Fallback nativo de Windows vía PowerShell si FilePicker no abre
      if (Platform.isWindows) {
        try {
          final res = await Process.run('powershell', [
            '-NoProfile',
            '-Command',
            r'''
Add-Type -AssemblyName System.Windows.Forms
$f = New-Object System.Windows.Forms.OpenFileDialog
$f.Filter = "Base de datos Access (*.mdb;*.accdb)|*.mdb;*.accdb|Todos los archivos (*.*)|*.*"
$f.Title = "Seleccionar Base de Datos Access (ZKAccess)"
if ($f.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
  Write-Host $f.FileName
}
''',
          ]);
          final out = res.stdout.toString().trim();
          if (out.isNotEmpty && (out.toLowerCase().endsWith('.mdb') || out.toLowerCase().endsWith('.accdb'))) {
            selectedPath = out;
          }
        } catch (_) {}
      }
    }

    if (selectedPath != null && selectedPath.isNotEmpty && mounted) {
      setState(() {
        _accessDbPathCtrl.text = selectedPath!;
      });
      await _saveAccessDbPath();
    }
  }

  Future<void> _saveAccessDbPath() async {
    final path = _accessDbPathCtrl.text.trim();
    if (path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa la ruta del archivo .mdb'), backgroundColor: AppTheme.warning),
      );
      return;
    }
    setState(() => _isSavingAccessPath = true);
    final service = ref.read(settingsServiceProvider);
    final success = await service.setAccessDbPath(path);
    if (!mounted) return;
    setState(() => _isSavingAccessPath = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ruta de Access guardada correctamente'), backgroundColor: AppTheme.success),
      );
      _testAccessConnection();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar la ruta de Access'), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _testAccessConnection() async {
    setState(() {
      _isTestingAccessConn = true;
      _accessTestResult = null;
    });
    final service = ref.read(settingsServiceProvider);
    final res = await service.testAccessConnection();
    if (!mounted) return;
    setState(() {
      _isTestingAccessConn = false;
      _accessTestResult = res;
      if (res['machines'] is List && (res['machines'] as List).isNotEmpty) {
        final m = res['machines'][0];
        if (m['ip'] != null && _machineIpCtrl.text.isEmpty) {
          _machineIpCtrl.text = m['ip'].toString();
        }
        if (m['port'] != null && _machinePortCtrl.text.isEmpty) {
          _machinePortCtrl.text = m['port'].toString();
        }
      }
    });
  }

  Future<void> _startDatabaseMigration() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E232B),
        title: const Row(
          children: [
            Icon(Icons.cloud_sync, color: AppTheme.primary),
            SizedBox(width: 10),
            Text('Confirmar Migración'),
          ],
        ),
        content: const Text(
          'Esta acción importará todos los socios (USERINFO), membresías activas, historial de asistencias y productos desde el archivo Access hacia la base de datos MySQL del SGGI.\n\n¿Deseas iniciar la migración ahora?',
          style: TextStyle(fontSize: 13, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Iniciar Migración'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isMigratingToDatabase = true;
      _migrationResult = null;
    });

    final service = ref.read(settingsServiceProvider);
    final res = await service.performMigrationToDatabase();

    if (!mounted) return;
    setState(() {
      _isMigratingToDatabase = false;
      _migrationResult = res;
    });

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Migración completada exitosamente!'),
          backgroundColor: AppTheme.success,
        ),
      );
      _testAccessConnection();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['error'] ?? 'Error durante la migración'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _saveAndTestMachineIp() async {
    final ip = _machineIpCtrl.text.trim();
    final portStr = _machinePortCtrl.text.trim();
    final port = int.tryParse(portStr) ?? 4370;

    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa la IP del equipo biométrico'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    setState(() {
      _isUpdatingMachineIp = true;
      _machineTestResult = null;
    });

    final service = ref.read(settingsServiceProvider);
    final res = await service.updateMachineIp(ip: ip, port: port);

    if (!mounted) return;
    setState(() {
      _isUpdatingMachineIp = false;
      _machineTestResult = res;
    });

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'IP guardada'),
          backgroundColor: res['reachable'] == true ? AppTheme.success : AppTheme.warning,
        ),
      );
      _testAccessConnection();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['error'] ?? 'Error al actualizar IP'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _testOnlyMachineIp() async {
    final ip = _machineIpCtrl.text.trim();
    final port = int.tryParse(_machinePortCtrl.text.trim()) ?? 4370;

    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa la IP a probar'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    setState(() {
      _isTestingMachineConn = true;
      _machineTestResult = null;
    });

    final service = ref.read(settingsServiceProvider);
    final res = await service.testMachineConnection(ip: ip, port: port);

    if (!mounted) return;
    setState(() {
      _isTestingMachineConn = false;
      _machineTestResult = res;
    });
  }

  Widget _buildAccessStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 11, color: Colors.white70)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isZktecoEnabled = ref.watch(zktecoSyncProvider);
    final test = _accessTestResult;
    final isSuccess = test?['success'] == true;
    final machines = (test?['machines'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final summary = test?['summary'] as Map<String, dynamic>?;

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.darkBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.fingerprint, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Base de Datos Access (ZKAccess / ZKTeco)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Configura la ruta del archivo .mdb para la sincronización de miembros y torniquetes',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),

            // Interruptor Maestro de ZKTeco
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isZktecoEnabled
                    ? Colors.green.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isZktecoEnabled
                      ? Colors.greenAccent.withValues(alpha: 0.3)
                      : Colors.white12,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isZktecoEnabled ? Icons.fingerprint : Icons.fingerprint_outlined,
                    size: 32,
                    color: isZktecoEnabled ? Colors.greenAccent : Colors.white38,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isZktecoEnabled
                              ? 'Sincronización ZKTeco / Access: HABILITADA'
                              : 'Sincronización ZKTeco / Access: DESACTIVADA (Modo Manual / QR)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isZktecoEnabled ? Colors.greenAccent : Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isZktecoEnabled
                              ? 'El sistema conecta con la base de datos .mdb y los torniquetes o relojes biométricos ZKTeco en red.'
                              : 'Desactiva la integración si este cliente o gimnasio no utiliza biométricos ni torniquetes. El sistema operará 100% independiente con código de barras, carnet QR o búsqueda manual.',
                          style: const TextStyle(fontSize: 12, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isZktecoEnabled,
                    activeThumbColor: Colors.greenAccent,
                    onChanged: (val) async {
                      final ok = await ref.read(zktecoSyncProvider.notifier).setEnabled(val);
                      if (context.mounted && ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              val
                                  ? 'Sincronización con ZKTeco activada'
                                  : 'Sincronización con ZKTeco desactivada (modo manual / QR)',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: val ? Colors.green.shade800 : Colors.grey.shade800,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (!isZktecoEnabled) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 28),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gimnasio configurado en Modo Autónomo / Control Manual',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'No se requieren configuraciones de red, archivos Access (.mdb) ni equipos físicos. Todos los registros de asistencia se gestionan a través de la pantalla de Control de Acceso con lector de código de barras, cámara QR o búsqueda manual de socios.',
                            style: TextStyle(fontSize: 12, color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Ruta de la BD
              const Text(
                'Ruta del Archivo Access (.mdb) *',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              const Text(
                'Especifica la ruta completa al archivo de base de datos de ZKAccess en el servidor o PC.',
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _accessDbPathCtrl,
                      readOnly: true,
                      onTap: _pickAccessDbFile,
                      decoration: InputDecoration(
                        hintText: r'Presiona aquí para seleccionar el archivo .mdb de ZKAccess...',
                        prefixIcon: const Icon(Icons.storage_outlined, size: 18),
                        suffixIcon: _isLoadingAccessPath
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            : IconButton(
                                icon: const Icon(Icons.folder_open, color: AppTheme.primary, size: 20),
                                tooltip: 'Seleccionar archivo Access (.mdb)',
                                onPressed: _pickAccessDbFile,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.folder_open, size: 18),
                    label: const Text('Examinar...'),
                    onPressed: _pickAccessDbFile,
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    icon: _isSavingAccessPath
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Guardar Ruta'),
                    onPressed: _isSavingAccessPath ? null : _saveAccessDbPath,
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    icon: _isTestingAccessConn
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.refresh, size: 18),
                    label: const Text('Probar Conexión'),
                    onPressed: _isTestingAccessConn ? null : _testAccessConnection,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Resultado de prueba de conexión
              if (_isTestingAccessConn)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Consultando base de datos Access y detectando equipos biométricos...', style: TextStyle(color: Colors.white60)),
                      ],
                    ),
                  ),
                )
              else if (test != null) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSuccess ? Colors.green.withValues(alpha: 0.08) : Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSuccess ? Colors.green.withValues(alpha: 0.25) : Colors.red.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isSuccess ? Icons.check_circle : Icons.error_outline,
                            color: isSuccess ? Colors.greenAccent : Colors.redAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isSuccess ? 'Base de Datos Conectada Correctamente' : 'Error al Conectar con la Base de Datos',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSuccess ? Colors.greenAccent : Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Ruta leída: ${test['dbPath'] ?? _accessDbPathCtrl.text}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      if (summary != null) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _buildAccessStatChip('Socios en Access', '${summary['users'] ?? 0}', Colors.blueAccent),
                            _buildAccessStatChip('Accesos Activos', '${summary['activeAccess'] ?? 0}', Colors.greenAccent),
                            _buildAccessStatChip('Registros de Asistencia', '${summary['logs'] ?? 0}', Colors.purpleAccent),
                          ],
                        ),
                      ],
                      if (machines.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Text('Equipos Biométricos Detectados:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        ...machines.map((m) => Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E232B),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.router_outlined, size: 16, color: AppTheme.primary),
                                  const SizedBox(width: 8),
                                  Text('${m['alias'] ?? 'Equipo ZK'} (IP: ${m['ip']}:${m['port']})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (m['enabled'] == true) ? Colors.green.withValues(alpha: 0.15) : Colors.white10,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      (m['enabled'] == true) ? 'Habilitado' : 'Deshabilitado',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: (m['enabled'] == true) ? Colors.greenAccent : Colors.white54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                      if (!isSuccess && test['error'] != null) ...[
                        const SizedBox(height: 8),
                        Text('Detalle del error: ${test['error']}', style: const TextStyle(fontSize: 11, color: Colors.redAccent)),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ================= 1. CONFIGURACIÓN IP DEL EQUIPO =================
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2028),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.router_outlined, color: AppTheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Configuración de IP del Equipo (Torniquete / Reloj)',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text(
                                'Especifica o modifica la dirección IP y puerto de red del equipo biométrico ZKTeco para comunicación TCP directa.',
                                style: TextStyle(fontSize: 11, color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 250,
                          child: TextField(
                            controller: _machineIpCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Dirección IP del Equipo *',
                              hintText: 'Ej. 192.168.1.201',
                              prefixIcon: Icon(Icons.settings_ethernet, size: 18),
                              isDense: true,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 130,
                          child: TextField(
                            controller: _machinePortCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Puerto TCP',
                              hintText: '4370',
                              prefixIcon: Icon(Icons.numbers, size: 18),
                              isDense: true,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          icon: _isUpdatingMachineIp
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.save_outlined, size: 18),
                          label: const Text('Guardar y Probar IP'),
                          onPressed: _isUpdatingMachineIp ? null : _saveAndTestMachineIp,
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          icon: _isTestingMachineConn
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.network_check_outlined, size: 18),
                          label: const Text('Probar Conexión'),
                          onPressed: _isTestingMachineConn ? null : _testOnlyMachineIp,
                        ),
                      ],
                    ),
                    if (_machineTestResult != null) ...[
                      const SizedBox(height: 14),
                      Builder(builder: (context) {
                        final isReachable = _machineTestResult!['reachable'] == true || _machineTestResult!['success'] == true;
                        final latency = _machineTestResult!['latencyMs'];
                        final message = _machineTestResult!['message'] ?? (isReachable ? 'Equipo respondiendo' : 'No responde');
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isReachable ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isReachable ? Colors.greenAccent.withValues(alpha: 0.3) : Colors.redAccent.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isReachable ? Icons.check_circle : Icons.error_outline,
                                color: isReachable ? Colors.greenAccent : Colors.redAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '$message${latency != null ? " (Latencia: ${latency}ms)" : ""}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isReachable ? Colors.greenAccent : Colors.redAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ================= 2. MIGRACIÓN A LA BASE DE DATOS =================
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2028),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amberAccent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.cloud_sync_outlined, color: Colors.amberAccent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Migración de Datos a MySQL',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text(
                                'Importa masivamente socios (USERINFO), membresías activas, historial de asistencias y catálogo de productos hacia la base de datos central.',
                                style: TextStyle(fontSize: 11, color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          ),
                          icon: _isMigratingToDatabase
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.play_arrow, size: 20),
                          label: Text(
                            _isMigratingToDatabase ? 'Migrando Base de Datos...' : 'Iniciar Migración a la Base de Datos',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: _isMigratingToDatabase ? null : _startDatabaseMigration,
                        ),
                      ],
                    ),
                    if (_migrationResult != null) ...[
                      const SizedBox(height: 16),
                      Builder(builder: (context) {
                        final success = _migrationResult!['success'] == true;
                        final data = _migrationResult!['data'] is Map ? _migrationResult!['data'] as Map : null;
                        final members = data?['members'];
                        final memberships = data?['memberships'];
                        final attendances = data?['attendances'];
                        final products = data?['products'];

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: success ? Colors.green.withValues(alpha: 0.08) : Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: success ? Colors.greenAccent.withValues(alpha: 0.3) : Colors.redAccent.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    success ? Icons.check_circle : Icons.error_outline,
                                    color: success ? Colors.greenAccent : Colors.redAccent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    success ? '¡Migración Completada con Éxito!' : 'Error durante la Migración',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: success ? Colors.greenAccent : Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                              if (success && data != null) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    if (members != null)
                                      _buildAccessStatChip('Socios', 'Insertados: ${members['inserted'] ?? 0}, Actualizados: ${members['updated'] ?? 0}', Colors.blueAccent),
                                    if (memberships != null)
                                      _buildAccessStatChip('Membresías', 'Creadas: ${memberships['inserted'] ?? 0}', Colors.greenAccent),
                                    if (attendances != null)
                                      _buildAccessStatChip('Asistencias', '${attendances['inserted'] ?? 0} registros', Colors.purpleAccent),
                                    if (products != null)
                                      _buildAccessStatChip('Productos', '${products['inserted'] ?? 0}', Colors.orangeAccent),
                                  ],
                                ),
                              ] else if (!success && _migrationResult!['error'] != null) ...[
                                const SizedBox(height: 8),
                                Text('Detalle del error: ${_migrationResult!['error']}', style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

