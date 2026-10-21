import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/receipt_printing_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../cash_register/providers/cash_register_provider.dart';
import '../../memberships/models/promotion_model.dart';
import '../../memberships/services/promotion_service.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/member_model.dart';
import '../providers/members_provider.dart';

class PayFeeDialog extends ConsumerStatefulWidget {
  final MemberModel member;
  final String paymentId;
  final double initialAmount;
  final String concept;
  final VoidCallback? onPaymentSuccess;

  const PayFeeDialog({
    super.key,
    required this.member,
    required this.paymentId,
    required this.initialAmount,
    this.concept = 'Cuota de Membresía',
    this.onPaymentSuccess,
  });

  @override
  ConsumerState<PayFeeDialog> createState() => _PayFeeDialogState();
}

class _PayFeeDialogState extends ConsumerState<PayFeeDialog> {
  static final _currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: 'RD\$ ', decimalDigits: 2);

  String _selectedMethod = 'cash';
  final _couponController = TextEditingController();
  final _manualDiscountController = TextEditingController();
  final _cashReceivedController = TextEditingController();

  bool _isValidatingCoupon = false;
  PromotionValidationResult? _couponResult;
  String? _appliedPromoCode;
  bool _isSubmitting = false;

  // 0: Sin Descuento, 1: Cupón Promocional, 2: Descuento Manual RD$
  int _discountMode = 1;

  @override
  void dispose() {
    _couponController.dispose();
    _manualDiscountController.dispose();
    _cashReceivedController.dispose();
    super.dispose();
  }

  double get _baseAmount => widget.initialAmount;

  double get _discountAmount {
    if (_discountMode == 1 && _couponResult != null && _couponResult!.valid) {
      return (_baseAmount * (_couponResult!.discount / 100));
    } else if (_discountMode == 2) {
      final manualVal = double.tryParse(_manualDiscountController.text.trim()) ?? 0.0;
      return manualVal > _baseAmount ? _baseAmount : manualVal;
    }
    return 0.0;
  }

  double get _finalAmount => (_baseAmount - _discountAmount).clamp(0.0, double.infinity);

  Future<void> _validateCoupon([String? explicitCode]) async {
    final code = (explicitCode ?? _couponController.text).trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un código de cupón'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    _couponController.text = code;
    setState(() => _isValidatingCoupon = true);

    try {
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _isValidatingCoupon = false;
          _couponResult = PromotionValidationResult(valid: false, discount: 0, message: 'Error al validar cupón: $e');
        });
      }
    }
  }

  void _clearCoupon() {
    setState(() {
      _couponController.clear();
      _couponResult = null;
      _appliedPromoCode = null;
    });
  }

  Future<void> _handleConfirmPayment() async {
    if (_selectedMethod == 'credit_balance' && widget.member.creditBalance < _finalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saldo a favor insuficiente (${_currencyFormat.format(widget.member.creditBalance)}). La cuota es de ${_currencyFormat.format(_finalAmount)}.',
          ),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final service = ref.read(memberServiceProvider);
    final discountCodeToSend = (_discountMode == 1 && _appliedPromoCode != null) ? _appliedPromoCode : null;
    final discountAmountToSend = (_discountMode == 2 && _discountAmount > 0) ? _discountAmount : null;

    final success = await service.payPayment(
      widget.paymentId,
      paymentMethod: _selectedMethod,
      discountCode: discountCodeToSend,
      discountAmount: discountAmountToSend,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (success) {
        // Actualizar la caja abierta para reflejar el ingreso de inmediato
        ref.read(cashRegisterProvider.notifier).loadInitialData();

        final gymSettings = ref.read(gymSettingsProvider).settings;
        final finalAmt = _finalAmount;
        final discAmt = _discountAmount;
        final promoCode = _appliedPromoCode;
        final discPercent = (_discountMode == 1 && _couponResult != null && _couponResult!.valid)
            ? _couponResult!.discount
            : (_discountMode == 2 && _baseAmount > 0 ? ((discAmt / _baseAmount) * 100).round() : null);

        widget.onPaymentSuccess?.call();
        Navigator.of(context).pop(true);

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            showCloseIcon: true,
            closeIconColor: Colors.white,
            width: 580,
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('Cobro de ${_currencyFormat.format(finalAmt)} registrado exitosamente en caja.')),
              ],
            ),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'IMPRIMIR RECIBO',
              textColor: Colors.amberAccent,
              onPressed: () {
                ReceiptPrintingService.printMembershipReceipt(
                  memberName: widget.member.fullName,
                  displayCode: widget.member.displayCode,
                  planName: widget.concept,
                  amountPaid: finalAmt,
                  paymentMethod: _selectedMethod,
                  receiptNumber: widget.paymentId,
                  promotionCode: promoCode,
                  discountPercentage: discPercent,
                  originalPlanPrice: discAmt > 0 ? _baseAmount : null,
                  gymSettings: gymSettings,
                );
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al registrar el cobro en caja'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final promotionsAsync = ref.watch(activePromotionsProvider);

    final cashReceived = double.tryParse(_cashReceivedController.text.trim()) ?? 0.0;
    final change = (cashReceived - _finalAmount).clamp(0.0, double.infinity);

    return Dialog(
      backgroundColor: const Color(0xFF1B2028),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 540,
        padding: const EdgeInsets.all(26),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.point_of_sale, color: AppTheme.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cobrar Cuota de Membresía',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
                          ),
                          Text(
                            'Socio: ${widget.member.fullName} (${widget.member.displayCode})',
                            style: const TextStyle(fontSize: 12, color: Colors.white60),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),

              const Divider(height: 24, color: AppTheme.darkBorder),

              // Concepto & Monto Base
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF15181E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Concepto:', style: TextStyle(fontSize: 11, color: Colors.white54)),
                        const SizedBox(height: 2),
                        Text(widget.concept, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Monto Base:', style: TextStyle(fontSize: 11, color: Colors.white54)),
                        const SizedBox(height: 2),
                        Text(
                          _currencyFormat.format(_baseAmount),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _discountAmount > 0 ? Colors.white54 : Colors.white,
                            decoration: _discountAmount > 0 ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // SELECCIÓN DE DESCUENTO EN EL MOMENTO DEL PAGO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Descuento al Pagar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (_discountMode == 1 && _appliedPromoCode != null)
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

              // Selector de Tipo de Descuento
              Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() {
                          _discountMode = 0;
                          _clearCoupon();
                          _manualDiscountController.clear();
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _discountMode == 0 ? AppTheme.primary.withValues(alpha: 0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: _discountMode == 0 ? Border.all(color: AppTheme.primary) : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Sin Descuento',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _discountMode == 0 ? FontWeight.bold : FontWeight.normal,
                              color: _discountMode == 0 ? Colors.white : Colors.white60,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() {
                          _discountMode = 1;
                          _manualDiscountController.clear();
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _discountMode == 1 ? AppTheme.primary.withValues(alpha: 0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: _discountMode == 1 ? Border.all(color: AppTheme.primary) : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Cupón Promocional',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _discountMode == 1 ? FontWeight.bold : FontWeight.normal,
                              color: _discountMode == 1 ? Colors.white : Colors.white60,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() {
                          _discountMode = 2;
                          _clearCoupon();
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _discountMode == 2 ? AppTheme.primary.withValues(alpha: 0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: _discountMode == 2 ? Border.all(color: AppTheme.primary) : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Descuento Manual',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _discountMode == 2 ? FontWeight.bold : FontWeight.normal,
                              color: _discountMode == 2 ? Colors.white : Colors.white60,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Modo 1: Cupón Promocional
              if (_discountMode == 1) ...[
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

                // Sugerencias de Cupones Activos
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

                // Feedback de Cupón
                if (_couponResult != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _couponResult!.valid ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _couponResult!.valid ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
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
                                ? '¡Cupón "$_appliedPromoCode" aplicado! (-${_couponResult!.discount}% = -${_currencyFormat.format(_discountAmount)})'
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
              ],

              // Modo 2: Descuento Manual en RD$
              if (_discountMode == 2) ...[
                TextField(
                  controller: _manualDiscountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                  decoration: const InputDecoration(
                    labelText: 'Monto de descuento en pesos (RD\$)',
                    prefixIcon: Icon(Icons.attach_money, size: 18),
                    hintText: 'Ej. 200.00',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],

              const SizedBox(height: 16),

              // Resumen Financiero Dinámico
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF15181E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    if (_discountAmount > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _discountMode == 1
                                ? 'Descuento Cupón ($_appliedPromoCode):'
                                : 'Descuento Manual:',
                            style: const TextStyle(fontSize: 12, color: Colors.greenAccent, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '- ${_currencyFormat.format(_discountAmount)}',
                            style: const TextStyle(fontSize: 13, color: Colors.greenAccent, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 14, color: Colors.white10),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL A COBRAR:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(
                          _currencyFormat.format(_finalAmount),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (widget.member.creditBalance > 0) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, size: 20, color: Colors.tealAccent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'El socio dispone de ${_currencyFormat.format(widget.member.creditBalance)} de Saldo a Favor disponible para aplicar a este pago.',
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // Selector de Método de Pago
              const Text('Método de Pago *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildPaymentMethodChip('cash', 'Efectivo', Icons.money),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPaymentMethodChip('card', 'Tarjeta', Icons.credit_card),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPaymentMethodChip('transfer', 'Transferencia', Icons.account_balance),
                  ),
                  if (widget.member.creditBalance > 0) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPaymentMethodChip('credit_balance', 'Saldo a Favor', Icons.account_balance_wallet),
                    ),
                  ],
                ],
              ),

              // Si es Efectivo, mostrar cálculo de devuelta
              if (_selectedMethod == 'cash') ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cashReceivedController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                        decoration: const InputDecoration(
                          labelText: 'Efectivo Recibido',
                          prefixIcon: Icon(Icons.attach_money, size: 18),
                          hintText: 'RD\$ 0.00',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Devuelta / Cambio:', style: TextStyle(fontSize: 10, color: Colors.white54)),
                            const SizedBox(height: 2),
                            Text(
                              _currencyFormat.format(change),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: cashReceived >= _finalAmount ? Colors.amberAccent : Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Acciones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check, size: 18),
                    label: Text(_isSubmitting ? 'Procesando...' : 'Confirmar Cobro (${_currencyFormat.format(_finalAmount)})'),
                    onPressed: _isSubmitting ? null : _handleConfirmPayment,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodChip(String key, String label, IconData icon) {
    final isSelected = _selectedMethod == key;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.white12,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? AppTheme.primary : Colors.white60),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
