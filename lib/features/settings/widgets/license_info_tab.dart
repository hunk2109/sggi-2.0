import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/license/license_provider.dart';
import '../../../core/license/license_validator.dart';
import '../../../core/theme/app_theme.dart';

class LicenseInfoTab extends ConsumerStatefulWidget {
  const LicenseInfoTab({super.key});

  @override
  ConsumerState<LicenseInfoTab> createState() => _LicenseInfoTabState();
}

class _LicenseInfoTabState extends ConsumerState<LicenseInfoTab> {
  final _keyCtrl = TextEditingController();
  bool _isUpdating = false;

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _updateLicense() async {
    final key = _keyCtrl.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa una clave de licencia.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isUpdating = true);
    final ok = await ref.read(licenseProvider.notifier).activate(key);
    if (!mounted) return;
    setState(() => _isUpdating = false);

    if (ok) {
      _keyCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Licencia actualizada y validada con éxito!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final err = ref.read(licenseProvider).error ?? 'Clave de activación inválida o no corresponde a este equipo.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _copyWhatsAppRenewalMessage(LicenseState lic) {
    final vigencia = lic.license?.expiresAt != null
        ? DateFormat('dd/MM/yyyy').format(lic.license!.expiresAt!)
        : 'Permanente (De Por Vida)';

    final msg = '''¡Hola Ravenkeep Development!
Necesito soporte / renovación de licencia para el software *SGGI 2.0 (Gestión de Gimnasio)*.

*Código de Equipo (HW ID):* ${lic.hardwareId}
*Estado Actual:* ${lic.isActivated ? 'Activa' : 'Sin Licencia'}
*Vigencia:* $vigencia

Quedo a la espera de su respuesta. ¡Muchas gracias!''';

    _copyToClipboard(msg, 'Mensaje de solicitud para WhatsApp copiado al portapapeles');
  }

