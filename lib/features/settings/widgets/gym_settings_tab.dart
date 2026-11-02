import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/gym_settings_model.dart';
import '../providers/settings_provider.dart';

class GymSettingsTab extends ConsumerStatefulWidget {
  const GymSettingsTab({super.key});

  @override
  ConsumerState<GymSettingsTab> createState() => _GymSettingsTabState();
}

class _GymSettingsTabState extends ConsumerState<GymSettingsTab> {
  final _gymNameCtrl = TextEditingController();
  final _rncCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _openingTimeCtrl = TextEditingController();
  final _closingTimeCtrl = TextEditingController();
  final _suspensionDaysCtrl = TextEditingController();
  String _ticketPaperSize = '80mm';
  bool _isInitialized = false;

  @override
  void dispose() {
    _gymNameCtrl.dispose();
    _rncCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _websiteCtrl.dispose();
    _openingTimeCtrl.dispose();
    _closingTimeCtrl.dispose();
    _suspensionDaysCtrl.dispose();
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
    _ticketPaperSize = settings.ticketPaperSize.isNotEmpty ? settings.ticketPaperSize : '80mm';
    _isInitialized = true;
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gymSettingsProvider);
    if (state.settings != null) {
      _populateFields(state.settings!);
    }

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
                    child: _buildTimePickerField('Hora de Apertura', _openingTimeCtrl, '06:00'),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildTimePickerField('Hora de Cierre', _closingTimeCtrl, '22:00'),
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
                            if (!mounted || !context.mounted) return;
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
}
