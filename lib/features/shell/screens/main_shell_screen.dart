import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:window_manager/window_manager.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../members/screens/members_screen.dart';

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
    (title: 'Punto de Venta', icon: Icons.point_of_sale, shortcut: 'F1'),
    (title: 'Socios & Membresías', icon: Icons.people_alt_outlined, shortcut: 'F2'),
    (title: 'Control de Acceso', icon: Icons.door_sliding_outlined, shortcut: 'F3'),
    (title: 'Caja & Arqueo', icon: Icons.account_balance_wallet_outlined, shortcut: 'F4'),
    (title: 'Inventario & Productos', icon: Icons.inventory_2_outlined, shortcut: 'F5'),
    (title: 'Nómina & Empleados', icon: Icons.badge_outlined, shortcut: 'F6'),
    (title: 'Reportes & Métricas', icon: Icons.bar_chart_outlined, shortcut: 'F7'),
  ];

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateClock());
  }

  void _updateClock() {
    setState(() {
      _currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: Column(
          children: [
            // Top Window Bar (Native Desktop Drag & Controls)
            _buildCustomTitleBar(),

            // Main Body (Sidebar + Content)
            Expanded(
              child: Row(
                children: [
                  // Collapsible Sidebar
                  _buildSidebar(),

                  // Active Content
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
                  const SizedBox(width: 12),
                  const Icon(Icons.fitness_center, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'SGGI 2.0  •  Gestión de Gimnasio',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Windows Native Desktop',
                      style: TextStyle(fontSize: 10, color: Colors.white38),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Window Buttons (Minimize, Maximize, Close)
          _buildWindowButton(
            icon: Icons.minimize,
            onTap: () => windowManager.minimize(),
          ),
          _buildWindowButton(
            icon: Icons.crop_square,
            onTap: () async {
              if (await windowManager.isMaximized()) {
                windowManager.unmaximize();
              } else {
                windowManager.maximize();
              }
            },
          ),
          _buildWindowButton(
            icon: Icons.close,
            isClose: true,
            onTap: () => windowManager.close(),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isClose = false,
  }) {
    return InkWell(
      onTap: onTap,
      hoverColor: isClose ? Colors.red : Colors.white.withValues(alpha: 0.1),
      child: SizedBox(
        width: 46,
        height: 38,
        child: Center(
          child: Icon(icon, size: 14, color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isSidebarCollapsed ? 68 : 240,
      color: const Color(0xFF1A1E24),
      child: Column(
        children: [
          // Collapse / Expand Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                              if (item.shortcut.isNotEmpty)
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
    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(onNavigate: (index) => setState(() => _selectedIndex = index));
      case 2:
        return const MembersScreen();
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
              Text(
                'Módulo preparado para implementación en Fase ${_selectedIndex <= 3 ? 2 : 3}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildStatusBar(dynamic user) {
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
              const Icon(Icons.security, size: 13, color: Colors.white38),
              const SizedBox(width: 6),
              const Text(
                'ZKTeco: Sincronizado',
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
            ],
          ),
          Row(
            children: [
              if (user != null) ...[
                Text(
                  'Usuario: ${user.fullName} (${user.role.label})',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
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

