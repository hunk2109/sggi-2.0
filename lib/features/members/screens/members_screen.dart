import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_table_scroll_view.dart';
import '../dialogs/assign_membership_dialog.dart';
import '../dialogs/member_detail_dialog.dart';
import '../dialogs/new_member_dialog.dart';
import '../dialogs/pay_fee_dialog.dart';
import '../models/member_model.dart';
import '../providers/members_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../../core/constants/app_permissions.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openNewMemberDialog() {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const NewMemberDialog(),
    );
  }

  void _openEditMemberDialog(MemberModel member) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => NewMemberDialog(memberToEdit: member),
    );
  }

  void _openAssignMembershipDialog(MemberModel member) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AssignMembershipDialog(member: member),
    );
  }

  void _openMemberDetail(MemberModel member) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => MemberDetailDialog(member: member),
    );
  }

  Future<void> _openCollectPendingPayment(MemberModel member) async {
    final s = ref.read(memberServiceProvider);
    final history = await s.getPaymentHistory(member.id);
    final payments = (history['payments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final pending = payments.firstWhere(
      (p) => p['status']?.toString().toLowerCase() == 'pending',
      orElse: () => <String, dynamic>{},
    );

    if (pending.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró cobro pendiente para este socio.')),
        );
      }
      return;
    }

    final paymentId = pending['id']?.toString() ?? '';
    final amount = double.tryParse(pending['amount']?.toString() ?? '') ?? 0.0;

    if (mounted) {
      showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PayFeeDialog(
          member: member,
          paymentId: paymentId,
          initialAmount: amount,
          concept: 'Cuota de Membresía',
          onPaymentSuccess: () {
            ref.read(membersProvider.notifier).loadMembers();
          },
        ),
      );
    }
  }

  Future<void> _confirmDeleteMember(MemberModel member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E232B),
        title: const Text('Eliminar Socio', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('¿Está seguro de eliminar a ${member.fullName}? Esta acción no se puede deshacer.'),
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
      final success = await ref.read(membersProvider.notifier).deleteMember(member.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Socio eliminado' : 'Error al eliminar socio'),
            backgroundColor: success ? AppTheme.success : AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(membersProvider);
    final notifier = ref.read(membersProvider.notifier);
    final authState = ref.watch(authProvider);
    final canCreate = authState.hasPermission(AppPermissions.membersCreate);
    final canEdit = authState.hasPermission(AppPermissions.membersEdit);
    final canDelete = authState.hasPermission(AppPermissions.membersDelete);
    final canAssign = authState.hasPermission(AppPermissions.membersAssignMembership);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Control Bar: Search, Filters, New Member Button (Responsive)
          Row(
            children: [
              // Search Input
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, código o teléfono...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              notifier.search('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onChanged: (val) {
                    setState(() {});
                    notifier.search(val);
                  },
                  onSubmitted: (val) => notifier.search(val),
                ),
              ),
              const SizedBox(width: 12),

              // Filter Chips
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFilterChip('all', 'Todos', state.filter, (f) => notifier.setFilter(f)),
                  const SizedBox(width: 6),
                  _buildFilterChip('active', 'Al Día', state.filter, (f) => notifier.setFilter(f)),
                  const SizedBox(width: 6),
                  _buildFilterChip('expired', 'Vencidos', state.filter, (f) => notifier.setFilter(f)),
                  const SizedBox(width: 6),
                  _buildFilterChip('pending', 'Pendientes', state.filter, (f) => notifier.setFilter(f)),
                ],
              ),

              const SizedBox(width: 12),

              // Quick Refresh
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualizar lista',
                onPressed: () => notifier.loadMembers(page: state.currentPage),
              ),
              if (canCreate) ...[
                const SizedBox(width: 6),
                // New Member Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Nuevo Socio'),
                  onPressed: _openNewMemberDialog,
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Main Data Table Container
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
                  : state.filteredMembers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 48, color: Colors.white.withValues(alpha: 0.3)),
                              const SizedBox(height: 12),
                              const Text('No se encontraron socios', style: TextStyle(color: Colors.white60)),
                            ],
                          ),
                        )
                      : AppTableScrollView(
                          child: DataTable(
                                    headingRowHeight: 46,
                                    dataRowMinHeight: 50,
                                    dataRowMaxHeight: 56,
                                    columnSpacing: 20,
                                    horizontalMargin: 16,
                                    columns: const [
                                      DataColumn(label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Nombre y Apellidos', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Teléfono / Contacto', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Plan Activo', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Vencimiento', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: state.filteredMembers.map((member) {
                                      return DataRow(
                                        cells: [
                                          // Code
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.black26,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                member.displayCode,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                              ),
                                            ),
                                          ),

                                          // Full Name (Clickable with ellipsis)
                                          DataCell(
                                            InkWell(
                                              borderRadius: BorderRadius.circular(6),
                                              onTap: () => _openMemberDetail(member),
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 4),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 13,
                                                      backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                                                      child: Text(
                                                        member.firstName.isNotEmpty ? member.firstName[0].toUpperCase() : 'S',
                                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      member.fullName,
                                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, decoration: TextDecoration.underline, decorationColor: Colors.white24),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),

                                          // Contact
                                          DataCell(
                                            Text(
                                              member.phone ?? member.email ?? '-',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context).textTheme.bodySmall?.color,
                                              ),
                                            ),
                                          ),

                                          // Plan
                                          DataCell(
                                            Text(
                                              member.activePlanName ?? 'Ninguno',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: member.activePlanName != null ? Colors.white : Colors.white38,
                                              ),
                                            ),
                                          ),

                                          // Expiration Date
                                          DataCell(
                                            Text(
                                              member.membershipEndDate != null
                                                  ? DateFormat('dd/MM/yyyy').format(member.membershipEndDate!)
                                                  : '-',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ),

                                          // Status Badge
                                          DataCell(_buildStatusBadge(member)),

                                          // Actions
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (member.hasPendingPayment)
                                                  IconButton(
                                                    icon: const Icon(Icons.point_of_sale, size: 18),
                                                    tooltip: 'Cobrar Cuota Pendiente',
                                                    color: AppTheme.success,
                                                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                                    padding: const EdgeInsets.all(4),
                                                    onPressed: () => _openCollectPendingPayment(member),
                                                  ),
                                                IconButton(
                                                  icon: const Icon(Icons.visibility_outlined, size: 18),
                                                  tooltip: 'Ficha Completa',
                                                  color: Colors.blueAccent,
                                                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                                  padding: const EdgeInsets.all(4),
                                                  onPressed: () => _openMemberDetail(member),
                                                ),
                                                if (canAssign)
                                                  Builder(
                                                    builder: (context) {
                                                      final bool canAct = !member.hasMembership || member.isExpired;
                                                      final String tooltip = !member.hasMembership
                                                          ? 'Asignar Membresía'
                                                          : (member.isExpired
                                                              ? 'Renovar Membresía (Vencida)'
                                                              : 'Membresía activa y al día (Solo renovable al vencer)');
                                                      return IconButton(
                                                        icon: Icon(
                                                          member.hasMembership ? Icons.autorenew : Icons.credit_card,
                                                          size: 18,
                                                        ),
                                                        tooltip: tooltip,
                                                        color: canAct ? AppTheme.primary : Colors.white24,
                                                        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                                        padding: const EdgeInsets.all(4),
                                                        onPressed: canAct ? () => _openAssignMembershipDialog(member) : null,
                                                      );
                                                    },
                                                  ),
                                                if (canEdit)
                                                  IconButton(
                                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                                    tooltip: 'Editar Datos',
                                                    color: Colors.white70,
                                                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                                    padding: const EdgeInsets.all(4),
                                                    onPressed: () => _openEditMemberDialog(member),
                                                  ),
                                                if (canDelete)
                                                  IconButton(
                                                    icon: const Icon(Icons.delete_outline, size: 18),
                                                    tooltip: 'Eliminar Socio',
                                                    color: Colors.redAccent.withValues(alpha: 0.7),
                                                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                                    padding: const EdgeInsets.all(4),
                                                    onPressed: () => _confirmDeleteMember(member),
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

          const SizedBox(height: 12),

          // Pagination Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Página ${state.currentPage} de ${state.totalPages}  (${state.total} socios en total)',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: state.currentPage > 1 ? () => notifier.loadMembers(page: state.currentPage - 1) : null,
                    child: const Text('Anterior'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: state.currentPage < state.totalPages ? () => notifier.loadMembers(page: state.currentPage + 1) : null,
                    child: const Text('Siguiente'),
                  ),
                ],
              ),
            ],
          ),
        ],
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

  Widget _buildStatusBadge(MemberModel member) {
    Color bg;
    Color fg;
    String label = member.statusLabel;

    switch (label) {
      case 'Al Día':
        bg = AppTheme.success.withValues(alpha: 0.15);
        fg = Colors.greenAccent;
        break;
      case 'Vencido':
        bg = AppTheme.error.withValues(alpha: 0.15);
        fg = Colors.redAccent;
        break;
      case 'Pago Pendiente':
        bg = AppTheme.warning.withValues(alpha: 0.15);
        fg = Colors.orangeAccent;
        break;
      default:
        bg = Colors.white.withValues(alpha: 0.08);
        fg = Colors.white60;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
