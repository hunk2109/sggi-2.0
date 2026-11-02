import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/access_db_tab.dart';
import '../widgets/automation_reports_tab.dart';
import '../widgets/coupons_promotions_tab.dart';
import '../widgets/gym_settings_tab.dart';
import '../widgets/license_info_tab.dart';
import '../widgets/roles_permissions_tab.dart';
import '../widgets/whatsapp_email_tab.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    ref.read(emailConfigProvider.notifier).loadConfig();
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
                  Tab(icon: Icon(Icons.mark_chat_read_outlined, size: 18), text: 'WhatsApp & Correo'),
                  Tab(icon: Icon(Icons.discount_outlined, size: 18), text: 'Cupones & Promociones'),
                  Tab(icon: Icon(Icons.fitness_center_outlined, size: 18), text: 'Datos del Gimnasio & Empresa'),
                  Tab(icon: Icon(Icons.notifications_active_outlined, size: 18), text: 'Reportes & Automatización'),
                  Tab(icon: Icon(Icons.fingerprint, size: 18), text: 'Biométrico & BD Access'),
                  Tab(icon: Icon(Icons.security_outlined, size: 18), text: 'Roles & Permisos'),
                  Tab(icon: Icon(Icons.verified_user_outlined, size: 18), text: 'Licencia del Sistema'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  const WhatsappEmailTab(),
                  const CouponsPromotionsTab(),
                  const GymSettingsTab(),
                  const AutomationReportsTab(),
                  const AccessDbTab(),
                  ref.watch(authProvider).user?.role.isAdmin == true
                      ? const RolesPermissionsTab()
                      : const _RolesRestrictedPlaceholder(),
                  const LicenseInfoTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RolesRestrictedPlaceholder extends StatelessWidget {
  const _RolesRestrictedPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.darkBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.security, size: 48, color: Colors.amber),
            ),
            const SizedBox(height: 20),
            const Text(
              'Acceso Restringido',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              'La gestión de roles, permisos y asignación de usuarios requiere privilegios de Administrador.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
