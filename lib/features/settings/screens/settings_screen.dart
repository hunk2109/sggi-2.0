import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../memberships/models/promotion_model.dart';
import '../../memberships/services/promotion_service.dart';
import '../models/gym_settings_model.dart';
import '../providers/settings_provider.dart';
import '../widgets/create_promotion_dialog.dart';
import '../widgets/roles_permissions_tab.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Gym settings controllers
  final _gymNameCtrl = TextEditingController();
  final _rncCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _openingTimeCtrl = TextEditingController();
  final _closingTimeCtrl = TextEditingController();
  final _suspensionDaysCtrl = TextEditingController();
  final _time1Ctrl = TextEditingController();
  final _time2Ctrl = TextEditingController();
  final _recipientsCtrl = TextEditingController();
  String _notificationChannel = 'both';
  String _ticketPaperSize = '80mm';

  // WhatsApp test controllers
  final _testPhoneCtrl = TextEditingController();
  final _testMessageCtrl = TextEditingController(text: '¡Hola! Este es un mensaje de prueba desde SGGI 2.0.');

  // Access MDB settings
  final _accessDbPathCtrl = TextEditingController();
  bool _isLoadingAccessPath = false;
  bool _isSavingAccessPath = false;
  bool _isTestingAccessConn = false;
  Map<String, dynamic>? _accessTestResult;

  // Cupones y promociones
  final _couponSearchCtrl = TextEditingController();

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadAccessDbPath();
  }

  Future<void> _loadAccessDbPath() async {
    setState(() => _isLoadingAccessPath = true);
    final service = ref.read(settingsServiceProvider);
    final path = await service.getAccessDbPath();
    if (mounted) {
      if (path != null && path.isNotEmpty) {
        _accessDbPathCtrl.text = path;
      }
      setState(() => _isLoadingAccessPath = false);
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
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _gymNameCtrl.dispose();
    _rncCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _websiteCtrl.dispose();
    _openingTimeCtrl.dispose();
    _closingTimeCtrl.dispose();
    _suspensionDaysCtrl.dispose();
    _time1Ctrl.dispose();
    _time2Ctrl.dispose();
    _recipientsCtrl.dispose();
    _testPhoneCtrl.dispose();
    _testMessageCtrl.dispose();
    _accessDbPathCtrl.dispose();
    _couponSearchCtrl.dispose();
    super.dispose();
  }

  void _populateFields(GymSettingsModel settings) {
    if (_isInitialized) return;
    _gymNameCtrl.text = settings.gymName;
    _rncCtrl.text = settings.rnc ?? '';
    _phoneCtrl.text = settings.phone ?? '';
    _emailCtrl.text = settings.email ?? '';
    _addressCtrl.text = settings.address ?? '';
    _websiteCtrl.text = settings.website ?? '';
    _openingTimeCtrl.text = settings.openingTime ?? '06:00';
    _closingTimeCtrl.text = settings.closingTime ?? '22:00';
    _suspensionDaysCtrl.text = settings.membershipSuspensionDays.toString();
    _time1Ctrl.text = settings.closingReportTime1 ?? '12:00';
    _time2Ctrl.text = settings.closingReportTime2 ?? '21:00';
    _recipientsCtrl.text = settings.closingReportRecipients ?? '';
    _notificationChannel = settings.notificationChannel ?? 'both';
    _ticketPaperSize = settings.ticketPaperSize.isNotEmpty ? settings.ticketPaperSize : '80mm';
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final gymState = ref.watch(gymSettingsProvider);
    final wpState = ref.watch(whatsappProvider);

    if (gymState.settings != null) {
      _populateFields(gymState.settings!);
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuración del Sistema',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gestión de mensajería WhatsApp, parámetros generales y reportes automáticos',
                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Actualizar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkCard,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.darkBorder),
                  ),
                  onPressed: () {
                    ref.read(gymSettingsProvider.notifier).loadSettings();
                    ref.read(whatsappProvider.notifier).checkStatus();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.darkBorder),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primary,
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                tabs: const [
                  Tab(icon: Icon(Icons.chat_bubble_outline, size: 18), text: 'WhatsApp & Mensajería'),
                  Tab(icon: Icon(Icons.discount_outlined, size: 18), text: 'Cupones & Promociones'),
                  Tab(icon: Icon(Icons.fitness_center_outlined, size: 18), text: 'Datos del Gimnasio & Empresa'),
                  Tab(icon: Icon(Icons.notifications_active_outlined, size: 18), text: 'Reportes & Automatización'),
                  Tab(icon: Icon(Icons.fingerprint, size: 18), text: 'Biométrico & BD Access'),
                  Tab(icon: Icon(Icons.security_outlined, size: 18), text: 'Roles & Permisos'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildWhatsappTab(wpState),
                  _buildCouponsTab(),
                  _buildGymSettingsTab(gymState),
                  _buildAutomationTab(gymState),
                  _buildAccessDbTab(),
                  const RolesPermissionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =================== TAB 1: WHATSAPP ===================
  Widget _buildWhatsappTab(WhatsappState wpState) {
    final status = wpState.status;
    final isConnected = status?.isConnected ?? false;
    final isQrReady = status?.isQrReady ?? false;

    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Card: Connection Status & QR Code
          Expanded(
            flex: 5,
            child: Card(
              color: AppTheme.darkCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.darkBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Status Header Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Estado de Conexión',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isConnected
                                ? AppTheme.success.withValues(alpha: 0.15)
                                : isQrReady
                                    ? Colors.orange.withValues(alpha: 0.15)
                                    : Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isConnected
                                  ? AppTheme.success
                                  : isQrReady
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isConnected
                                      ? AppTheme.success
                                      : isQrReady
                                          ? Colors.orange
                                          : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                status?.label ?? 'Cargando...',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isConnected
                                      ? AppTheme.success
                                      : isQrReady
                                          ? Colors.orange
                                          : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32, color: AppTheme.darkBorder),

                    // QR / Connected View
                    if (wpState.isLoading && status == null)
                      const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(),
                      )
                    else if (isConnected) ...[
                      const Icon(Icons.check_circle_outline, size: 72, color: AppTheme.success),
                      const SizedBox(height: 16),
                      const Text(
                        'WhatsApp Vinculado y Activo',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'El sistema puede enviar facturas en PDF, recibos de caja, alertas de vencimiento y confirmaciones de membresía directamente a los socios.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.logout, size: 16, color: Colors.redAccent),
                            label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('¿Cerrar sesión de WhatsApp?'),
                                  content: const Text('Se desvinculará el número actual y será necesario escanear un nuevo código QR.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                    ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Desvincular')),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                ref.read(whatsappProvider.notifier).logout();
                              }
                            },
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.restart_alt, size: 16),
                            label: const Text('Reiniciar Servicio'),
                            onPressed: () => ref.read(whatsappProvider.notifier).restart(),
                          ),
                        ],
                      ),
                    ] else if (isQrReady) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: status!.qr!,
                          version: QrVersions.auto,
                          size: 240,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Escanea este código con tu teléfono',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.darkSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.darkBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInstructionStep('1', 'Abre WhatsApp en el teléfono del gimnasio.'),
                            _buildInstructionStep('2', 'Toca Ajustes o Configuración > Dispositivos vinculados.'),
                            _buildInstructionStep('3', 'Toca "Vincular un dispositivo" y apunta con la cámara.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Regenerar Código QR'),
                        onPressed: () => ref.read(whatsappProvider.notifier).restart(),
                      ),
                    ] else ...[
                      const Icon(Icons.signal_wifi_off, size: 64, color: Colors.white30),
                      const SizedBox(height: 16),
                      Text(
                        status?.label ?? 'Iniciando cliente de WhatsApp...',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Si tarda en responder, puedes forzar un reinicio del proceso.',
                        style: TextStyle(fontSize: 12, color: Colors.white54),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('Iniciar / Reiniciar Cliente'),
                        onPressed: () => ref.read(whatsappProvider.notifier).restart(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Right Card: Test Message & Information
          Expanded(
            flex: 4,
            child: Card(
              color: AppTheme.darkCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.darkBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prueba de Envío Directo',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Envía un mensaje de comprobación para verificar que el bot responde correctamente.',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
                    ),
                    const Divider(height: 24, color: AppTheme.darkBorder),

                    const Text('Número de Destino (con o sin prefijo RD)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _testPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: 'Ej: 8091234567 o 8295551234',
                        prefixIcon: Icon(Icons.phone, size: 18),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('Mensaje de Prueba', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _testMessageCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Escribe tu mensaje...',
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: wpState.isSendingTest
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send, size: 16),
                        label: const Text('Enviar Mensaje de Prueba'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isConnected ? AppTheme.primary : Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: (!isConnected || wpState.isSendingTest)
                            ? null
                            : () async {
                                final phone = _testPhoneCtrl.text.trim();
                                final msg = _testMessageCtrl.text.trim();
                                if (phone.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Ingresa un número de teléfono válido'), backgroundColor: AppTheme.warning),
                                  );
                                  return;
                                }
                                final res = await ref.read(whatsappProvider.notifier).sendTestMessage(phone, msg);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res.message),
                                    backgroundColor: res.success ? AppTheme.success : AppTheme.error,
                                  ),
                                );
                              },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Information box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.darkBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, size: 18, color: AppTheme.accent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'El servicio corre localmente en el servidor backend mediante una instancia controlada de WhatsApp Web. No requiere pago de APIs externas.',
                              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: AppTheme.primary,
            child: Text(number, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  // =================== TAB 2: DATOS DEL GIMNASIO ===================
  Widget _buildGymSettingsTab(GymSettingsState state) {
    return SingleChildScrollView(
      child: Card(
        color: AppTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.darkBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Datos Comerciales y Fiscales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'Esta información se imprimirá en los tickets de venta y facturas de los socios.',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
              ),
              const Divider(height: 28, color: AppTheme.darkBorder),

              Row(
                children: [
                  Expanded(
                    child: _buildFormField('Nombre del Gimnasio *', _gymNameCtrl, 'Ej: SGGI Fitness Center'),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildFormField('RNC / Cédula Fiscal', _rncCtrl, 'Ej: 131-12345-6'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildFormField('Teléfono de Contacto', _phoneCtrl, 'Ej: 809-555-1234'),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildFormField('Correo Electrónico', _emailCtrl, 'Ej: contacto@gimnasio.com'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildFormField('Dirección Física', _addressCtrl, 'Ej: Av. Principal #45, Santo Domingo'),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildFormField('Sitio Web / Red Social', _websiteCtrl, 'Ej: www.instagram.com/gym'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text('Horarios y Reglas de Acceso', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Divider(height: 28, color: AppTheme.darkBorder),

              Row(
                children: [
                  Expanded(
                    child: _buildFormField('Hora de Apertura', _openingTimeCtrl, '06:00'),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildFormField('Hora de Cierre', _closingTimeCtrl, '22:00'),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildFormField(
                      'Días de Tolerancia / Gracia (Torniquetes)',
                      _suspensionDaysCtrl,
                      '15',
                      helperText: 'Días adicionales antes de bloquear al socio vencido en el biométrico',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Formato e Impresión de Tickets y Recibos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'Selecciona el formato y ancho de papel para los comprobantes de venta del POS y recibos de membresías.',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
              ),
              const Divider(height: 28, color: AppTheme.darkBorder),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tamaño de Papel Predeterminado', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _ticketPaperSize,
                          dropdownColor: AppTheme.darkCard,
                          decoration: InputDecoration(
                            fillColor: AppTheme.darkSurface,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.darkBorder)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.darkBorder)),
                          ),
                          items: const [
                            DropdownMenuItem(value: '80mm', child: Text('Papel Térmico 80 mm (Estándar POS)')),
                            DropdownMenuItem(value: '70mm', child: Text('Papel Térmico 70 mm / 72 mm (Compacto)')),
                            DropdownMenuItem(value: '58mm', child: Text('Papel Térmico 58 mm (Miniprinter / Portátil)')),
                            DropdownMenuItem(value: 'a4', child: Text('Hoja Estándar A4 (Factura formal de página completa)')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _ticketPaperSize = v);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(top: 22),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.darkBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _ticketPaperSize == 'a4' ? Icons.description_outlined : Icons.receipt_long_outlined,
                            color: Colors.blueAccent,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _ticketPaperSize == 'a4'
                                  ? 'Modo A4: Genera una factura formal en hoja completa con membrete, tabla de detalles y espacio para firmas.'
                                  : _ticketPaperSize == '70mm'
                                      ? 'Modo 70mm: Optimizado para rollos de 70-72mm con tipografía compacta, ideal para impresoras medianas.'
                                      : _ticketPaperSize == '58mm'
                                          ? 'Modo 58mm: Formato súper compacto para impresoras térmicas portátiles de 58mm (2 pulgadas).'
                                          : 'Modo 80mm: Formato estándar para impresoras térmicas de punto de venta (POS) de 3 pulgadas.',
                              style: const TextStyle(fontSize: 12, color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    icon: state.isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save, size: 18),
                    label: const Text('Guardar Cambios'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    onPressed: state.isSaving
                        ? null
                        : () async {
                            final model = (state.settings ?? GymSettingsModel()).copyWith(
                              gymName: _gymNameCtrl.text.trim(),
                              rnc: _rncCtrl.text.trim(),
                              phone: _phoneCtrl.text.trim(),
                              email: _emailCtrl.text.trim(),
                              address: _addressCtrl.text.trim(),
                              website: _websiteCtrl.text.trim(),
                              openingTime: _openingTimeCtrl.text.trim(),
                              closingTime: _closingTimeCtrl.text.trim(),
                              membershipSuspensionDays: int.tryParse(_suspensionDaysCtrl.text.trim()) ?? 15,
                              ticketPaperSize: _ticketPaperSize,
                            );

                            final ok = await ref.read(gymSettingsProvider.notifier).saveSettings(model);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok ? 'Configuración guardada exitosamente' : 'Error al guardar configuración'),
                                backgroundColor: ok ? AppTheme.success : AppTheme.error,
                              ),
                            );
                          },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =================== TAB 3: REPORTES & AUTOMATIZACIÓN ===================
  Widget _buildAutomationTab(GymSettingsState state) {
    return SingleChildScrollView(
      child: Card(
        color: AppTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.darkBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cortes de Caja y Reportes Automáticos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'El sistema genera resúmenes automáticos de ventas y asistencia en las horas fijadas.',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
              ),
              const Divider(height: 28, color: AppTheme.darkBorder),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Canal de Notificaciones Preferido', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _notificationChannel,
                          items: const [
                            DropdownMenuItem(value: 'whatsapp', child: Text('Solo WhatsApp')),
                            DropdownMenuItem(value: 'email', child: Text('Solo Correo Electrónico')),
                            DropdownMenuItem(value: 'both', child: Text('WhatsApp y Correo (Ambos)')),
                          ],
                          onChanged: (v) => setState(() => _notificationChannel = v ?? 'both'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildFormField('Hora de Corte 1 (Turno Mañana)', _time1Ctrl, '12:00'),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildFormField('Hora de Corte 2 (Turno Noche)', _time2Ctrl, '21:00'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildFormField(
                'Destinatarios de Reportes (Teléfonos o Correos separados por coma)',
                _recipientsCtrl,
                'Ej: 8095551234, admin@gym.com',
                helperText: 'A estos números/correos se enviarán las alertas automáticas de cierre de caja.',
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    icon: state.isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save, size: 18),
                    label: const Text('Guardar Parámetros de Reporte'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    onPressed: state.isSaving
                        ? null
                        : () async {
                            final model = (state.settings ?? GymSettingsModel()).copyWith(
                              notificationChannel: _notificationChannel,
                              closingReportTime1: _time1Ctrl.text.trim(),
                              closingReportTime2: _time2Ctrl.text.trim(),
                              closingReportRecipients: _recipientsCtrl.text.trim(),
                            );

                            final ok = await ref.read(gymSettingsProvider.notifier).saveSettings(model);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok ? 'Parámetros actualizados exitosamente' : 'Error al guardar parámetros'),
                                backgroundColor: ok ? AppTheme.success : AppTheme.error,
                              ),
                            );
                          },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, String hint, {String? helperText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            helperMaxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildAccessDbTab() {
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
                    decoration: InputDecoration(
                      hintText: r'C:\Users\...\Downloads\dowtown.mdb o C:\develop\gym-backend\dowtown.mdb',
                      prefixIcon: const Icon(Icons.storage_outlined, size: 18),
                      suffixIcon: _isLoadingAccessPath
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                                  child: Text((m['enabled'] == true) ? 'Habilitado' : 'Deshabilitado', style: TextStyle(fontSize: 10, color: (m['enabled'] == true) ? Colors.greenAccent : Colors.white54)),
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
          ],
        ),
      ),
    );
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

  // =================== TAB 2: CUPONES & PROMOCIONES ===================
  Widget _buildCouponsTab() {
    final promoState = ref.watch(promotionsProvider);
    final allCoupons = promoState.promotions;
    final query = _couponSearchCtrl.text.trim().toLowerCase();

    final filteredCoupons = allCoupons.where((c) {
      if (query.isEmpty) return true;
      final matchCode = c.code.toLowerCase().contains(query);
      final matchDesc = c.description?.toLowerCase().contains(query) ?? false;
      return matchCode || matchDesc;
    }).toList();

    final totalCount = allCoupons.length;
    final activeCount = allCoupons.where((c) => c.isValid).length;
    final totalUses = allCoupons.fold<int>(0, (acc, c) => acc + c.usesCount);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Superior
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.discount_outlined, color: Colors.amberAccent, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Gestión de Cupones y Promociones',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Crea códigos de descuento aplicables exclusivamente en el pago y renovación de membresías, o selecciónalos al redactar campañas masivas.',
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _buildCouponStatBadge('Total Cupones', '$totalCount', Colors.blueAccent),
                          _buildCouponStatBadge('Vigentes y Activos', '$activeCount', Colors.greenAccent),
                          _buildCouponStatBadge('Canjes Realizados', '$totalUses', Colors.amberAccent),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text(
                    'Crear Nuevo Cupón',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const CreatePromotionDialog(),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Barra de Búsqueda y Filtro
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponSearchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar por código de cupón o descripción...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _couponSearchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _couponSearchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppTheme.darkCard,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Refrescar cupones',
                icon: const Icon(Icons.refresh, color: Colors.white70),
                onPressed: () => ref.read(promotionsProvider.notifier).loadPromotions(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Estado de Carga o Lista de Cupones
          if (promoState.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (filteredCoupons.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.darkBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_offer_outlined, size: 54, color: Colors.white24),
                  const SizedBox(height: 14),
                  Text(
                    allCoupons.isEmpty
                        ? 'No hay cupones creados en el gimnasio'
                        : 'No se encontraron cupones con "$query"',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    allCoupons.isEmpty
                        ? 'Crea tu primer cupón para promocionar planes y fidelizar socios.'
                        : 'Intenta con otro término de búsqueda.',
                    style: const TextStyle(fontSize: 12, color: Colors.white38),
                  ),
                  if (allCoupons.isEmpty) ...[
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                      icon: const Icon(Icons.add, size: 16, color: Colors.white),
                      label: const Text('Crear Cupón Ahora', style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const CreatePromotionDialog(),
                        );
                      },
                    ),
                  ],
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                final crossAxisCount = isWide ? 3 : 2;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 200,
                  ),
                  itemCount: filteredCoupons.length,
                  itemBuilder: (context, index) {
                    final promo = filteredCoupons[index];
                    return _buildCouponCard(promo);
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCouponCard(PromotionModel promo) {
    final isExpired = promo.expiresAt != null && DateTime.now().isAfter(promo.expiresAt!);
    final isMaxReached = promo.maxUses != null && promo.usesCount >= promo.maxUses!;
    final isValid = promo.active && !isExpired && !isMaxReached;

    Color statusColor = Colors.greenAccent;
    String statusText = 'ACTIVO';
    if (!promo.active) {
      statusColor = Colors.redAccent;
      statusText = 'INACTIVO';
    } else if (isExpired) {
      statusColor = Colors.orangeAccent;
      statusText = 'EXPIRADO';
    } else if (isMaxReached) {
      statusColor = Colors.amberAccent;
      statusText = 'AGOTADO';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid ? Colors.amberAccent.withValues(alpha: 0.25) : AppTheme.darkBorder,
          width: isValid ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.confirmation_number, size: 14, color: Colors.amberAccent),
                        const SizedBox(width: 6),
                        Text(
                          promo.code,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 14, color: Colors.white38),
                    tooltip: 'Copiar código',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: promo.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Código "${promo.code}" copiado al portapapeles.'), duration: const Duration(seconds: 2)),
                      );
                    },
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
            ],
          ),

          Row(
            children: [
              Text(
                '${promo.discountPercentage}% OFF',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text(
                'en membresías',
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
            ],
          ),

          Text(
            promo.description?.isNotEmpty == true ? promo.description! : 'Sin descripción adicional.',
            style: const TextStyle(fontSize: 11, color: Colors.white60),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const Divider(height: 12, color: Colors.white12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usos: ${promo.usesCount} / ${promo.maxUses ?? '∞'}',
                    style: const TextStyle(fontSize: 10, color: Colors.white54),
                  ),
                  Text(
                    promo.expiresAt != null
                        ? 'Vence: ${DateFormat('dd/MM/yyyy').format(promo.expiresAt!)}'
                        : 'Sin vencimiento',
                    style: const TextStyle(fontSize: 10, color: Colors.white54),
                  ),
                ],
              ),
              Row(
                children: [
                  Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      value: promo.active,
                      activeThumbColor: Colors.greenAccent,
                      onChanged: (val) {
                        ref.read(promotionsProvider.notifier).toggleActive(promo.id);
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                    tooltip: 'Eliminar cupón',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF1E232B),
                          title: const Text('Eliminar Cupón', style: TextStyle(color: Colors.white)),
                          content: Text('¿Está seguro de eliminar el cupón "${promo.code}"?', style: const TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        ref.read(promotionsProvider.notifier).deletePromotion(promo.id);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCouponStatBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
}
