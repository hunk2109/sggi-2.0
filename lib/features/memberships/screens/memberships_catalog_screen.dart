import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../dialogs/membership_form_dialog.dart';
import '../models/membership_model.dart';
import '../providers/memberships_catalog_provider.dart';

class MembershipsCatalogScreen extends ConsumerStatefulWidget {
  const MembershipsCatalogScreen({super.key});

  @override
  ConsumerState<MembershipsCatalogScreen> createState() => _MembershipsCatalogScreenState();
}

class _MembershipsCatalogScreenState extends ConsumerState<MembershipsCatalogScreen> {
  final _searchController = TextEditingController();
  static final _currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: 'RD\$ ', decimalDigits: 2);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreatePlanDialog() {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const MembershipFormDialog(),
    );
  }

  void _openEditPlanDialog(MembershipModel membership) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MembershipFormDialog(membershipToEdit: membership),
    );
  }

  Future<void> _confirmDeletePlan(MembershipModel membership) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E232B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('Eliminar Plan de Membresía', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Está seguro de eliminar el plan "${membership.name}"?',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 10),
              const Text(
                'Nota: Si existen socios que ya tienen asignado este plan en su historial, el sistema lo marcará como INACTIVO de forma segura para proteger los registros contables y de auditoría.',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar Plan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await ref.read(membershipsCatalogProvider.notifier).deleteMembership(membership.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Plan eliminado o desactivado correctamente' : 'Error al procesar la eliminación'),
            backgroundColor: ok ? AppTheme.success : AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(membershipsCatalogProvider);
    final notifier = ref.read(membershipsCatalogProvider.notifier);
    final plans = state.filteredMemberships;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Control Bar: Búsqueda, Filtros y Botón Nuevo Plan
          Row(
            children: [
              // Search Input
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar plan por nombre o beneficio...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              notifier.setSearch('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onChanged: (val) {
                    setState(() {});
                    notifier.setSearch(val);
                  },
                ),
              ),
              const SizedBox(width: 14),

              // Filter Chips
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFilterChip('all', 'Todos (${state.memberships.length})', state.filter, (f) => notifier.setFilter(f)),
                  const SizedBox(width: 6),
                  _buildFilterChip('active', 'Activos (${state.memberships.where((m) => m.isActive).length})', state.filter, (f) => notifier.setFilter(f)),
                  const SizedBox(width: 6),
                  _buildFilterChip('inactive', 'Inactivos (${state.memberships.where((m) => !m.isActive).length})', state.filter, (f) => notifier.setFilter(f)),
                ],
              ),
              const SizedBox(width: 14),

              // Refresh Button
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Recargar planes',
                onPressed: () => notifier.loadMemberships(),
              ),
              const SizedBox(width: 8),

              // New Plan Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                icon: const Icon(Icons.add_card, size: 18),
                label: const Text('Nuevo Plan de Membresía', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _openCreatePlanDialog,
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Main Plans View
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : plans.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.card_membership_outlined, size: 56, color: Colors.white24),
                            const SizedBox(height: 14),
                            const Text(
                              'No se encontraron planes de membresía',
                              style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Comienza creando el primer plan para habilitar la inscripción de socios.',
                              style: TextStyle(fontSize: 12, color: Colors.white38),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Crear Primer Plan'),
                              onPressed: _openCreatePlanDialog,
                            ),
                          ],
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          // Grid responsivo según el ancho disponible
                          final width = constraints.maxWidth;
                          final crossAxisCount = width > 1350 ? 3 : (width > 880 ? 2 : 1);

                          return GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.35,
                            ),
                            itemCount: plans.length,
                            itemBuilder: (context, index) {
                              final plan = plans[index];
                              return _buildPlanCard(plan);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(MembershipModel plan) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B2028),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: plan.isActive ? AppTheme.primary.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.08),
          width: plan.isActive ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header with badges
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: plan.isActive ? AppTheme.primary.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              border: const Border(bottom: BorderSide(color: Color(0xFF282F3B))),
            ),
            child: Row(
              children: [
                // Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: plan.type == MembershipType.group
                        ? Colors.purple.withValues(alpha: 0.2)
                        : Colors.blueAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        plan.type == MembershipType.group ? Icons.groups : Icons.person,
                        size: 13,
                        color: plan.type == MembershipType.group ? Colors.purpleAccent : Colors.lightBlueAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        plan.type.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: plan.type == MembershipType.group ? Colors.purpleAccent : Colors.lightBlueAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Recurrence Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: plan.isRecurring ? Colors.teal.withValues(alpha: 0.15) : Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    plan.isRecurring ? 'RECURRENTE' : 'PLAZO FIJO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: plan.isRecurring ? Colors.tealAccent : Colors.amberAccent,
                    ),
                  ),
                ),

                const Spacer(),

                // Active Switch / Badge
                InkWell(
                  onTap: () => ref.read(membershipsCatalogProvider.notifier).toggleActive(plan.id, plan.isActive),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: plan.isActive ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: plan.isActive ? Colors.greenAccent.withValues(alpha: 0.4) : Colors.redAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 3,
                          backgroundColor: plan.isActive ? Colors.greenAccent : Colors.redAccent,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          plan.isActive ? 'ACTIVO' : 'INACTIVO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: plan.isActive ? Colors.greenAccent : Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Card Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plan Name
                  Text(
                    plan.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),

                  // Price & Duration
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _currencyFormat.format(plan.price),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.greenAccent,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '/ ${plan.durationLabel}',
                        style: const TextStyle(fontSize: 12, color: Colors.white60, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),

                  // Companion Info if group
                  if (plan.type == MembershipType.group && plan.pricePerCompanion != null && plan.pricePerCompanion! > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '+ ${_currencyFormat.format(plan.pricePerCompanion!)} por acompañante (máx. ${plan.maxGroupCompanions ?? 2})',
                      style: const TextStyle(fontSize: 11, color: Colors.purpleAccent, fontWeight: FontWeight.w500),
                    ),
                  ],

                  if (plan.description != null && plan.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      plan.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Benefits list
                  Expanded(
                    child: plan.benefits.isEmpty
                        ? const Text('Sin beneficios registrados', style: TextStyle(fontSize: 11, color: Colors.white30, fontStyle: FontStyle.italic))
                        : SingleChildScrollView(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: plan.benefits.map((b) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check, size: 11, color: Colors.greenAccent),
                                      const SizedBox(width: 4),
                                      Text(
                                        b,
                                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Card Footer Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF282F3B))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Toggle active button
                IconButton(
                  icon: Icon(
                    plan.isActive ? Icons.visibility : Icons.visibility_off,
                    size: 18,
                    color: plan.isActive ? Colors.white60 : Colors.redAccent,
                  ),
                  tooltip: plan.isActive ? 'Desactivar plan' : 'Activar plan',
                  onPressed: () => ref.read(membershipsCatalogProvider.notifier).toggleActive(plan.id, plan.isActive),
                ),
                // Edit button
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueAccent),
                  tooltip: 'Modificar Plan',
                  onPressed: () => _openEditPlanDialog(plan),
                ),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                  tooltip: 'Eliminar Plan',
                  onPressed: () => _confirmDeletePlan(plan),
                ),
              ],
            ),
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
}
