import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../models/member_model.dart';
import '../providers/members_provider.dart';
import '../dialogs/new_member_dialog.dart';
import '../dialogs/assign_membership_dialog.dart';

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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const NewMemberDialog(),
    );
  }

  void _openAssignMembershipDialog(MemberModel member) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AssignMembershipDialog(member: member),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(membersProvider);
    final notifier = ref.read(membersProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Directorio de Socios',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${state.total} socios',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refrescar'),
                    onPressed: () => notifier.loadMembers(page: state.currentPage),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('Nuevo Socio (F2)'),
                    onPressed: _openNewMemberDialog,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Search and Filters Bar
          Row(
            children: [
              // Search Input
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      if (val.isEmpty) notifier.search('');
                    },
                    onSubmitted: (val) => notifier.search(val),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre, código (2026-XXXX) o cédula...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                notifier.search('');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Filter Chips
              _buildFilterChip('all', 'Todos', state.filter, (f) => notifier.setFilter(f)),
              const SizedBox(width: 8),
              _buildFilterChip('active', 'Al Día', state.filter, (f) => notifier.setFilter(f)),
              const SizedBox(width: 8),
              _buildFilterChip('expired', 'Vencidos / Sin Plan', state.filter, (f) => notifier.setFilter(f)),
              const SizedBox(width: 8),
              _buildFilterChip('pending', 'Pendiente de Pago', state.filter, (f) => notifier.setFilter(f)),
            ],
          ),

          const SizedBox(height: 16),

          // High Density Data Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
              ),
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.filteredMembers.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_outline, size: 48, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('No se encontraron socios', style: TextStyle(color: Colors.grey, fontSize: 16)),
                            ],
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SingleChildScrollView(
                            child: DataTable(
                              headingRowHeight: 44,
                              dataRowMinHeight: 52,
                              dataRowMaxHeight: 52,
                              columnSpacing: 20,
                              headingRowColor: WidgetStateProperty.all(
                                const Color(0xFF1B2028),
                              ),
                              columns: const [
                                DataColumn(label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Nombre del Socio', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Contacto / Teléfono', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Plan Asignado', style: TextStyle(fontWeight: FontWeight.bold))),
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

                                    // Full Name
                                    DataCell(
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                                            child: Text(
                                              member.firstName.isNotEmpty ? member.firstName[0].toUpperCase() : 'S',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            member.fullName,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Contact
                                    DataCell(
                                      Text(
                                        member.phone ?? member.email ?? '—',
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
                                            : '—',
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
                                          IconButton(
                                            icon: const Icon(Icons.credit_card, size: 18),
                                            tooltip: 'Asignar / Renovar Plan',
                                            color: AppTheme.primary,
                                            onPressed: () => _openAssignMembershipDialog(member),
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

          const SizedBox(height: 14),

          // Pagination Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mostrando página ${state.currentPage} de ${state.totalPages}  (${state.total} socios en total)',
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
