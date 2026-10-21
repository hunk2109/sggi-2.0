import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/receipt_printing_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../memberships/models/membership_model.dart';
import '../../settings/providers/settings_provider.dart';
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
  late DateTime _startDate;
  String _paymentMethod = 'pending'; // Por defecto pendiente según decisión del usuario
  bool _isLoading = false;

  bool get _hasActiveUnexpired =>
      widget.member.hasMembership &&
      !widget.member.isExpired;

  bool get _isExpiredRenewal =>
      widget.member.hasMembership &&
      widget.member.isExpired;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _selectedPlanId = widget.member.activePlanId;
  }

  Future<void> _handleSubmit() async {
    if (_hasActiveUnexpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por política de la empresa, solo se permite renovar la membresía una vez haya vencido.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final plans = ref.read(activeMembershipsProvider).value ?? [];

    String? planIdToUse = _selectedPlanId;
    if (_isExpiredRenewal) {
      planIdToUse = null;
      if (widget.member.activePlanId != null) {
        final found = plans.where((p) => p.id == widget.member.activePlanId).firstOrNull;
        planIdToUse = found?.id;
      }
      if (planIdToUse == null && widget.member.activePlanName != null) {
        final target = widget.member.activePlanName!.trim().toLowerCase();
        final found = plans.where((p) => p.name.trim().toLowerCase() == target).firstOrNull;
        planIdToUse = found?.id;
      }
      planIdToUse ??= plans.firstOrNull?.id;
    } else if (planIdToUse == null || planIdToUse.isEmpty) {
      if (widget.member.activePlanId != null) {
        final found = plans.where((p) => p.id == widget.member.activePlanId).firstOrNull;
        planIdToUse = found?.id;
      }
      if (planIdToUse == null && widget.member.activePlanName != null) {
        final target = widget.member.activePlanName!.trim().toLowerCase();
        final found = plans.where((p) => p.name.trim().toLowerCase() == target).firstOrNull;
        planIdToUse = found?.id;
      }
      planIdToUse ??= plans.firstOrNull?.id;
    }

    if (planIdToUse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un plan'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    final selectedPlan = plans.where((p) => p.id == planIdToUse).firstOrNull;

    if (_paymentMethod == 'credit_balance') {
      final price = selectedPlan?.price ?? 0;
      if (widget.member.creditBalance < price) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Saldo a favor insuficiente (Disponible: RD\$ ${widget.member.creditBalance.toStringAsFixed(2)}, Costo: RD\$ ${price.toStringAsFixed(2)})',
            ),
            backgroundColor: AppTheme.warning,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

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
      membershipId: planIdToUse,
      startDate: DateFormat('yyyy-MM-dd').format(_startDate),
      endDate: DateFormat('yyyy-MM-dd').format(calculatedEnd),
      paymentMethod: _paymentMethod,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result.success) {
        final isPending = _paymentMethod == 'pending';

        final messenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);

        if (!isPending) {
          final gymSettings = ref.read(gymSettingsProvider).settings;
          final originalPrice = selectedPlan?.price ?? 0;

          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1B2028),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              title: const Row(
                children: [
                  Icon(Icons.print_outlined, color: Colors.greenAccent, size: 24),
                  SizedBox(width: 10),
                  Text('¿Imprimir Recibo de Pago?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              content: Text(
                'Cobro de RD\$ ${originalPrice.toStringAsFixed(2)} registrado correctamente.\n\n¿Deseas abrir el diálogo de impresión de Windows para emitir el comprobante de ${_isExpiredRenewal ? "renovación" : "asignación"} del socio?',
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('No imprimir', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('Imprimir Recibo (Windows)'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ReceiptPrintingService.printMembershipReceipt(
                      memberName: widget.member.fullName,
                      displayCode: widget.member.displayCode,
                      planName: selectedPlan?.name ?? widget.member.activePlanName ?? 'Plan de Membresía',
                      amountPaid: originalPrice.toDouble(),
                      paymentMethod: _paymentMethod,
                      startDate: _startDate,
                      endDate: calculatedEnd,
                      gymSettings: gymSettings,
                    );
                  },
                ),
              ],
            ),
          );
        }

        if (!mounted) return;
        navigator.pop(true);

        messenger.clearSnackBars();
        if (result.warning != null && result.warning!.isNotEmpty) {
          messenger.showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              showCloseIcon: true,
              closeIconColor: Colors.white,
              width: 520,
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
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          messenger.showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              showCloseIcon: true,
              closeIconColor: Colors.white,
              width: 480,
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isPending
                          ? (_isExpiredRenewal
                              ? 'Renovación registrada. Factura pendiente generada para cobro en caja.'
                              : 'Membresía asignada. Factura pendiente generada para cobro en caja.')
                          : (_isExpiredRenewal
                              ? 'Membresía renovada y cobrada exitosamente.'
                              : 'Membresía asignada y cobrada exitosamente.'),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.success,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isExpiredRenewal ? 'Error al renovar membresía' : 'Error al asignar membresía'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membershipsAsync = ref.watch(activeMembershipsProvider);
    final plans = membershipsAsync.value ?? [];

    MembershipModel? activeMatchedPlan;
    if (_isExpiredRenewal && plans.isNotEmpty) {
      if (widget.member.activePlanId != null) {
        activeMatchedPlan = plans.where((p) => p.id == widget.member.activePlanId).firstOrNull;
      }
      if (activeMatchedPlan == null && widget.member.activePlanName != null && widget.member.activePlanName!.isNotEmpty) {
        final target = widget.member.activePlanName!.trim().toLowerCase();
        activeMatchedPlan = plans.where((p) => p.name.trim().toLowerCase() == target).firstOrNull;
        activeMatchedPlan ??= plans.where((p) => p.name.trim().toLowerCase().contains(target) || target.contains(p.name.trim().toLowerCase())).firstOrNull;
      }
      activeMatchedPlan ??= plans.firstOrNull;
    }

    final effectivePlanId = _isExpiredRenewal ? (activeMatchedPlan?.id ?? _selectedPlanId) : _selectedPlanId;
    final selectedPlan = plans.where((p) => p.id == effectivePlanId).firstOrNull;
    final num originalPrice = selectedPlan?.price ?? 0;

    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 580,
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
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
                      Text(
                        _hasActiveUnexpired
                            ? 'Membresía Activa y al Día'
                            : (_isExpiredRenewal ? 'Renovar Membresía' : 'Asignar Membresía'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isExpiredRenewal
                            ? 'Socio: ${widget.member.fullName} (${widget.member.displayCode}) • Plan anterior vencido'
                            : 'Socio: ${widget.member.fullName} (${widget.member.displayCode})',
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

              if (_hasActiveUnexpired) ...[
                // Banner informativo si está activa
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_outlined, color: Colors.amberAccent, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'El socio cuenta con una membresía activa (${widget.member.activePlanName ?? "Plan"})',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Fecha de vencimiento: ${widget.member.membershipEndDate != null ? DateFormat('dd/MM/yyyy').format(widget.member.membershipEndDate!) : "-"}\n\nPor política de la empresa, solo se permite renovar la membresía una vez haya vencido.\nSi desea asignar un plan diferente antes del vencimiento, debe cancelar el plan actual primero desde su ficha.',
                        style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white12),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              ] else ...[
                // Formulario de asignación / renovación
                if (_isExpiredRenewal) ...[
                  // Miembro con Membresía Vencida (Renovación): El plan está BLOQUEADO/FIJO
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.lock_outline, size: 20, color: Colors.blueAccent),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Plan a Renovar (Bloqueado)',
                                    style: TextStyle(fontSize: 11, color: Colors.white60, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    selectedPlan != null
                                        ? '${selectedPlan.name}  •  RD\$ ${selectedPlan.price.toStringAsFixed(2)} (${selectedPlan.durationLabel})'
                                        : (widget.member.activePlanName ?? 'Plan del Socio'),
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.shield_outlined, size: 12, color: Colors.blueAccent),
                                  SizedBox(width: 4),
                                  Text(
                                    'Plan Fijo',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blueAccent),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, size: 15, color: Colors.amberAccent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Por política de la empresa, no está permitido modificar el plan al renovar una membresía vencida. Si deseas asignarle un plan diferente, primero debes cancelar la membresía desde su ficha de socio.',
                                  style: TextStyle(fontSize: 11, color: Colors.amber.shade200, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Socio Sin Plan: Puede seleccionar libremente su plan
                  const Text('Seleccionar Plan *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),

                  membershipsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => Text('Error cargando planes: $e', style: const TextStyle(color: AppTheme.error)),
                    data: (plansList) {
                      if (plansList.isEmpty) {
                        return const Text('No hay planes activos configurados en el sistema.');
                      }
                      return DropdownButtonFormField<String>(
                        initialValue: _selectedPlanId,
                        hint: const Text('Selecciona un plan de membresía'),
                        items: plansList.map((p) {
                          return DropdownMenuItem(
                            value: p.id,
                            child: Text('${p.name} - RD\$ ${p.price.toStringAsFixed(2)} (${p.durationLabel})'),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedPlanId = v),
                      );
                    },
                  ),
                ],

                if (selectedPlan != null && selectedPlan.type == MembershipType.group) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.groups_outlined, color: Colors.purpleAccent, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Membresía Familiar / Grupal',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.purpleAccent),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Este plan convierte al socio en Titular de un Grupo Familiar. Permite registrar hasta ${selectedPlan.maxGroupCompanions ?? "varios"} familiares o acompañantes (${selectedPlan.pricePerCompanion != null && selectedPlan.pricePerCompanion! > 0 ? "RD\$ ${selectedPlan.pricePerCompanion!.toStringAsFixed(2)} c/u" : "incluidos en la tarifa"}).\nPodrás registrar y vincular a sus acompañantes desde el detalle del socio.',
                                style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                // Fecha de Inicio
                const Text('Fecha de Inicio de Vigencia', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),

                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 180)),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked;
                      });
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
                        Text(
                          DateFormat('dd/MM/yyyy').format(_startDate),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Row(
                          children: [
                            Text('Cambiar fecha', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            SizedBox(width: 6),
                            Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // RESUMEN DEL COSTO DEL PLAN
                if (selectedPlan != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15181E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Costo del Plan:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
                        Text(
                          'RD\$ ${originalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                if (widget.member.creditBalance > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: Colors.tealAccent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'El socio cuenta con Saldo a Favor de RD\$ ${widget.member.creditBalance.toStringAsFixed(2)}. Puedes usarlo como método de pago inmediato.',
                            style: const TextStyle(fontSize: 12, color: Colors.tealAccent, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Payment Method
                const Text('Cobro y Facturación', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMethod,
                  items: [
                    const DropdownMenuItem(
                      value: 'pending',
                      child: Text('Generar factura pendiente (Cobrar en caja / Pagos)'),
                    ),
                    if (widget.member.creditBalance > 0)
                      DropdownMenuItem(
                        value: 'credit_balance',
                        child: Text('Cobrar inmediatamente - Saldo a Favor (RD\$ ${widget.member.creditBalance.toStringAsFixed(2)} disp.)'),
                      ),
                    const DropdownMenuItem(
                      value: 'cash',
                      child: Text('Cobrar inmediatamente - Efectivo'),
                    ),
                    const DropdownMenuItem(
                      value: 'card',
                      child: Text('Cobrar inmediatamente - Tarjeta de Crédito/Débito'),
                    ),
                    const DropdownMenuItem(
                      value: 'transfer',
                      child: Text('Cobrar inmediatamente - Transferencia'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _paymentMethod = v ?? 'pending'),
                ),

                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _paymentMethod == 'pending'
                        ? Colors.orange.withValues(alpha: 0.08)
                        : _paymentMethod == 'credit_balance'
                            ? Colors.teal.withValues(alpha: 0.08)
                            : Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _paymentMethod == 'pending'
                          ? Colors.orange.withValues(alpha: 0.2)
                          : _paymentMethod == 'credit_balance'
                              ? Colors.teal.withValues(alpha: 0.3)
                              : Colors.green.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _paymentMethod == 'pending'
                            ? Icons.receipt_long_outlined
                            : _paymentMethod == 'credit_balance'
                                ? Icons.account_balance_wallet
                                : Icons.check_circle_outline,
                        size: 18,
                        color: _paymentMethod == 'pending'
                            ? Colors.orangeAccent
                            : _paymentMethod == 'credit_balance'
                                ? Colors.tealAccent
                                : Colors.greenAccent,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _paymentMethod == 'pending'
                              ? 'Se registrará el plan asignado con pago PENDIENTE. Podrás cobrarlo en la caja desde el módulo de Pagos o en la ficha del socio.'
                              : _paymentMethod == 'credit_balance'
                                  ? 'Se descontará el monto del plan directamente del Saldo a Favor del socio (RD\$ ${widget.member.creditBalance.toStringAsFixed(2)} disponible).'
                                  : 'El pago se registrará como COMPLETADO inmediatamente en la caja activa del cajero.',
                          style: TextStyle(
                            fontSize: 11,
                            color: _paymentMethod == 'pending'
                                ? Colors.orangeAccent
                                : _paymentMethod == 'credit_balance'
                                    ? Colors.tealAccent
                                    : Colors.greenAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                          : Text(_isExpiredRenewal ? 'Confirmar Renovación' : 'Confirmar Asignación'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
