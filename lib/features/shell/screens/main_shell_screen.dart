import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:window_manager/window_manager.dart';
import '../../../core/license/license_provider.dart';
import '../../../core/license/license_validator.dart';
import '../../../core/theme/app_theme.dart';
import '../../access/screens/access_control_screen.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../members/screens/members_hub_screen.dart';
import '../../pos/screens/pos_screen.dart';
import '../../cash_register/screens/cash_register_screen.dart';
import '../../inventory/screens/inventory_screen.dart';
import '../../employees/screens/employees_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../settings/providers/settings_provider.dart';
import '../../campaigns/screens/campaigns_screen.dart';
import '../../auth/dialogs/user_profile_dialog.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;
  late Timer _clockTimer;
  String _currentTime = '';

  final List<({String title, IconData icon, String shortcut})> _navItems = [
    (title: 'Dashboard', icon: Icons.dashboard_outlined, shortcut: ''),
    (title: 'Punto de Venta', icon: Icons.point_of_sale_outlined, shortcut: 'F1'),
    (title: 'Socios & Membresías', icon: Icons.people_alt_outlined, shortcut: 'F2'),
    (title: 'Control de Acceso', icon: Icons.door_sliding_outlined, shortcut: 'F3'),
    (title: 'Caja & Arqueo', icon: Icons.account_balance_wallet_outlined, shortcut: 'F4'),
    (title: 'Inventario & Productos', icon: Icons.inventory_2_outlined, shortcut: 'F5'),
    (title: 'Nómina & Empleados', icon: Icons.badge_outlined, shortcut: 'F6'),
    (title: 'Envíos Masivos', icon: Icons.campaign_outlined, shortcut: 'F7'),
    (title: 'Reportes & Métricas', icon: Icons.bar_chart_outlined, shortcut: 'F8'),
    (title: 'Configuración', icon: Icons.settings_outlined, shortcut: 'F9'),
  ];

  /// Módulo de licencia requerido por cada entrada del menú (null = siempre disponible).
  static const List<String?> _navModules = [
    null, // Dashboard
    LicenseModules.pos,
    LicenseModules.miembros,
    LicenseModules.acceso,
    LicenseModules.caja,
    LicenseModules.inventario,
    LicenseModules.empleados,
    LicenseModules.campanas,
    LicenseModules.reportes,
    null, // Configuración
  ];

  bool _isLocked(int index) {
    final module = _navModules[index];
    return module != null && !ref.read(licenseProvider).hasModule(module);
  }

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
  }

  void _updateClock() {
    final now = DateTime.now();
    setState(() {
      try {
        _currentTime = DateFormat('hh:mm:ss a   EEE d MMM', 'es_DO').format(now);
      } catch (_) {
        try {
          _currentTime = DateFormat('hh:mm:ss a   EEE d MMM', 'es').format(now);
        } catch (_) {
          _currentTime = DateFormat('hh:mm:ss a').format(now);
        }
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.f1) {
        setState(() => _selectedIndex = 1);
      } else if (event.logicalKey == LogicalKeyboardKey.f2) {
        setState(() => _selectedIndex = 2);
      } else if (event.logicalKey == LogicalKeyboardKey.f3) {
        setState(() => _selectedIndex = 3);
      } else if (event.logicalKey == LogicalKeyboardKey.f4) {
        setState(() => _selectedIndex = 4);
      } else if (event.logicalKey == LogicalKeyboardKey.f5) {
        setState(() => _selectedIndex = 5);
      } else if (event.logicalKey == LogicalKeyboardKey.f6) {
        setState(() => _selectedIndex = 6);
      } else if (event.logicalKey == LogicalKeyboardKey.f7) {
        setState(() => _selectedIndex = 7);
      } else if (event.logicalKey == LogicalKeyboardKey.f8) {
        setState(() => _selectedIndex = 8);
      } else if (event.logicalKey == LogicalKeyboardKey.f9) {
        setState(() => _selectedIndex = 9);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: Column(
          children: [
            // Custom Desktop Titlebar
            _buildCustomTitleBar(),

            // Main Application View
            Expanded(
              child: Row(
                children: [
                  // Collapsible Sidebar
                  _buildSidebar(context),

                  // Content Area
                  Expanded(
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: _buildBody(),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Status Bar
            _buildStatusBar(user),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTitleBar() {
    return Container(
      height: 38,
      color: const Color(0xFF16191E),
      child: Row(
        children: [
          // Drag Window Area with Icon and Title
          Expanded(
            child: DragToMoveArea(
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.fitness_center, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  const Text(
                    'SGGI 2.0  •  Gestión de Gimnasio',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Windows Native Desktop',
                      style: TextStyle(fontSize: 10, color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Native Window Buttons
          _buildWindowButton(
            icon: Icons.minimize,
            onPressed: () async => await windowManager.minimize(),
          ),
          _buildWindowButton(
            icon: Icons.crop_square,
            onPressed: () async {
              if (await windowManager.isMaximized()) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
            },
          ),
          _buildWindowButton(
            icon: Icons.close,
            isClose: true,
            onPressed: () async => await windowManager.close(),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowButton({required IconData icon, required VoidCallback onPressed, bool isClose = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        hoverColor: isClose ? Colors.red : Colors.white10,
        onTap: onPressed,
        child: SizedBox(
          width: 46,
          height: 38,
          child: Icon(
            icon,
            size: 15,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final width = _isSidebarCollapsed ? 68.0 : 230.0;
    final user = ref.watch(authProvider).user;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: const BoxDecoration(
        color: Color(0xFF1B2028),
        border: Border(
          right: BorderSide(color: Color(0xFF2A303C), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Sidebar Toggle & Header
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: _isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
              children: [
                if (!_isSidebarCollapsed)
                  const Text(
                    'MENÚ PRINCIPAL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: Colors.white38,
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    _isSidebarCollapsed ? Icons.menu : Icons.menu_open,
                    size: 18,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFF2A303C)),

          // Navigation List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;
                final locked = _isLocked(index);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Material(
                    color: isSelected ? AppTheme.primary.withValues(alpha: 0.18) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => _selectedIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 20,
                              color: isSelected ? AppTheme.primary : Colors.white70,
                            ),
                            if (!_isSidebarCollapsed) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    color: isSelected ? Colors.white : Colors.white70,
                                  ),
                                ),
                              ),
                              if (locked)
                                const Icon(Icons.lock_outline, size: 14, color: Colors.white38)
                              else if (item.shortcut.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black38,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.shortcut,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white38,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // User Profile Tile
          const Divider(height: 1, color: Color(0xFF2A303C)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => UserProfileDialog.show(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.25),
                      child: Text(
                        user != null && user.firstName.isNotEmpty
                            ? user.firstName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    if (!_isSidebarCollapsed) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'Mi Perfil',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              user?.role.label ?? 'Editar perfil',
                              style: const TextStyle(fontSize: 10, color: Colors.white54),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.settings_outlined, size: 16, color: Colors.white38),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Logout Button
          const Divider(height: 1, color: Color(0xFF2A303C)),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => ref.read(authProvider.notifier).logout(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.logout, size: 18, color: Colors.redAccent),
                    if (!_isSidebarCollapsed) ...[
                      const SizedBox(width: 12),
                      const Text(
                        'Cerrar Sesión',
                        style: TextStyle(fontSize: 13, color: Colors.redAccent),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLocked(_selectedIndex)) {
      final current = _navItems[_selectedIndex];
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(current.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Este módulo no está incluido en tu licencia. Contacta a tu proveedor para habilitarlo.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(onNavigate: (index) => setState(() => _selectedIndex = index));
      case 1:
        return const PosScreen();
      case 2:
        return const MembersHubScreen();
      case 3:
        return const AccessControlScreen();
      case 4:
        return const CashRegisterScreen();
      case 5:
        return const InventoryScreen();
      case 6:
        return const EmployeesScreen();
      case 7:
        return const CampaignsScreen();
      case 9:
        return const SettingsScreen();
      default:
        final current = _navItems[_selectedIndex];
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(current.icon, size: 64, color: AppTheme.primary.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                current.title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Módulo preparado para Reportes & Métricas Avanzadas (Fase 4)',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildStatusBar(dynamic user) {
    final hasCloudAccess = ref.watch(licenseProvider).hasCloudAccess;
    final isZktecoEnabled = ref.watch(zktecoSyncProvider);

    return Container(
      height: 28,
      color: const Color(0xFF14171C),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF107C41),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Backend: Online',
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
              const SizedBox(width: 20),
              const Icon(Icons.print, size: 13, color: Colors.white38),
              const SizedBox(width: 6),
              const Text(
                'Impresora POS: Conectada (80mm)',
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
              const SizedBox(width: 20),
              Icon(
                isZktecoEnabled ? Icons.fingerprint : Icons.fingerprint_outlined,
                size: 13,
                color: isZktecoEnabled ? Colors.greenAccent : Colors.white38,
              ),
              const SizedBox(width: 6),
              Text(
                isZktecoEnabled ? 'ZKTeco: Sincronizado' : 'Biométrico: Desactivado (Manual)',
                style: TextStyle(
                  fontSize: 11,
                  color: isZktecoEnabled ? Colors.white70 : Colors.white38,
                ),
              ),
              const SizedBox(width: 20),
              Icon(
                hasCloudAccess ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                size: 13,
                color: hasCloudAccess ? Colors.lightBlueAccent : Colors.amber.shade300,
              ),
              const SizedBox(width: 6),
              Text(
                hasCloudAccess ? 'Sincronización Nube: Activa' : 'Modo: Solo Local (Offline)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: hasCloudAccess ? FontWeight.normal : FontWeight.w600,
                  color: hasCloudAccess ? Colors.lightBlueAccent : Colors.amber.shade200,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (user != null) ...[
                InkWell(
                  onTap: () => UserProfileDialog.show(context),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_circle_outlined, size: 14, color: AppTheme.primaryLight),
                        const SizedBox(width: 4),
                        Text(
                          'Usuario: ${user.fullName} (${user.role.label})',
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Text(
                _currentTime,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
