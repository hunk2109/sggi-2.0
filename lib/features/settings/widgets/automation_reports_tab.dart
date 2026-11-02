import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/gym_settings_model.dart';
import '../providers/settings_provider.dart';
import 'select_report_recipients_dialog.dart';

class AutomationReportsTab extends ConsumerStatefulWidget {
  const AutomationReportsTab({super.key});

  @override
  ConsumerState<AutomationReportsTab> createState() => _AutomationReportsTabState();
}

class _AutomationReportsTabState extends ConsumerState<AutomationReportsTab> {
  final _time1Ctrl = TextEditingController();
  final _time2Ctrl = TextEditingController();
  final _recipientsCtrl = TextEditingController();
  String _notificationChannel = 'both';
  bool _isSendingManualReport = false;
  bool _enableDailySummaryReport = true;
  bool _enablePaymentReminders = true;
  bool _enableExpirationWarnings = true;
  bool _enableBirthdayEmails = true;
  bool _enableMembershipRenewal = true;
  bool _isInitialized = false;

  @override
  void dispose() {
    _time1Ctrl.dispose();
    _time2Ctrl.dispose();
    _recipientsCtrl.dispose();
    super.dispose();
  }

  void _populateFields(GymSettingsModel settings) {
    if (_isInitialized) return;
    _time1Ctrl.text = settings.closingReportTime1 ?? '12:00';
    _time2Ctrl.text = settings.closingReportTime2 ?? '21:00';
    _recipientsCtrl.text = settings.closingReportRecipients ?? '';
    _notificationChannel = settings.notificationChannel ?? 'both';
    _enableDailySummaryReport = settings.enableDailySummaryReport;
    _enablePaymentReminders = settings.enablePaymentReminders;
    _enableExpirationWarnings = settings.enableExpirationWarnings;
    _enableBirthdayEmails = settings.enableBirthdayEmails;
    _enableMembershipRenewal = settings.enableMembershipRenewal;
    _isInitialized = true;
  }

