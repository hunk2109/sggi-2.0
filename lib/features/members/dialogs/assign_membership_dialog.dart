import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../models/member_model.dart';
import '../providers/members_provider.dart';

class AssignMembershipDialog extends ConsumerStatefulWidget {
  final MemberModel member;

  const AssignMembershipDialog({super.key, required this.member});

  @override
  ConsumerState<AssignMembershipDialog> createState() => _AssignMembershipDialogState();
}

class _AssignMembershipDialogState extends ConsumerState<AssignMembershipDialog> {
  String? _selectedPlanId;
  DateTime _startDate = DateTime.now();
  String _paymentMethod = 'cash';
  bool _isLoading = false;

  Future<void> _handleSubmit() async {
    if (_selectedPlanId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un plan'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    setState(() => _isLoading = true);

    final plans = ref.read(activeMembershipsProvider).value ?? [];
    final selectedPlan = plans.where((p) => p.id == _selectedPlanId).firstOrNull;
    DateTime calculatedEnd;
    if (selectedPlan != null && selectedPlan.durationDays != null && selectedPlan.durationDays! > 0) {
      calculatedEnd = _startDate.add(Duration(days: selectedPlan.durationDays!));
    } else if (selectedPlan != null) {
      calculatedEnd = DateTime(_startDate.year, _startDate.month + selectedPlan.durationMonths, _startDate.day);
    } else {
      calculatedEnd = DateTime(_startDate.year, _startDate.month + 1, _startDate.day);
    }

    final result = await ref.read(membersProvider.notifier).assignMembership(
      memberId: widget.member.id,
      membershipId: _selectedPlanId!,
      startDate: DateFormat('yyyy-MM-dd').format(_startDate),
      endDate: DateFormat('yyyy-MM-dd').format(calculatedEnd),
      paymentMethod: _paymentMethod,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result.success) {
        Navigator.of(context).pop();
        if (result.warning != null && result.warning!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Membresía asignada internamente.\nAdvertencia de biométrico: ${result.warning!}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange.shade800,
              duration: const Duration(seconds: 7),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Membresía asignada y sincronizada correctamente'), backgroundColor: AppTheme.success),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al asignar membresía'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membershipsAsync = ref.watch(activeMembershipsProvider);

    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                      'Asignar / Renovar Plan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Socio: ${widget.member.fullName} (${widget.member.displayCode})',
                      style: const TextStyle(fontSize: 13, color: AppTheme.primaryLight),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),

            // Plan Selector
            const Text('Seleccionar Plan *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            membershipsAsync.when(
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              )),
              error: (e, _) => Text('Error cargando planes: $e', style: const TextStyle(color: AppTheme.error)),
              data: (plans) {
                if (plans.isEmpty) {
                  return const Text('No hay planes activos configurados en el sistema.');
                }
                return DropdownButtonFormField<String>(
                  initialValue: _selectedPlanId,
                  hint: const Text('Selecciona un plan de membresía'),
                  items: plans.map((p) {
                    return DropdownMenuItem(
                      value: p.id,
                      child: Text('${p.name} - RD\$ ${p.price.toStringAsFixed(2)} (${p.durationLabel})'),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedPlanId = v),
                );
              },
            ),

            const SizedBox(height: 18),

            // Start Date Picker
            const Text('Fecha de Inicio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (picked != null) {
                  setState(() => _startDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                    const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Payment Method
            const Text('Método de Pago', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Efectivo')),
                DropdownMenuItem(value: 'card', child: Text('Tarjeta de Crédito / Débito')),
                DropdownMenuItem(value: 'transfer', child: Text('Transferencia Bancaria')),
              ],
              onChanged: (v) => setState(() => _paymentMethod = v ?? 'cash'),
            ),

            const SizedBox(height: 28),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  child: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Confirmar y Asignar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
