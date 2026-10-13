import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../dialogs/employee_form_dialog.dart';
import '../models/employee_model.dart';
import '../models/payroll_model.dart';
import '../providers/employees_provider.dart';

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _currency = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$ ', decimalDigits: 2);
  final _dateOnly = DateFormat('dd/MM/yyyy');

  final List<String> _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateEmployee() {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const EmployeeFormDialog(),
    );
  }

  void _openEditEmployee(EmployeeModel employee) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EmployeeFormDialog(employeeToEdit: employee),
    );
  }

  Future<void> _confirmDeleteEmployee(EmployeeModel employee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E232B),
        title: const Text('Eliminar / Desactivar Empleado', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('¿Está seguro de eliminar a ${employee.fullName}? Si tiene registros asociados se desactivará.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(employeesProvider.notifier).deleteEmployee(employee.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Empleado procesado' : 'Error al eliminar empleado'),
            backgroundColor: success ? AppTheme.success : AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleGeneratePayroll() async {
    final state = ref.read(employeesProvider);
    final monthName = _months[(state.selectedMonth - 1).clamp(0, 11)];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E232B),
        title: const Text('Generar Nómina', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('¿Desea calcular y generar la nómina de todos los empleados activos para $monthName ${state.selectedYear}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Generar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(employeesProvider.notifier).generatePayroll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Nómina generada exitosamente' : 'Error al generar nómina'),
            backgroundColor: success ? AppTheme.success : AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleApprovePayroll(PayrollModel p) async {
    await ref.read(employeesProvider.notifier).approvePayroll(p.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nómina de ${p.employeeName} aprobada'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  Future<void> _handlePayPayroll(PayrollModel p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E232B),
        title: const Text('Confirmar Pago de Nómina', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('¿Marcar como pagado el monto de ${_currency.format(p.netSalary)} a ${p.employeeName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar Pago', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(employeesProvider.notifier).markPayrollPaid(p.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pago de ${p.employeeName} registrado'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header with Tabs
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF15181E),
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E232B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicator: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.badge_outlined, size: 18),
                      text: 'Personal & Empleados',
                    ),
                    Tab(
                      icon: Icon(Icons.payments_outlined, size: 18),
                      text: 'Nómina Mensual',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildEmployeesTab(),
              _buildPayrollTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeesTab() {
    final state = ref.watch(employeesProvider);
    final notifier = ref.read(employeesProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4 Metric Summary Cards
          Row(
            children: [
              _buildMetricCard(
                icon: Icons.badge_outlined,
                label: 'Total Empleados',
                value: '${state.totalEmployees}',
                color: Colors.blueAccent,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                icon: Icons.check_circle_outline,
                label: 'Empleados Activos',
                value: '${state.activeCount}',
                color: Colors.greenAccent,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                icon: Icons.fitness_center,
                label: 'Entrenadores Activos',
                value: '${state.trainersCount}',
                color: AppTheme.primary,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                icon: Icons.payments_outlined,
                label: 'Nómina Mensual Estimada',
                value: _currency.format(state.totalMonthlyPayroll),
                color: Colors.amber,
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Control Bar: Search, Filters, New Employee Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar empleado por nombre, teléfono o correo...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              notifier.setSearchQuery('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onChanged: (val) => notifier.setSearchQuery(val),
                ),
              ),
              const SizedBox(width: 12),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFilterChip('all', 'Todos', state.filter, (f) => notifier.setFilter(f)),
                  const SizedBox(width: 6),
                  _buildFilterChip('active', 'Activos', state.filter, (f) => notifier.setFilter(f)),
                  const SizedBox(width: 6),
                  _buildFilterChip('inactive', 'Inactivos', state.filter, (f) => notifier.setFilter(f)),
                ],
              ),

              const SizedBox(width: 12),

              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualizar lista',
                onPressed: () => notifier.loadEmployees(),
              ),
              const SizedBox(width: 6),

              ElevatedButton.icon(
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Nuevo Empleado'),
                onPressed: _openCreateEmployee,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Main Table Container
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.filteredEmployees.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.badge_outlined, size: 48, color: Colors.white24),
                              SizedBox(height: 10),
                              Text('No se encontraron empleados registrados', style: TextStyle(color: Colors.white54)),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: SizedBox(
                            width: double.infinity,
                            child: DataTable(
                              headingRowHeight: 44,
                              dataRowMinHeight: 48,
                              dataRowMaxHeight: 48,
                              columns: const [
                                DataColumn(label: Text('Empleado', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Puesto / Rol', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Teléfono', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Correo Electrónico', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Salario Mensual', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: state.filteredEmployees.map((e) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircleAvatar(
                                            radius: 13,
                                            backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                                            child: Text(
                                              e.firstName.isNotEmpty ? e.firstName[0].toUpperCase() : 'E',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(e.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(4)),
                                        child: Text(e.roleLabel, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                                      ),
                                    ),
                                    DataCell(Text(e.phone, style: const TextStyle(fontSize: 12))),
                                    DataCell(Text(e.email, style: const TextStyle(fontSize: 12, color: Colors.white60))),
                                    DataCell(Text(_currency.format(e.salary), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: e.isActive ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          e.isActive ? 'ACTIVO' : 'INACTIVO',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: e.isActive ? Colors.greenAccent : Colors.redAccent,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(e.isActive ? Icons.toggle_on : Icons.toggle_off, size: 22),
                                            tooltip: e.isActive ? 'Desactivar Empleado' : 'Activar Empleado',
                                            color: e.isActive ? Colors.greenAccent : Colors.white38,
                                            onPressed: () => notifier.toggleActive(e.id),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 18),
                                            tooltip: 'Editar Empleado',
                                            color: Colors.white70,
                                            onPressed: () => _openEditEmployee(e),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18),
                                            tooltip: 'Eliminar Empleado',
                                            color: Colors.redAccent.withValues(alpha: 0.7),
                                            onPressed: () => _confirmDeleteEmployee(e),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollTab() {
    final state = ref.watch(employeesProvider);
    final notifier = ref.read(employeesProvider.notifier);

    final pendingCount = state.payrolls.where((p) => !p.isPaid).length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Selector Bar & Generate Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2028),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: AppTheme.primary, size: 22),
                const SizedBox(width: 10),
                const Text('Período de Nómina:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 14),

                // Month Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252A33),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButton<int>(
                    value: state.selectedMonth,
                    underline: const SizedBox(),
                    dropdownColor: const Color(0xFF252A33),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: List.generate(12, (index) {
                      return DropdownMenuItem<int>(
                        value: index + 1,
                        child: Text(_months[index]),
                      );
                    }),
                    onChanged: (m) {
                      if (m != null) {
                        notifier.setPayrollPeriod(m, state.selectedYear);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),

                // Year Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252A33),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButton<int>(
                    value: state.selectedYear,
                    underline: const SizedBox(),
                    dropdownColor: const Color(0xFF252A33),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: [2025, 2026, 2027].map((y) {
                      return DropdownMenuItem<int>(
                        value: y,
                        child: Text('$y'),
                      );
                    }).toList(),
                    onChanged: (y) {
                      if (y != null) {
                        notifier.setPayrollPeriod(state.selectedMonth, y);
                      }
                    },
                  ),
                ),

                const Spacer(),

                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Recargar Nóminas',
                  onPressed: () => notifier.loadPayrolls(),
                ),
                const SizedBox(width: 8),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: state.isGeneratingPayroll
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.calculate_outlined, size: 18),
                  label: Text(
                    state.isGeneratingPayroll ? 'Generando...' : 'Generar Nómina del Mes',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: state.isGeneratingPayroll ? null : _handleGeneratePayroll,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4 Metric Cards for Payroll
          Row(
            children: [
              _buildMetricCard(
                icon: Icons.payments,
                label: 'Total Neto a Pagar',
                value: _currency.format(state.payrollTotalNet),
                color: Colors.greenAccent,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                icon: Icons.people_outline,
                label: 'Empleados en Nómina',
                value: '${state.payrolls.length}',
                color: Colors.blueAccent,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                icon: Icons.task_alt,
                label: 'Nóminas Pagadas',
                value: '${state.payrollPaidCount}',
                color: Colors.tealAccent,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                icon: Icons.pending_actions,
                label: 'Pendientes de Pago',
                value: '$pendingCount',
                color: pendingCount > 0 ? Colors.amber : Colors.white60,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Payroll Table Container
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.payrolls.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.receipt_long_outlined, size: 48, color: Colors.white24),
                              const SizedBox(height: 10),
                              const Text('No hay registros de nómina generados para este período', style: TextStyle(color: Colors.white54)),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.calculate, size: 18),
                                label: const Text('Generar Nómina Ahora'),
                                onPressed: _handleGeneratePayroll,
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: SizedBox(
                            width: double.infinity,
                            child: DataTable(
                              headingRowHeight: 44,
                              dataRowMinHeight: 48,
                              dataRowMaxHeight: 48,
                              columns: const [
                                DataColumn(label: Text('Empleado', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Salario Base', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Bonos', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Deducciones', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Neto a Pagar', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Cuenta / Banco', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: state.payrolls.map((p) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircleAvatar(
                                            radius: 13,
                                            backgroundColor: Colors.blueAccent.withValues(alpha: 0.2),
                                            child: Text(
                                              p.employeeName.isNotEmpty ? p.employeeName[0].toUpperCase() : 'E',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(p.employeeName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                              if (p.employeeRole.isNotEmpty)
                                                Text(p.employeeRole, style: const TextStyle(fontSize: 10, color: Colors.white54)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text(_currency.format(p.baseSalary), style: const TextStyle(fontSize: 12))),
                                    DataCell(Text(_currency.format(p.bonuses), style: const TextStyle(fontSize: 12, color: Colors.greenAccent))),
                                    DataCell(Text(_currency.format(p.deductions), style: const TextStyle(fontSize: 12, color: Colors.redAccent))),
                                    DataCell(Text(_currency.format(p.netSalary), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber))),
                                    DataCell(
                                      Text(
                                        p.bank != null && p.accountNumber != null
                                            ? '${p.bank} - ${p.accountNumber}'
                                            : 'Efectivo / No reg.',
                                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                                      ),
                                    ),
                                    DataCell(_buildPayrollStatusBadge(p)),
                                    DataCell(_buildPayrollActions(p)),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollStatusBadge(PayrollModel p) {
    Color bg;
    Color fg;
    String label;

    if (p.isPaid) {
      bg = Colors.green.withValues(alpha: 0.15);
      fg = Colors.greenAccent;
      label = 'PAGADO';
    } else if (p.isApproved) {
      bg = Colors.blue.withValues(alpha: 0.15);
      fg = Colors.blueAccent;
      label = 'APROBADO';
    } else {
      bg = Colors.amber.withValues(alpha: 0.15);
      fg = Colors.amber;
      label = 'BORRADOR';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildPayrollActions(PayrollModel p) {
    if (p.isPaid) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.greenAccent),
          const SizedBox(width: 4),
          Text(
            p.paymentDate != null ? _dateOnly.format(p.paymentDate!) : 'Pagado',
            style: const TextStyle(fontSize: 11, color: Colors.greenAccent),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!p.isApproved)
          IconButton(
            icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
            tooltip: 'Aprobar Nómina',
            color: Colors.blueAccent,
            onPressed: () => _handleApprovePayroll(p),
          ),
        IconButton(
          icon: const Icon(Icons.paid_outlined, size: 18),
          tooltip: 'Marcar como Pagado',
          color: Colors.greenAccent,
          onPressed: () => _handlePayPayroll(p),
        ),
      ],
    );
  }

  Widget _buildMetricCard({required IconData icon, required String label, required String value, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2028),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, String activeFilter, Function(String) onSelect) {
    final isSelected = activeFilter == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.white70)),
      selected: isSelected,
      selectedColor: AppTheme.primary,
      backgroundColor: const Color(0xFF1F242C),
      onSelected: (_) => onSelect(key),
    );
  }
}