  Widget _buildTimePickerField(String label, TextEditingController controller, String defaultTime) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            TimeOfDay initial = const TimeOfDay(hour: 12, minute: 0);
            final text = controller.text.trim();
            if (text.contains(':')) {
              final parts = text.split(':');
              final h = int.tryParse(parts[0]);
              final m = int.tryParse(parts[1]);
              if (h != null && m != null) {
                initial = TimeOfDay(hour: h, minute: m);
              }
            }
            final picked = await showTimePicker(
              context: context,
              initialTime: initial,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppTheme.primary,
                      surface: AppTheme.darkCard,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
              setState(() => controller.text = formatted);
            }
          },
          child: IgnorePointer(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: defaultTime,
                suffixIcon: const Icon(Icons.access_time, size: 20, color: AppTheme.primary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
    Color activeColor = Colors.greenAccent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161A22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: value ? activeColor.withValues(alpha: 0.3) : AppTheme.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: value ? activeColor.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: value ? activeColor : Colors.white54),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: activeColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Future<void> _openEmployeeSelectorDialog() async {
    final result = await SelectReportRecipientsDialog.show(
      context,
      currentRecipients: _recipientsCtrl.text.trim(),
      notificationChannel: _notificationChannel,
    );

    if (result != null && mounted) {
      setState(() {
        _recipientsCtrl.text = result;
      });
    }
  }

  Widget _buildRecipientsSection() {
    final rawTokens = _recipientsCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Destinatarios de Reportes (Teléfonos o Correos separados por coma)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.groups_outlined, size: 16),
              label: const Text('Extraer de Empleados'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                foregroundColor: AppTheme.primaryLight,
                side: const BorderSide(color: AppTheme.primary),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: _openEmployeeSelectorDialog,
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _recipientsCtrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Ej: 8095551234, admin@gym.com',
            helperText: 'A estos números/correos se enviarán las alertas automáticas de cierre de caja.',
            helperMaxLines: 2,
            suffixIcon: IconButton(
              icon: const Icon(Icons.person_add_alt_1_outlined, color: AppTheme.primaryLight, size: 20),
              tooltip: 'Seleccionar de empleados',
              onPressed: _openEmployeeSelectorDialog,
            ),
          ),
        ),
        if (rawTokens.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...rawTokens.map((token) {
                final isEmail = token.contains('@');
                return Chip(
                  avatar: CircleAvatar(
                    radius: 10,
                    backgroundColor: isEmail ? Colors.blueAccent.withValues(alpha: 0.2) : Colors.greenAccent.withValues(alpha: 0.2),
                    child: Icon(
                      isEmail ? Icons.mail_outline : Icons.chat_bubble_outline,
                      size: 11,
                      color: isEmail ? Colors.blueAccent : Colors.greenAccent,
                    ),
                  ),
                  label: Text(
                    token,
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF1E232B),
                  side: BorderSide(color: isEmail ? Colors.blueAccent.withValues(alpha: 0.3) : Colors.greenAccent.withValues(alpha: 0.3)),
                  deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white54),
                  onDeleted: () {
                    final updated = rawTokens.where((t) => t != token).join(', ');
                    setState(() {
                      _recipientsCtrl.text = updated;
                    });
                  },
                );
              }),
              ActionChip(
                avatar: const Icon(Icons.add, size: 14, color: AppTheme.primaryLight),
                label: const Text('Agregar Empleado', style: TextStyle(fontSize: 11, color: AppTheme.primaryLight)),
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                side: const BorderSide(color: AppTheme.primary),
                onPressed: _openEmployeeSelectorDialog,
              ),
            ],
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gymSettingsProvider);
    if (state.settings != null) {
      _populateFields(state.settings!);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta 1: Cortes de Caja y Reportes Automáticos
          Card(
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

                  _buildNotificationSwitch(
                    title: 'Activar Envíos Automáticos de Cortes de Caja',
                    subtitle: 'Genera y envía automáticamente los cierres a los destinatarios en las horas fijadas (Mañana y Noche).',
                    value: _enableDailySummaryReport,
                    icon: Icons.receipt_long_rounded,
                    activeColor: Colors.greenAccent,
                    onChanged: (val) => setState(() => _enableDailySummaryReport = val),
                  ),
                  const SizedBox(height: 20),

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
                        child: _buildTimePickerField('Hora de Corte 1 (Turno Mañana)', _time1Ctrl, '12:00'),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildTimePickerField('Hora de Corte 2 (Turno Noche)', _time2Ctrl, '21:00'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildRecipientsSection(),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: _isSendingManualReport
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                            : const Icon(Icons.send_rounded, size: 18, color: AppTheme.primary),
                        label: Text(
                          _isSendingManualReport ? 'Generando y Enviando...' : 'Enviar Reporte Ahora',
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primary),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                        ),
                        onPressed: _isSendingManualReport
                            ? null
                            : () async {
                                final recipients = _recipientsCtrl.text.trim();
                                if (recipients.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Agrega al menos un teléfono o correo en los destinatarios.'),
                                      backgroundColor: AppTheme.warning,
                                    ),
                                  );
                                  return;
                                }

                                setState(() => _isSendingManualReport = true);
                                try {
                                  final service = ref.read(settingsServiceProvider);
                                  final res = await service.sendDailySummaryReport();
                                  if (!mounted || !context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(res.message),
                                      backgroundColor: res.success ? AppTheme.success : AppTheme.error,
                                    ),
                                  );
                                } finally {
                                  if (mounted) setState(() => _isSendingManualReport = false);
                                }
                              },
                      ),
                      const SizedBox(width: 14),
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
                                  enableDailySummaryReport: _enableDailySummaryReport,
                                  enablePaymentReminders: _enablePaymentReminders,
                                  enableExpirationWarnings: _enableExpirationWarnings,
                                  enableBirthdayEmails: _enableBirthdayEmails,
                                  enableMembershipRenewal: _enableMembershipRenewal,
                                );

                                final ok = await ref.read(gymSettingsProvider.notifier).saveSettings(model);
                                if (!mounted || !context.mounted) return;
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

          const SizedBox(height: 20),

          // Tarjeta 2: Notificaciones y Mensajes Automáticos a Clientes
          Card(
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
                  const Text('Control de Notificaciones y Mensajes Automáticos del Sistema', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'Activa o desactiva qué tipos de mensajes automáticos envía el sistema por WhatsApp y Correo a los socios.',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
                  ),
                  const Divider(height: 28, color: AppTheme.darkBorder),

                  _buildNotificationSwitch(
                    title: 'Recordatorios de Pago y Cobro Automático',
                    subtitle: 'Envía alertas preventivas y avisos de cobro a socios con cuotas por vencer o pendientes.',
                    value: _enablePaymentReminders,
                    icon: Icons.payments_outlined,
                    activeColor: Colors.blueAccent,
                    onChanged: (val) => setState(() => _enablePaymentReminders = val),
                  ),
                  const SizedBox(height: 12),

                  _buildNotificationSwitch(
                    title: 'Alertas de Membresías por Vencer',
                    subtitle: 'Notifica con anticipación a los socios cuando su plan esté próximo a expirar.',
                    value: _enableExpirationWarnings,
                    icon: Icons.notifications_active_outlined,
                    activeColor: Colors.orangeAccent,
                    onChanged: (val) => setState(() => _enableExpirationWarnings = val),
                  ),
                  const SizedBox(height: 12),

                  _buildNotificationSwitch(
                    title: 'Felicitaciones de Cumpleaños a Socios',
                    subtitle: 'Envía mensajes y felicitaciones automáticas a los socios registrados el día de su cumpleaños.',
                    value: _enableBirthdayEmails,
                    icon: Icons.cake_outlined,
                    activeColor: Colors.purpleAccent,
                    onChanged: (val) => setState(() => _enableBirthdayEmails = val),
                  ),
                  const SizedBox(height: 12),

                  _buildNotificationSwitch(
                    title: 'Avisos de Renovación de Membresía',
                    subtitle: 'Envía confirmación y recibo digital cada vez que se renueva o adquiere una membresía.',
                    value: _enableMembershipRenewal,
                    icon: Icons.autorenew_rounded,
                    activeColor: Colors.tealAccent,
                    onChanged: (val) => setState(() => _enableMembershipRenewal = val),
                  ),
                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        icon: state.isSaving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save, size: 18),
                        label: const Text('Guardar Configuración de Mensajes'),
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
                                  enableDailySummaryReport: _enableDailySummaryReport,
                                  enablePaymentReminders: _enablePaymentReminders,
                                  enableExpirationWarnings: _enableExpirationWarnings,
                                  enableBirthdayEmails: _enableBirthdayEmails,
                                  enableMembershipRenewal: _enableMembershipRenewal,
                                );

                                final ok = await ref.read(gymSettingsProvider.notifier).saveSettings(model);
                                if (!mounted || !context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ok ? 'Configuración de mensajes guardada exitosamente' : 'Error al guardar configuración'),
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
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