  @override
  Widget build(BuildContext context) {
    final lic = ref.watch(licenseProvider);
    final data = lic.license;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (lic.isActivated ? Colors.green : Colors.red).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  lic.isActivated ? Icons.verified_user : Icons.gpp_bad_outlined,
                  color: lic.isActivated ? Colors.greenAccent : Colors.redAccent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Licenciamiento del Sistema',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'Información sobre la vigencia del software, módulos contratados y soporte oficial.',
                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: (lic.isActivated ? Colors.green : Colors.red).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: lic.isActivated ? Colors.greenAccent : Colors.redAccent,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      lic.isActivated ? Icons.check_circle : Icons.warning_amber_rounded,
                      size: 16,
                      color: lic.isActivated ? Colors.greenAccent : Colors.redAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      lic.isActivated ? 'LICENCIA ACTIVA' : 'SIN LICENCIA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: lic.isActivated ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Layout en 2 columnas
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildDetailsCard(lic, data)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildSupportAndRenewalCard(lic)),
                      ],
                    )
                  : Column(
                      children: [
                        _buildDetailsCard(lic, data),
                        const SizedBox(height: 24),
                        _buildSupportAndRenewalCard(lic),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(LicenseState lic, LicenseData? data) {
    String vigenciaText;
    Color vigenciaColor = Colors.white;

    if (!lic.isActivated) {
      vigenciaText = 'No activada';
      vigenciaColor = Colors.redAccent;
    } else if (data?.expiresAt == null) {
      vigenciaText = 'Permanente (De Por Vida)';
      vigenciaColor = Colors.greenAccent;
    } else {
      final days = lic.daysRemaining ?? 0;
      final dateStr = DateFormat('dd/MM/yyyy').format(data!.expiresAt!);
      vigenciaText = '$dateStr ($days días restantes)';
      vigenciaColor = days > 15 ? Colors.greenAccent : Colors.orangeAccent;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF181C25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A303C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: AppTheme.primary),
              SizedBox(width: 8),
              Text(
                'Detalles de la Suscripción',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFF2A303C)),
          const SizedBox(height: 16),

          // Fila Vigencia
          _buildInfoRow(
            icon: Icons.timer_outlined,
            title: 'Vigencia de la Licencia',
            value: vigenciaText,
            valueColor: vigenciaColor,
          ),
          const SizedBox(height: 14),

          // Fila Sincronización en la Nube
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (data?.cloudAccess ?? false)
                  ? Colors.blue.withValues(alpha: 0.08)
                  : Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (data?.cloudAccess ?? false)
                    ? Colors.blueAccent.withValues(alpha: 0.3)
                    : Colors.amber.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  (data?.cloudAccess ?? false) ? Icons.cloud_done : Icons.cloud_off,
                  color: (data?.cloudAccess ?? false) ? Colors.lightBlueAccent : Colors.amberAccent,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (data?.cloudAccess ?? false)
                            ? 'Sincronización en la Nube: Habilitada ☁️'
                            : 'Plan Solo Local (Sin Nube / Offline) 💻',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: (data?.cloudAccess ?? false) ? Colors.lightBlueAccent : Colors.amberAccent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (data?.cloudAccess ?? false)
                            ? 'Tu plan incluye acceso a sincronización remota, respaldos y conectividad en la nube.'
                            : 'El sistema funciona de forma 100% independiente y local. No requiere conexión a internet para operar.',
                        style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Fila Código de Equipo (HW ID)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.computer_outlined, size: 16, color: Colors.white70),
                  SizedBox(width: 6),
                  Text('Código de Equipo (HW ID)', style: TextStyle(fontSize: 13, color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2A303C)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        lic.hardwareId.isEmpty ? 'OBTENIENDO HW ID...' : lic.hardwareId,
                        style: const TextStyle(
                          fontFamily: 'Consolas',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copiar HW ID',
                      onPressed: () => _copyToClipboard(lic.hardwareId, 'Código de equipo copiado'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Este identificador único vincula la licencia a esta computadora.',
                style: TextStyle(fontSize: 11, color: Colors.white38),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFF2A303C)),
          const SizedBox(height: 16),

          // Módulos Contratados
          const Row(
            children: [
              Icon(Icons.view_module_outlined, size: 18, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Módulos Habilitados', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildModuleChip('👥 Miembros y Clientes', lic.hasModule(LicenseModules.miembros)),
              _buildModuleChip('🎟️ Membresías y Promos', lic.hasModule(LicenseModules.membresias)),
              _buildModuleChip('🚪 Control de Acceso', lic.hasModule(LicenseModules.acceso)),
              _buildModuleChip('🛒 Punto de Venta (POS)', lic.hasModule(LicenseModules.pos)),
              _buildModuleChip('💵 Caja y Cierres', lic.hasModule(LicenseModules.caja)),
              _buildModuleChip('📦 Inventario', lic.hasModule(LicenseModules.inventario)),
              _buildModuleChip('💼 Empleados y Nómina', lic.hasModule(LicenseModules.empleados)),
              _buildModuleChip('📢 Campañas Masivas', lic.hasModule(LicenseModules.campanas)),
              _buildModuleChip('📊 Dashboard y Reportes', lic.hasModule(LicenseModules.reportes)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportAndRenewalCard(LicenseState lic) {
    return Column(
      children: [
        // Tarjeta Empresa de Desarrollo
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF181C25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A303C)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.business_outlined, size: 20, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text(
                    'Empresa Desarrolladora & Soporte',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFF2A303C)),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.code, color: AppTheme.primary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ravenkeep Development',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Desarrollo de Software a Medida, Ecosistemas POS y Automatización Empresarial.',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildContactItem(
                      icon: Icons.chat_bubble_outline,
                      title: 'Soporte y Ventas WhatsApp',
                      value: 'Atención al Cliente & Licencias',
                    ),
                    const SizedBox(height: 8),
                    _buildContactItem(
                      icon: Icons.shield_outlined,
                      title: 'Garantía del Software',
                      value: 'Actualizaciones de Seguridad y Estabilidad',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _copyWhatsAppRenewalMessage(lic),
                  icon: const Icon(Icons.mark_chat_unread_outlined, color: Colors.greenAccent),
                  label: const Text('COPIAR MENSAJE PARA WHATSAPP', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.greenAccent.withValues(alpha: 0.5)),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Tarjeta Renovar / Activar Clave
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF181C25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2A303C)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.key_outlined, size: 20, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text(
                    'Renovar o Cambiar Clave de Activación',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Si adquiriste una extensión de vigencia o nuevos módulos, pega aquí la nueva clave suministrada por Ravenkeep Development.',
                style: TextStyle(fontSize: 12, color: Colors.white60),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _keyCtrl,
                maxLines: 3,
                style: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
                decoration: const InputDecoration(
                  labelText: 'Nueva Clave de Activación',
                  hintText: 'Pega aquí la clave en Base64...',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.black26,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.icon(
                  onPressed: _isUpdating ? null : _updateLicense,
                  icon: _isUpdating
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check_circle_outline),
                  label: const Text('VALIDAR Y APLICAR LICENCIA'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    Color valueColor = Colors.white,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white60),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 13, color: Colors.white70)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }

  Widget _buildContactItem({required IconData icon, required String title, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(value, style: const TextStyle(fontSize: 11, color: Colors.white54)),
          ],
        ),
      ],
    );
  }

  Widget _buildModuleChip(String label, bool isEnabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isEnabled ? Colors.green.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isEnabled ? Colors.greenAccent.withValues(alpha: 0.4) : const Color(0xFF2A303C),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEnabled ? Icons.check : Icons.lock_outline,
            size: 14,
            color: isEnabled ? Colors.greenAccent : Colors.white38,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isEnabled ? FontWeight.w600 : FontWeight.normal,
              color: isEnabled ? Colors.white : Colors.white38,
            ),
          ),
        ],
      ),
    );
  }
}
