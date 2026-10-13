import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  final Function(int)? onNavigate;

  const DashboardScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Quick Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Hola, ${user?.firstName ?? "Usuario"}!',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Panel de control de operaciones del gimnasio',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Rol: ${user?.role.label ?? "Desconocido"}',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Shortcut Quick Action Cards
          const Text(
            'ACCIONES RÁPIDAS DE MOSTRADOR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _buildActionCard(
                context,
                title: 'Punto de Venta / Cobro',
                subtitle: 'Cobrar membresías y productos',
                shortcut: 'F1',
                icon: Icons.point_of_sale,
                color: const Color(0xFF0078D4),
                onTap: () => onNavigate?.call(1),
              ),
              const SizedBox(width: 16),
              _buildActionCard(
                context,
                title: 'Directorio de Socios',
                subtitle: 'Buscar, registrar y renovar',
                shortcut: 'F2',
                icon: Icons.people_alt_outlined,
                color: const Color(0xFF107C41),
                onTap: () => onNavigate?.call(2),
              ),
              const SizedBox(width: 16),
              _buildActionCard(
                context,
                title: 'Monitor de Torniquete',
                subtitle: 'Check-in en tiempo real y ZKTeco',
                shortcut: 'F3',
                icon: Icons.door_sliding_outlined,
                color: const Color(0xFF881798),
                onTap: () => onNavigate?.call(3),
              ),
              const SizedBox(width: 16),
              _buildActionCard(
                context,
                title: 'Caja & Arqueo',
                subtitle: 'Aperturas, cierres y desglose',
                shortcut: 'F4',
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFFD83B01),
                onTap: () => onNavigate?.call(4),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Overview KPI Cards
          const Text(
            'MÉTRICAS DEL DÍA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _buildMetricCard(
                context,
                title: 'Ventas Totales Hoy',
                value: 'RD\$ 0.00',
                trend: '+0% vs ayer',
                icon: Icons.attach_money,
              ),
              const SizedBox(width: 16),
              _buildMetricCard(
                context,
                title: 'Check-ins / Entradas',
                value: '0 entradas',
                trend: 'Torniquetes activos',
                icon: Icons.login,
              ),
              const SizedBox(width: 16),
              _buildMetricCard(
                context,
                title: 'Membresías por Vencer',
                value: '0 socios',
                trend: 'Próximos 3 días',
                icon: Icons.warning_amber_rounded,
              ),
              const SizedBox(width: 16),
              _buildMetricCard(
                context,
                title: 'Estado del Sincronizador',
                value: 'Conectado',
                trend: 'ZKAccess DB OK',
                icon: Icons.sync,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String shortcut,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        shortcut,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String trend,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                Icon(icon, size: 18, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              trend,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
