import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/receipt_printing_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../memberships/models/promotion_model.dart';
import '../../memberships/services/promotion_service.dart';
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
  int _startDateOption = 0; // 0: Desde vencimiento (si aplica) o desde hoy, 1: Desde hoy, 2: Personalizado

  // Cupones y promociones
  final _couponController = TextEditingController();
  bool _isValidatingCoupon = false;
  PromotionValidationResult? _couponResult;
  String? _appliedPromoCode;

  bool get _hasActiveUnexpired =>
      widget.member.hasMembership &&
      widget.member.membershipEndDate != null &&
      widget.member.membershipEndDate!.isAfter(DateTime.now());

  @override
  void initState() {
    super.initState();
    if (_hasActiveUnexpired) {
      _startDate = widget.member.membershipEndDate!;
      _startDateOption = 0; // Continuar desde vencimiento actual
    } else {
      _startDate = DateTime.now();
      _startDateOption = 1; // Desde hoy
    }
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _validateCoupon([String? explicitCode]) async {
    final code = (explicitCode ?? _couponController.text).trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un código de cupón'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    _couponController.text = code;
    setState(() => _isValidatingCoupon = true);

    final result = await ref.read(promotionServiceProvider).validatePromotion(code);
    if (mounted) {
      setState(() {
        _isValidatingCoupon = false;
        _couponResult = result;
        if (result.valid) {
          _appliedPromoCode = result.code ?? code;
        } else {
          _appliedPromoCode = null;
        }
      });
    }
  }

  void _clearCoupon() {
    setState(() {
      _couponController.clear();
      _couponResult = null;
      _appliedPromoCode = null;
    });
  }

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
      promotionCode: _appliedPromoCode,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result.success) {
        final isPending = _paymentMethod == 'pending';
        final discountMsg = _appliedPromoCode != null && _couponResult != null && _couponResult!.valid
            ? ' con ${_couponResult!.discount}% de descuento ($_appliedPromoCode)'
            : '';

        final messenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);

        if (!isPending) {
          final gymSettings = ref.read(gymSettingsProvider).settings;
          final originalPrice = selectedPlan?.price ?? 0;
          final discountPercent = (_couponResult != null && _couponResult!.valid) ? _couponResult!.discount : 0;
          final finalPrice = originalPrice * (1 - (discountPercent / 100));

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
                'Cobro de RD\$ ${finalPrice.toStringAsFixed(2)} registrado correctamente.\n\n¿Deseas abrir el diálogo de impresión de Windows para emitir el comprobante del socio?',
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
                      planName: selectedPlan?.name ?? 'Plan de Membresía',
                      amountPaid: finalPrice.toDouble(),
                      paymentMethod: _paymentMethod,
                      startDate: _startDate,
                      endDate: calculatedEnd,
                      promotionCode: _appliedPromoCode,
                      discountPercentage: discountPercent > 0 ? discountPercent : null,
                      originalPlanPrice: originalPrice > 0 ? originalPrice.toDouble() : null,
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

        if (result.warning != null && result.warning!.isNotEmpty) {
          messenger.showSnackBar(
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
          messenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isPending
                          ? 'Membresía asignada$discountMsg. Factura pendiente generada para cobro.'
                          : 'Membresía asignada$discountMsg y cobrada exitosamente.',
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
          const SnackBar(content: Text('Error al asignar membresía'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membershipsAsync = ref.watch(activeMembershipsProvider);
    final promotionsAsync = ref.watch(activePromotionsProvider);

    final plans = membershipsAsync.value ?? [];
    final selectedPlan = plans.where((p) => p.id == _selectedPlanId).firstOrNull;

    num originalPrice = selectedPlan?.price ?? 0;
    num discountPercent = (_couponResult != null && _couponResult!.valid) ? _couponResult!.discount : 0;
    num discountAmount = (originalPrice * discountPercent) / 100;
    num finalPrice = originalPrice - discountAmount;

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

              const SizedBox(height: 18),

              // Fecha de Inicio & Renovación Anticipada
              const Text('Fecha de Inicio de Vigencia', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),

              if (_hasActiveUnexpired) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: Colors.blueAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'El socio tiene un plan vigente hasta el ${DateFormat('dd/MM/yyyy').format(widget.member.membershipEndDate!)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueAccent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text('Extender desde vencimiento (${DateFormat('dd/MM').format(widget.member.membershipEndDate!)})'),
                            selected: _startDateOption == 0,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _startDateOption = 0;
                                  _startDate = widget.member.membershipEndDate!;
                                });
                              }
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Iniciar desde hoy'),
                            selected: _startDateOption == 1,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _startDateOption = 1;
                                  _startDate = DateTime.now();
                                });
                              }
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Personalizada'),
                            selected: _startDateOption == 2,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _startDateOption = 2);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

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
                      _startDateOption = 2; // Personalizada
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

              // SECCIÓN CUPÓN O PROMOCIÓN (SOLO PAGOS DE MEMBRESÍA)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cupón / Descuento Promocional', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  if (_appliedPromoCode != null)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: Colors.redAccent,
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.close, size: 14),
                      label: const Text('Quitar cupón', style: TextStyle(fontSize: 11)),
                      onPressed: _clearCoupon,
                    ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _couponController,
                      textCapitalization: TextCapitalization.characters,
                      enabled: _appliedPromoCode == null,
                      decoration: InputDecoration(
                        hintText: 'Ej. PROMO10, VERANO20...',
                        prefixIcon: const Icon(Icons.confirmation_number_outlined, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        suffixIcon: _isValidatingCoupon
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            : null,
                      ),
                      onSubmitted: (_) => _validateCoupon(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      backgroundColor: _appliedPromoCode != null ? Colors.green.shade700 : AppTheme.primary,
                    ),
                    icon: Icon(_appliedPromoCode != null ? Icons.check : Icons.local_offer_outlined, size: 16),
                    label: Text(_appliedPromoCode != null ? 'Aplicado' : 'Validar'),
                    onPressed: _isValidatingCoupon || _appliedPromoCode != null ? null : () => _validateCoupon(),
                  ),
                ],
              ),

              // Sugerencias de cupones activos del gimnasio
              promotionsAsync.when(
                data: (promos) {
                  if (promos.isEmpty || _appliedPromoCode != null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: promos.map((p) {
                        return ActionChip(
                          avatar: const Icon(Icons.discount_outlined, size: 14, color: Colors.amberAccent),
                          label: Text(
                            '${p.code} (-${p.discountPercentage}%)',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: const Color(0xFF1E232B),
                          side: BorderSide(color: Colors.amberAccent.withValues(alpha: 0.3)),
                          onPressed: () => _validateCoupon(p.code),
                        );
                      }).toList(),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),

              // Feedback de validación
              if (_couponResult != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _couponResult!.valid
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _couponResult!.valid
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _couponResult!.valid ? Icons.check_circle_outline : Icons.error_outline,
                        size: 16,
                        color: _couponResult!.valid ? Colors.greenAccent : Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _couponResult!.valid
                              ? '¡Cupón "$_appliedPromoCode" válido! -${_couponResult!.discount}% de descuento aplicado a la cuota.'
                              : _couponResult!.message,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _couponResult!.valid ? Colors.greenAccent : Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // RESUMEN FINANCIERO DEL PAGO
              if (selectedPlan != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15181E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Precio original del plan:', style: TextStyle(fontSize: 12, color: Colors.white70)),
                          Text(
                            'RD\$ ${originalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: discountAmount > 0 ? Colors.white38 : Colors.white,
                              decoration: discountAmount > 0 ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ],
                      ),
                      if (discountAmount > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Descuento Promocional ($_appliedPromoCode $discountPercent%):',
                              style: const TextStyle(fontSize: 12, color: Colors.greenAccent, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '- RD\$ ${discountAmount.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12, color: Colors.greenAccent, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total a Cobrar / Pagar:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          Text(
                            'RD\$ ${finalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // Payment Method
              const Text('Cobro y Facturación', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                items: const [
                  DropdownMenuItem(
                    value: 'pending',
                    child: Text('Generar factura pendiente (Cobrar en caja / Pagos)'),
                  ),
                  DropdownMenuItem(
                    value: 'cash',
                    child: Text('Cobrar inmediatamente - Efectivo'),
                  ),
                  DropdownMenuItem(
                    value: 'card',
                    child: Text('Cobrar inmediatamente - Tarjeta de Crédito/Débito'),
                  ),
                  DropdownMenuItem(
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
                      : Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _paymentMethod == 'pending'
                        ? Colors.orange.withValues(alpha: 0.2)
                        : Colors.green.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _paymentMethod == 'pending' ? Icons.receipt_long_outlined : Icons.check_circle_outline,
                      size: 18,
                      color: _paymentMethod == 'pending' ? Colors.orangeAccent : Colors.greenAccent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _paymentMethod == 'pending'
                            ? 'Se registrará el plan asignado con pago PENDIENTE. Podrás cobrarlo en la caja desde el módulo de Pagos o en la ficha del socio.'
                            : 'El pago se registrará como COMPLETADO inmediatamente en la caja activa del cajero.',
                        style: TextStyle(
                          fontSize: 11,
                          color: _paymentMethod == 'pending' ? Colors.orangeAccent : Colors.greenAccent,
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
                        : const Text('Confirmar Asignación'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
