import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../models/gym_settings_model.dart';
import '../providers/settings_provider.dart';

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

  // WhatsApp test controllers
  final _testPhoneCtrl = TextEditingController();
  final _testMessageCtrl = TextEditingController(text: '¡Hola! Este es un mensaje de prueba desde SGGI 2.0.');

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
                  Tab(icon: Icon(Icons.fitness_center_outlined, size: 18), text: 'Datos del Gimnasio & Empresa'),
                  Tab(icon: Icon(Icons.notifications_active_outlined, size: 18), text: 'Reportes & Automatización'),
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
                  _buildGymSettingsTab(gymState),
                  _buildAutomationTab(gymState),
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
}
