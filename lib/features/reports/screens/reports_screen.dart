import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../models/analytics_model.dart';
import '../providers/reports_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToCampaigns;
  final VoidCallback? onNavigateToEmployees;

  const ReportsScreen({
    super.key,
    this.onNavigateToCampaigns,
    this.onNavigateToEmployees,
  });

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final _currency = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);
  bool _isSendingReport = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportsProvider.notifier).fetchAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1216),
      body: Column(
        children: [
          _buildHeader(state),
          Expanded(
            child: state.isLoading && state.analytics == null
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppTheme.primary),
                        SizedBox(height: 16),
                        Text(
                          'Calculando métricas y análisis de comportamiento...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  )
                : state.error != null && state.analytics == null
                    ? _buildErrorView(state.error!)
                    : _buildDashboardContent(state.analytics!),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ReportsState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF16191E),
        border: Border(bottom: BorderSide(color: Color(0xFF23272F))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.analytics_outlined, color: AppTheme.primary, size: 26),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inteligencia Financiera & Métricas de Negocio',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 2),
              Text(
                'Análisis de ingresos, nómina, horas pico y recomendaciones predictivas',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
          const Spacer(),
          // Filter Tabs
          _buildPeriodSelector(state.selectedRange),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Actualizar Datos',
            onPressed: () => ref.read(reportsProvider.notifier).fetchAnalytics(),
            icon: state.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                  )
                : const Icon(Icons.refresh, color: Colors.white70),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            icon: _isSendingReport
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded, size: 16),
            label: Text(_isSendingReport ? 'Enviando...' : 'Enviar Reporte Manual'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _isSendingReport ? null : _handleSendManualReport,
          ),
        ],
      ),
    );
  }

  Future<void> _handleSendManualReport() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E222B),
        title: const Row(
          children: [
            Icon(Icons.mark_email_read_outlined, color: AppTheme.primary),
            SizedBox(width: 10),
            Text('Enviar Resumen Diario', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: const Text(
          '¿Deseas generar el reporte de corte y enviarlo de inmediato a los destinatarios configurados (WhatsApp / Correo)?',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enviar Ahora', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSendingReport = true);
    try {
      final res = await ref.read(reportsServiceProvider).sendDailySummaryReport();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: res.success ? AppTheme.success : AppTheme.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar el reporte: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSendingReport = false);
    }
  }

  Widget _buildPeriodSelector(String selectedRange) {
    final ranges = [
      {'key': 'weekly', 'label': 'Semana'},
      {'key': 'monthly', 'label': 'Este Mes'},
      {'key': 'quarterly', 'label': 'Trimestre'},
      {'key': 'yearly', 'label': 'Año'},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1216),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2E37)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ranges.map((r) {
          final isSelected = selectedRange == r['key'];
          return InkWell(
            onTap: () => ref.read(reportsProvider.notifier).changeRange(r['key']!),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                r['label']!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D24),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 14),
            const Text(
              'Error cargando análisis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => ref.read(reportsProvider.notifier).fetchAnalytics(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(FinancialAnalyticsModel data) {
    final fin = data.financial;
    final beh = data.behavior;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOP CARDS (Financial Overview)
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Ingresos Totales',
                  value: _currency.format(fin.totalRevenue),
                  subtitle: 'Membresías: ${_currency.format(fin.membershipRevenue)} | POS: ${_currency.format(fin.posSalesRevenue)}',
                  icon: Icons.payments_outlined,
                  color: const Color(0xFF10B981), // Emerald green
                  badgeText: '+ Activo',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: 'Gastos de Nómina',
                  value: _currency.format(fin.payrollExpenses),
                  subtitle: 'Representa el ${fin.payrollRatioPercent.toStringAsFixed(1)}% de los ingresos',
                  icon: Icons.badge_outlined,
                  color: fin.payrollRatioPercent > 45 ? Colors.orangeAccent : const Color(0xFF3B82F6),
                  badgeText: fin.payrollRatioPercent > 45 ? 'Atención' : 'Normal',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: 'Gastos Operativos & Caja',
                  value: _currency.format(fin.operationalExpenses + fin.cashWithdrawals),
                  subtitle: 'Cuentas x pagar: ${_currency.format(fin.operationalExpenses)} | Retiros: ${_currency.format(fin.cashWithdrawals)}',
                  icon: Icons.account_balance_wallet_outlined,
                  color: const Color(0xFFF59E0B),
                  badgeText: 'Operación',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: 'Utilidad Neta',
                  value: _currency.format(fin.netProfit),
                  subtitle: 'Margen de beneficio: ${fin.profitMarginPercent.toStringAsFixed(1)}%',
                  icon: Icons.trending_up,
                  color: fin.netProfit >= 0 ? const Color(0xFF06B6D4) : Colors.redAccent,
                  badgeText: '${fin.profitMarginPercent.toStringAsFixed(0)}% Margen',
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 2. MIDDLE ROW: Payroll Efficiency & Peak Hours Behavior
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payroll & Expense Breakdown
              Expanded(
                flex: 5,
                child: _buildPayrollAndExpenseBreakdown(fin),
              ),
              const SizedBox(width: 20),
              // Peak Hours & Member Flow
              Expanded(
                flex: 6,
                child: _buildBehaviorAndPeakHours(beh),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 3. RETENTION STATS & WEEKDAYS
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _buildRetentionStatsCard(beh.membersStats),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 6,
                child: _buildWeekdayTrafficCard(beh.weekdays),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 4. ACTIONABLE BUSINESS RECOMMENDATIONS
          _buildRecommendationsSection(data.recommendations),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? badgeText,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF16191E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF23272F)),
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
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.white54),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollAndExpenseBreakdown(FinancialData fin) {
    const healthyPayrollMax = 40.0;
    final currentPayrollRatio = fin.payrollRatioPercent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16191E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF23272F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.pie_chart_outline, color: AppTheme.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Eficiencia de Nómina y Gastos',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (currentPayrollRatio > healthyPayrollMax)
                      ? Colors.orange.withValues(alpha: 0.15)
                      : const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  currentPayrollRatio > healthyPayrollMax
                      ? 'Nómina Alta (>40%)'
                      : 'Nómina Saludable',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: currentPayrollRatio > healthyPayrollMax ? Colors.orangeAccent : const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Ratio Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Nómina vs Ingresos Totales',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${currentPayrollRatio.toStringAsFixed(1)}% (Objetivo: 25% - 40%)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (currentPayrollRatio / 100).clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: const Color(0xFF23272F),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    currentPayrollRatio > healthyPayrollMax ? Colors.orangeAccent : const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFF23272F)),
          const SizedBox(height: 12),
          // Expense items
          _buildExpenseRow(
            label: 'Nómina Pagada / Aprobada',
            amount: fin.payrollExpenses,
            percent: fin.totalExpenses > 0 ? (fin.payrollExpenses / fin.totalExpenses) * 100 : 0,
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 10),
          _buildExpenseRow(
            label: 'Cuentas Operativas por Pagar',
            amount: fin.operationalExpenses,
            percent: fin.totalExpenses > 0 ? (fin.operationalExpenses / fin.totalExpenses) * 100 : 0,
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 10),
          _buildExpenseRow(
            label: 'Retiros / Gastos Menores de Caja',
            amount: fin.cashWithdrawals,
            percent: fin.totalExpenses > 0 ? (fin.cashWithdrawals / fin.totalExpenses) * 100 : 0,
            color: const Color(0xFFEC4899),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseRow({
    required String label,
    required double amount,
    required double percent,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ),
        Text(
          '${percent.toStringAsFixed(1)}%',
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
        const SizedBox(width: 16),
        Text(
          _currency.format(amount),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildBehaviorAndPeakHours(BehaviorData beh) {
    final peak = beh.peakHours;
    final total = (peak.morningCheckins + peak.afternoonCheckins + peak.eveningCheckins);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16191E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF23272F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.access_time_filled, color: Color(0xFF8B5CF6), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Distribución de Asistencias & Horas Pico',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${beh.totalCheckins} Asistencias',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Most Popular slot banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF201B2E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: Color(0xFFA78BFA), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Franja con mayor concurrencia: ${peak.busiestTimeSlot} (${peak.busiestPercentage.toStringAsFixed(0)}% del total)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Time Slot Bars
          _buildTimeSlotBar(
            title: 'Mañana (06:00 AM - 12:00 PM)',
            count: peak.morningCheckins,
            total: total,
            color: const Color(0xFF38BDF8),
            icon: Icons.wb_sunny_outlined,
          ),
          const SizedBox(height: 12),
          _buildTimeSlotBar(
            title: 'Tarde (12:00 PM - 06:00 PM)',
            count: peak.afternoonCheckins,
            total: total,
            color: const Color(0xFFFBBF24),
            icon: Icons.wb_twilight,
          ),
          const SizedBox(height: 12),
          _buildTimeSlotBar(
            title: 'Noche (06:00 PM - 12:00 AM)',
            count: peak.eveningCheckins,
            total: total,
            color: const Color(0xFFA78BFA),
            icon: Icons.nights_stay_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotBar({
    required String title,
    required int count,
    required int total,
    required Color color,
    required IconData icon,
  }) {
    final pct = total > 0 ? (count / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ),
            Text(
              '$count accesos (${(pct * 100).toStringAsFixed(0)}%)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: const Color(0xFF23272F),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildRetentionStatsCard(MembersStatsData stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16191E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF23272F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.people_alt_outlined, color: Color(0xFF06B6D4), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Retención & Clientes en Riesgo',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${stats.retentionRatePercent.toStringAsFixed(0)}% Retención',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF06B6D4)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  title: 'Miembros Activos',
                  value: '${stats.activeMembers}',
                  subtitle: 'Al día en suscripción',
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(
                  title: 'Vencidos < 30 días',
                  value: '${stats.expiredRecentMembers}',
                  subtitle: 'Candidatos de recuperación',
                  color: Colors.orangeAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStat(
                  title: 'Ingreso Prom. / Miembro',
                  value: _currency.format(stats.averageRevenuePerActiveMember),
                  subtitle: 'Gasto por cliente',
                  color: const Color(0xFF38BDF8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (stats.expiredRecentMembers > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orangeAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Hay ${stats.expiredRecentMembers} clientes con membresía vencida en los últimos 30 días. Envíales una oferta de reactivación.',
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ),
                  if (widget.onNavigateToCampaigns != null)
                    TextButton(
                      onPressed: widget.onNavigateToCampaigns,
                      child: const Text('Enviar Campaña', style: TextStyle(fontSize: 11, color: Colors.orangeAccent)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF101318),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF23272F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.white54)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildWeekdayTrafficCard(List<WeekdayCheckin> weekdays) {
    final maxCheckins = weekdays.fold<int>(0, (prev, e) => e.checkins > prev ? e.checkins : prev);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16191E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF23272F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_today, color: Color(0xFFF59E0B), size: 20),
              SizedBox(width: 8),
              Text(
                'Afluencia por Día de la Semana',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weekdays.map((wd) {
              final pct = maxCheckins > 0 ? (wd.checkins / maxCheckins) : 0.0;
              final height = (pct * 90).clamp(12.0, 90.0);
              final isHighest = wd.checkins == maxCheckins && maxCheckins > 0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${wd.checkins}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isHighest ? const Color(0xFFF59E0B) : Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: height,
                        decoration: BoxDecoration(
                          color: isHighest ? const Color(0xFFF59E0B) : const Color(0xFF2E3440),
                          borderRadius: BorderRadius.circular(6),
                          border: isHighest ? Border.all(color: const Color(0xFFFBBF24), width: 1.5) : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        wd.day,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isHighest ? FontWeight.bold : FontWeight.normal,
                          color: isHighest ? Colors.white : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(List<RecommendationItem> recs) {
    if (recs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF16191E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF23272F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lightbulb_outline, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recomendaciones del Asistente de Negocio',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Sugerencias basadas en el análisis algorítmico de tus finanzas y afluencia',
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Recommendation cards list
          ...recs.map((rec) => _buildRecommendationCard(rec)),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(RecommendationItem rec) {
    Color categoryColor;
    IconData categoryIcon;
    switch (rec.category) {
      case 'FINANCIAL':
        categoryColor = const Color(0xFF10B981);
        categoryIcon = Icons.account_balance_outlined;
        break;
      case 'OPERATIONS':
        categoryColor = const Color(0xFF8B5CF6);
        categoryIcon = Icons.schedule_outlined;
        break;
      case 'RETENTION':
        categoryColor = const Color(0xFF06B6D4);
        categoryIcon = Icons.loyalty_outlined;
        break;
      case 'SALES':
        categoryColor = const Color(0xFFF59E0B);
        categoryIcon = Icons.storefront_outlined;
        break;
      default:
        categoryColor = AppTheme.primary;
        categoryIcon = Icons.info_outline;
    }

    Color priorityColor;
    switch (rec.priority) {
      case 'HIGH':
        priorityColor = Colors.redAccent;
        break;
      case 'MEDIUM':
        priorityColor = Colors.orangeAccent;
        break;
      case 'LOW':
      default:
        priorityColor = Colors.white54;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101318),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF262A34)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(categoryIcon, color: categoryColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        rec.category,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: categoryColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Prioridad ${rec.priority}',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: priorityColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  rec.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  rec.description,
                  style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          if (rec.actionLabel != null) ...[
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                if (rec.category == 'RETENTION' && widget.onNavigateToCampaigns != null) {
                  widget.onNavigateToCampaigns!();
                } else if (rec.category == 'OPERATIONS' && widget.onNavigateToEmployees != null) {
                  widget.onNavigateToEmployees!();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sugerencia recibida: ${rec.title}'),
                      backgroundColor: const Color(0xFF1E222B),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: categoryColor.withValues(alpha: 0.2),
                foregroundColor: categoryColor,
                elevation: 0,
                side: BorderSide(color: categoryColor.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Text(rec.actionLabel!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}
