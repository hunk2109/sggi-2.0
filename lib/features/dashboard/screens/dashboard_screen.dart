import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/dashboard_model.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  final Function(int)? onNavigate;

  const DashboardScreen({super.key, this.onNavigate});

  static final _currency = NumberFormat.currency(
    locale: 'es_DO',
    symbol: 'RD\$ ',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final state = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).loadOverview(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header greeting, shift status & refresh button
              _buildHeader(context, ref, user, state.data),

              const SizedBox(height: 24),

              // 2. Shortcut Action Cards (F1 - F4)
              _buildShortcutSection(context),

              const SizedBox(height: 28),

              // 3. State content: Loading, Error, or Live Data
              if (state.isLoading && state.data == null)
                _buildLoadingState()
              else if (state.error != null && state.data == null)
                _buildErrorState(context, ref, state.error!)
              else ...[
                // KPI Metric Cards
                _buildKpiMetrics(context, state.data!),

                const SizedBox(height: 28),

                // Middle Row: Monthly Sales Chart & Revenue Mix / Top Products
                _buildMiddleAnalyticsRow(context, state.data!),

                const SizedBox(height: 28),

                // Bottom Row: Recent Activity Feeds (Attendances & Sales)
                _buildRecentActivityRow(context, state.data!),

                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 1. Header
  // =========================================================================
  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    dynamic user,
    DashboardOverviewModel? data,
  ) {
    final now = DateTime.now();
    final dateStr = _formatHeaderDate(now);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Greeting & Date
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '¡Hola, ${user?.firstName ?? "Usuario"}!',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    user?.role.label ?? 'Usuario',
                    style: const TextStyle(
                      color: AppTheme.primaryLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 6),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '  •  Panel de Operaciones en Tiempo Real',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Right: Live Shift Status & Refresh
        Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Cash shift chip
            if (data != null)
              InkWell(
                onTap: () => onNavigate?.call(4), // Navigate to Cash Register
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: data.cashShiftOpen
                        ? AppTheme.success.withValues(alpha: 0.12)
                        : AppTheme.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: data.cashShiftOpen
                          ? AppTheme.success.withValues(alpha: 0.4)
                          : AppTheme.warning.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: data.cashShiftOpen
                              ? AppTheme.success
                              : AppTheme.warning,
                          boxShadow: [
                            BoxShadow(
                              color: (data.cashShiftOpen
                                      ? AppTheme.success
                                      : AppTheme.warning)
                                  .withValues(alpha: 0.6),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        data.cashShiftOpen
                            ? 'Caja Abierta: ${data.cashierName ?? "Cajero"}'
                            : 'Caja Cerrada (F4)',
                        style: TextStyle(
                          color: data.cashShiftOpen
                              ? AppTheme.success
                              : AppTheme.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: data.cashShiftOpen
                            ? AppTheme.success
                            : AppTheme.warning,
                      ),
                    ],
                  ),
                ),
              ),

            // Torniquete / Sync chip
            if (data != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.door_sliding_outlined,
                      size: 16,
                      color: data.syncConfigured ? AppTheme.accent : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      data.syncConfigured
                          ? 'ZKAccess: ${data.deviceIp ?? "Conectado"}'
                          : 'ZKAccess: Pendiente',
                      style: TextStyle(
                        color: data.syncConfigured
                            ? Colors.grey[200]
                            : Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // Reload button
            IconButton.filledTonal(
              onPressed: () =>
                  ref.read(dashboardProvider.notifier).loadOverview(),
              tooltip: 'Actualizar métricas',
              icon: const Icon(Icons.refresh_rounded, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.darkCard,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppTheme.darkBorder),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================================
  // 2. Shortcuts (F1 - F4)
  // =========================================================================
  Widget _buildShortcutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flash_on_rounded, size: 16, color: AppTheme.accent),
            const SizedBox(width: 6),
            Text(
              'ACCIONES RÁPIDAS DE MOSTRADOR',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildActionCard(
              context,
              title: 'Punto de Venta / Cobro',
              subtitle: 'Cobrar membresías y productos',
              shortcut: 'F1',
              icon: Icons.point_of_sale_rounded,
              color: const Color(0xFF0078D4),
              onTap: () => onNavigate?.call(1),
            ),
            const SizedBox(width: 16),
            _buildActionCard(
              context,
              title: 'Directorio de Socios',
              subtitle: 'Buscar, registrar y renovar',
              shortcut: 'F2',
              icon: Icons.people_alt_rounded,
              color: const Color(0xFF107C41),
              onTap: () => onNavigate?.call(2),
            ),
            const SizedBox(width: 16),
            _buildActionCard(
              context,
              title: 'Monitor de Torniquete',
              subtitle: 'Check-in en vivo y control acceso',
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
              icon: Icons.account_balance_wallet_rounded,
              color: const Color(0xFFD83B01),
              onTap: () => onNavigate?.call(4),
            ),
          ],
        ),
      ],
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
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.darkBorder),
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
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white12),
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
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 3. KPI Metrics Row (Real Data)
  // =========================================================================
  Widget _buildKpiMetrics(BuildContext context, DashboardOverviewModel data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.insights_rounded, size: 16, color: AppTheme.accent),
            const SizedBox(width: 6),
            Text(
              'MÉTRICAS PRINCIPALES DEL DÍA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // 1. Total Daily Revenue
            _buildMetricCard(
              context,
              title: 'Ingresos Totales Hoy',
              value: _currency.format(data.todayRevenue),
              subtitle:
                  '${data.todaySalesCount} transacciones cobradas hoy',
              icon: Icons.payments_rounded,
              accentColor: AppTheme.success,
              extraTag: 'POS + Membresías',
            ),
            const SizedBox(width: 16),

            // 2. Daily Check-ins
            _buildMetricCard(
              context,
              title: 'Entradas / Check-ins',
              value: '${data.todayCheckinsCount}',
              subtitle: 'Accesos por torniquete hoy',
              icon: Icons.how_to_reg_rounded,
              accentColor: AppTheme.primary,
              extraTag: 'ZKAccess',
            ),
            const SizedBox(width: 16),

            // 3. Active Members
            _buildMetricCard(
              context,
              title: 'Socios Activos',
              value: '${data.activeMembers}',
              subtitle: 'De un total de ${data.totalMembers} socios',
              icon: Icons.people_alt_rounded,
              accentColor: const Color(0xFF881798),
              extraTag: '${data.inactiveMembers} inactivos',
            ),
            const SizedBox(width: 16),

            // 4. Expiring Memberships
            _buildMetricCard(
              context,
              title: 'Membresías por Vencer',
              value: '${data.expiringMembershipsCount}',
              subtitle: 'En los próximos 7 días',
              icon: Icons.warning_amber_rounded,
              accentColor: AppTheme.warning,
              extraTag: 'Acción sugerida',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    String? extraTag,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.darkBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: accentColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (extraTag != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      extraTag,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 4. Middle Analytics Row (Monthly Chart & Revenue Mix / Top Products)
  // =========================================================================
  Widget _buildMiddleAnalyticsRow(
    BuildContext context,
    DashboardOverviewModel data,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left 60%: Monthly Revenue Trend Bar Chart
        Expanded(
          flex: 6,
          child: _buildMonthlyTrendCard(context, data),
        ),

        const SizedBox(width: 20),

        // Right 40%: Revenue Mix & Top Products
        Expanded(
          flex: 4,
          child: _buildRevenueAndTopProductsCard(context, data),
        ),
      ],
    );
  }

  Widget _buildMonthlyTrendCard(
    BuildContext context,
    DashboardOverviewModel data,
  ) {
    final list = data.monthlySales;
    final maxRevenue = list.fold<double>(
      1000.0,
      (prev, elem) => elem.totalRevenue > prev ? elem.totalRevenue : prev,
    );

    final totalPeriod = list.fold<double>(0.0, (prev, e) => prev + e.totalRevenue);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tendencia de Ingresos Mensuales',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Facturación acumulada últimos 6 meses',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total: ${_currency.format(totalPeriod)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Bar Chart Visualization
          if (list.isEmpty)
            const SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  'No hay registros de ventas para este período.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: list.map((item) {
                  final ratio = (item.totalRevenue / maxRevenue).clamp(0.04, 1.0);
                  final isCurrentMonth = item.month == DateTime.now().month &&
                      item.year == DateTime.now().year;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Tooltip(
                        message:
                            '${item.monthName} ${item.year}\n${_currency.format(item.totalRevenue)}\n${item.transactionCount} ventas',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Revenue Text on top
                            Text(
                              item.totalRevenue >= 1000
                                  ? 'RD\$ ${(item.totalRevenue / 1000).toStringAsFixed(1)}k'
                                  : 'RD\$ ${item.totalRevenue.toInt()}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isCurrentMonth
                                    ? AppTheme.accent
                                    : Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Animated/styled vertical bar
                            Container(
                              height: 120 * ratio,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: isCurrentMonth
                                      ? [
                                          AppTheme.primary,
                                          AppTheme.accent,
                                        ]
                                      : [
                                          const Color(0xFF2E384D),
                                          const Color(0xFF455A7E),
                                        ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Month Label
                            Text(
                              item.monthName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isCurrentMonth
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isCurrentMonth
                                    ? Colors.white
                                    : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRevenueAndTopProductsCard(
    BuildContext context,
    DashboardOverviewModel data,
  ) {
    final memberships = data.revenueDistribution.firstWhere(
      (e) => e.name == 'Membresías',
      orElse: () => RevenueDistributionItem(name: 'Membresías', revenue: 0, percentage: 0),
    );
    final products = data.revenueDistribution.firstWhere(
      (e) => e.name == 'Productos',
      orElse: () => RevenueDistributionItem(name: 'Productos', revenue: 0, percentage: 0),
    );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Composición & Más Vendidos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Membresías vs productos de hoy',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),

          const SizedBox(height: 16),

          // Proportion Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: (memberships.percentage * 10).toInt().clamp(1, 1000),
                    child: Container(color: AppTheme.primary),
                  ),
                  Expanded(
                    flex: (products.percentage * 10).toInt().clamp(1, 1000),
                    child: Container(color: AppTheme.accent),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Membresías: ${memberships.percentage.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Productos: ${products.percentage.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),

          const Divider(height: 28, color: AppTheme.darkBorder),

          // Top 5 Products
          const Text(
            'TOP PRODUCTOS MÁS VENDIDOS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),

          if (data.topProducts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  'No hay ventas de mostrador registradas.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            )
          else
            ...data.topProducts.take(4).map((p) {
              final index = data.topProducts.indexOf(p) + 1;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: index == 1
                            ? const Color(0xFFFFB900).withValues(alpha: 0.2)
                            : Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '#$index',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: index == 1 ? const Color(0xFFFFB900) : Colors.grey[400],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '${p.quantity} unids.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _currency.format(p.revenue),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // =========================================================================
  // 5. Bottom Row: Recent Activity Feeds (Attendances & Sales)
  // =========================================================================
  Widget _buildRecentActivityRow(
    BuildContext context,
    DashboardOverviewModel data,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Recent Attendances (Torniquete)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.door_sliding_outlined,
                          size: 18,
                          color: AppTheme.accent,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Últimos Accesos (Torniquete)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => onNavigate?.call(3),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Ver monitor (F3)', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (data.recentAttendances.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text(
                        'Aún no hay entradas registradas hoy.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  )
                else
                  ...data.recentAttendances.map((att) {
                    final isGranted = att.status.toLowerCase() == 'accepted' ||
                        att.status.toLowerCase() == 'permitido';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: isGranted
                                ? AppTheme.success.withValues(alpha: 0.15)
                                : AppTheme.error.withValues(alpha: 0.15),
                            child: Icon(
                              isGranted
                                  ? Icons.check_circle_outline
                                  : Icons.cancel_outlined,
                              size: 18,
                              color: isGranted ? AppTheme.success : AppTheme.error,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  att.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  att.memberCode.isNotEmpty
                                      ? 'Código: ${att.memberCode}'
                                      : 'Tipo: ${att.type}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatTimeAgo(att.time),
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),

        const SizedBox(width: 20),

        // Right: Recent POS Sales
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_long_rounded,
                          size: 18,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Últimas Ventas y Cobros',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => onNavigate?.call(1),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Ir a POS (F1)', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (data.recentSales.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text(
                        'Aún no hay ventas registradas hoy.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  )
                else
                  ...data.recentSales.map((sale) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                            child: const Icon(
                              Icons.attach_money_rounded,
                              size: 18,
                              color: AppTheme.primaryLight,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sale.clientName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${sale.invoiceNumber ?? "Venta"} • ${_formatPaymentMethod(sale.paymentMethod)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _currency.format(sale.amount),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.success,
                                ),
                              ),
                              Text(
                                _formatTimeAgo(sale.time),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // Loading & Error States
  // =========================================================================
  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80.0),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(color: AppTheme.primary),
            const SizedBox(height: 16),
            Text(
              'Cargando métricas en tiempo real...',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 30),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 40, color: AppTheme.error),
          const SizedBox(height: 12),
          const Text(
            'Error al cargar métricas del dashboard',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.read(dashboardProvider.notifier).loadOverview(),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // Helper Formatters
  // =========================================================================
  String _formatHeaderDate(DateTime date) {
    const days = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
    ];
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    return '$dayName, ${date.day} de $monthName ${date.year}';
  }

  String _formatTimeAgo(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return DateFormat('hh:mm a').format(time);
    return DateFormat('dd/MM hh:mm a').format(time);
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Efectivo';
      case 'card':
        return 'Tarjeta';
      case 'transfer':
        return 'Transferencia';
      default:
        return method;
    }
  }
}
