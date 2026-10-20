import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/cash_register_model.dart';
import '../providers/cash_register_provider.dart';

class DominicanDenomination {
  final int value;
  final String label;
  final bool isBill;
  final Color color;

  const DominicanDenomination({
    required this.value,
    required this.label,
    required this.isBill,
    required this.color,
  });
}

const List<DominicanDenomination> _dominicanDenominations = [
  DominicanDenomination(value: 2000, label: 'RD\$ 2,000', isBill: true, color: Color(0xFF1E88E5)),
  DominicanDenomination(value: 1000, label: 'RD\$ 1,000', isBill: true, color: Color(0xFFE53935)),
  DominicanDenomination(value: 500, label: 'RD\$ 500', isBill: true, color: Color(0xFF00ACC1)),
  DominicanDenomination(value: 200, label: 'RD\$ 200', isBill: true, color: Color(0xFFFB8C00)),
  DominicanDenomination(value: 100, label: 'RD\$ 100', isBill: true, color: Color(0xFF8E24AA)),
  DominicanDenomination(value: 50, label: 'RD\$ 50', isBill: true, color: Color(0xFF43A047)),
  DominicanDenomination(value: 25, label: 'RD\$ 25', isBill: false, color: Color(0xFFFFB300)),
  DominicanDenomination(value: 10, label: 'RD\$ 10', isBill: false, color: Color(0xFF78909C)),
  DominicanDenomination(value: 5, label: 'RD\$ 5', isBill: false, color: Color(0xFF8D6E63)),
  DominicanDenomination(value: 1, label: 'RD\$ 1', isBill: false, color: Color(0xFF90A4AE)),
];

class CloseCashDialog extends ConsumerStatefulWidget {
  final CashRegisterModel register;

  const CloseCashDialog({super.key, required this.register});

  @override
  ConsumerState<CloseCashDialog> createState() => _CloseCashDialogState();
}

class _CloseCashDialogState extends ConsumerState<CloseCashDialog> {
  final _closingController = TextEditingController();
  final Map<int, TextEditingController> _denomControllers = {};
  final _currency = NumberFormat.currency(locale: 'en_US', symbol: 'RD\$ ', decimalDigits: 2);
  bool _isLoading = false;
  bool _isBreakdownMode = true;

  @override
  void initState() {
    super.initState();
    for (final d in _dominicanDenominations) {
      _denomControllers[d.value] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _closingController.dispose();
    for (final ctrl in _denomControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _updateFromBreakdown() {
    double sum = 0;
    for (final d in _dominicanDenominations) {
      final count = int.tryParse(_denomControllers[d.value]?.text.trim() ?? '') ?? 0;
      sum += (d.value * count);
    }
    _closingController.text = sum > 0 ? sum.toStringAsFixed(2) : '';
    setState(() {});
  }

  void _changeDenomCount(int value, int delta) {
    final ctrl = _denomControllers[value];
    if (ctrl == null) return;
    final current = int.tryParse(ctrl.text.trim()) ?? 0;
    final next = current + delta;
    if (next < 0) return;
    ctrl.text = next > 0 ? next.toString() : '';
    _updateFromBreakdown();
  }

  void _clearBreakdown() {
    for (final ctrl in _denomControllers.values) {
      ctrl.clear();
    }
    _closingController.clear();
    setState(() {});
  }

  Future<void> _handleClose(double expectedCash) async {
    final amount = double.tryParse(_closingController.text.trim()) ?? 0.0;
    final diff = amount - expectedCash;

    if (diff.abs() > 0.01) {
      final isSurplus = diff > 0;
      final diffText = _currency.format(diff.abs());
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E232B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(
                isSurplus ? Icons.info_outline : Icons.warning_amber_rounded,
                color: isSurplus ? Colors.blueAccent : Colors.redAccent,
              ),
              const SizedBox(width: 10),
              Text(
                isSurplus ? 'Diferencia: Sobrante' : 'Diferencia: Faltante',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'El arqueo presenta un ${isSurplus ? 'excedente' : 'faltante'} de $diffText.',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Monto Esperado:', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  Text(_currency.format(expectedCash), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Físico Contado:', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  Text(_currency.format(amount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '¿Desea registrar el cierre y asentar esta diferencia en la auditoría?',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white60),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Revisar Conteo'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSurplus ? AppTheme.primary : AppTheme.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Confirmar Cierre'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    // Build breakdown map
    final Map<String, int> breakdown = {};
    for (final d in _dominicanDenominations) {
      final count = int.tryParse(_denomControllers[d.value]?.text.trim() ?? '') ?? 0;
      if (count > 0) {
        breakdown[d.value.toString()] = count;
      }
    }

    setState(() => _isLoading = true);
    final success = await ref.read(cashRegisterProvider.notifier).closeRegister(
      amount,
      billBreakdown: breakdown.isNotEmpty ? breakdown : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Caja cerrada y arqueo completado exitosamente'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      final err = ref.read(cashRegisterProvider).error ?? 'Error cerrando caja';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cashRegisterProvider);
    final opening = widget.register.openingAmount;

    // Filter sales from current shift
    final cashSales = state.cashSalesAmount;
    final otherSales = state.sales
        .where((s) => s.status != 'cancelled' && s.paymentMethod != 'cash' && s.paymentMethod.isNotEmpty)
        .fold(0.0, (sum, s) => sum + s.totalAmount);

    final cashPayments = state.cashPaymentsAmount;
    final otherPayments = state.otherPaymentsAmount;

    final withdrawals = state.totalWithdrawals;
    final inflows = state.totalInflows;

    // Monto esperado en gaveta física (Fondo Inicial + Ventas Efectivo + Membresías Efectivo + Otros Ingresos - Retiros)
    final expectedCash = opening + cashSales + cashPayments + inflows - withdrawals;

    final entered = double.tryParse(_closingController.text.trim()) ?? 0.0;
    final diff = entered - expectedCash;
    final hasInput = _closingController.text.trim().isNotEmpty;

    return Dialog(
      backgroundColor: const Color(0xFF1E232B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 660,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lock_clock, color: Colors.amber, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'Cierre & Arqueo de Caja',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.white60),
                  onPressed: () => Navigator.of(context).pop(false),
                  tooltip: 'Cerrar ventana',
                ),
              ],
            ),
            const Divider(height: 20, color: Colors.white12),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ================= CARD: RESUMEN FINANCIERO Y MONTO ESPERADO =================
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16191E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: expectedCash > 0
                              ? Colors.amber.withValues(alpha: 0.35)
                              : Colors.white12,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.calculate_outlined, color: Colors.amber, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Arqueo Teórico del Turno (Monto Esperado)',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Caja #${widget.register.id.length > 6 ? widget.register.id.substring(0, 6) : widget.register.id}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Fondo Inicial de Apertura:', style: TextStyle(fontSize: 12, color: Colors.white70)),
                              Text(_currency.format(opening), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('(+) Ventas Mostrador (Efectivo):', style: TextStyle(fontSize: 12, color: Colors.greenAccent)),
                              Text('+ ${_currency.format(cashSales)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                            ],
                          ),
                          if (cashPayments > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('(+) Cobros de Membresías (Efectivo):', style: TextStyle(fontSize: 12, color: Colors.tealAccent)),
                                Text('+ ${_currency.format(cashPayments)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.tealAccent)),
                              ],
                            ),
                          ],
                          if (inflows > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('(+) Otros Ingresos (Efectivo):', style: TextStyle(fontSize: 12, color: Colors.greenAccent)),
                                Text('+ ${_currency.format(inflows)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                              ],
                            ),
                          ],
                          if (withdrawals > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('(-) Salidas / Retiros de Efectivo:', style: TextStyle(fontSize: 12, color: Colors.orangeAccent)),
                                Text('- ${_currency.format(withdrawals)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                              ],
                            ),
                          ],
                          if (otherSales + otherPayments > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('ℹ Tarjetas / Transf. (no van a gaveta):', style: TextStyle(fontSize: 11, color: Colors.white38)),
                                Text(_currency.format(otherSales + otherPayments), style: const TextStyle(fontSize: 11, color: Colors.white38)),
                              ],
                            ),
                          ],
                          const Divider(height: 16, color: Colors.white12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL EFECTIVO ESPERADO EN GAVETA:',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text(
                                _currency.format(expectedCash),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: expectedCash > 0 ? Colors.amberAccent : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ================= MODO DE ENTRADA (DESGLOSE vs MANUAL) =================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Conteo Físico de Efectivo',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Row(
                          children: [
                            if (_isBreakdownMode)
                              TextButton.icon(
                                icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: Colors.white60),
                                label: const Text('Limpiar Conteo', style: TextStyle(fontSize: 11, color: Colors.white60)),
                                onPressed: _clearBreakdown,
                              ),
                            const SizedBox(width: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => setState(() => _isBreakdownMode = true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _isBreakdownMode ? AppTheme.primary : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.payments_outlined, size: 14, color: _isBreakdownMode ? Colors.white : Colors.white60),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Desglose RD\$',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: _isBreakdownMode ? Colors.white : Colors.white60,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => setState(() => _isBreakdownMode = false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: !_isBreakdownMode ? AppTheme.primary : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_note, size: 14, color: !_isBreakdownMode ? Colors.white : Colors.white60),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Monto Directo',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: !_isBreakdownMode ? Colors.white : Colors.white60,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ================= DESGLOSE DE BILLETES DOMINICANOS =================
                    if (_isBreakdownMode) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 3.2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _dominicanDenominations.length,
                          itemBuilder: (context, index) {
                            final denom = _dominicanDenominations[index];
                            final ctrl = _denomControllers[denom.value]!;
                            final count = int.tryParse(ctrl.text.trim()) ?? 0;
                            final subtotal = denom.value * count;

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E232B),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: count > 0 ? denom.color.withValues(alpha: 0.6) : Colors.white12,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Denomination badge
                                  Container(
                                    width: 76,
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    decoration: BoxDecoration(
                                      color: denom.color.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: denom.color.withValues(alpha: 0.4)),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          denom.label,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: denom.color,
                                          ),
                                        ),
                                        Text(
                                          denom.isBill ? 'Billete' : 'Moneda',
                                          style: TextStyle(fontSize: 9, color: denom.color.withValues(alpha: 0.8)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Stepper controls
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                                    color: count > 0 ? Colors.white70 : Colors.white24,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                    onPressed: count > 0 ? () => _changeDenomCount(denom.value, -1) : null,
                                  ),
                                  SizedBox(
                                    width: 44,
                                    child: TextField(
                                      controller: ctrl,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                      decoration: InputDecoration(
                                        hintText: '0',
                                        hintStyle: const TextStyle(color: Colors.white30),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                        isDense: true,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Colors.white24)),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Colors.white24)),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: denom.color)),
                                      ),
                                      onChanged: (_) => _updateFromBreakdown(),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, size: 18),
                                    color: Colors.white70,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                                    onPressed: () => _changeDenomCount(denom.value, 1),
                                  ),

                                  const Spacer(),

                                  // Subtotal for this denom
                                  Text(
                                    _currency.format(subtotal),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal,
                                      color: count > 0 ? Colors.white : Colors.white38,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      // Manual entry mode
                      TextField(
                        controller: _closingController,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.attach_money, color: Colors.white70),
                          hintText: '0.00',
                          labelText: 'Efectivo Total Físico en Gaveta (RD\$)',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // ================= TOTAL FISICO & COMPARACION LIVE =================
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL FÍSICO CONTADO:',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
                              ),
                              Text(
                                _currency.format(entered),
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                          const Divider(height: 16, color: Colors.white10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    !hasInput || entered == 0
                                        ? Icons.help_outline
                                        : (diff.abs() < 0.01
                                            ? Icons.check_circle_outline
                                            : (diff > 0 ? Icons.trending_up : Icons.trending_down)),
                                    size: 16,
                                    color: !hasInput || entered == 0
                                        ? Colors.white54
                                        : (diff.abs() < 0.01
                                            ? Colors.greenAccent
                                            : (diff > 0 ? Colors.blueAccent : Colors.redAccent)),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    !hasInput || entered == 0
                                        ? 'Diferencia de Cuadre:'
                                        : (diff.abs() < 0.01
                                            ? 'Caja Cuadrada Perfecta:'
                                            : (diff > 0 ? 'Excedente / Sobrante:' : 'Faltante en Caja:')),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: !hasInput || entered == 0
                                          ? Colors.white54
                                          : (diff.abs() < 0.01
                                              ? Colors.greenAccent
                                              : (diff > 0 ? Colors.blueAccent : Colors.redAccent)),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                !hasInput || entered == 0
                                    ? _currency.format(diff)
                                    : (diff.abs() < 0.01
                                        ? 'RD\$ 0.00'
                                        : (diff > 0 ? '+ ${_currency.format(diff)}' : '- ${_currency.format(diff.abs())}')),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: !hasInput || entered == 0
                                      ? Colors.white54
                                      : (diff.abs() < 0.01
                                          ? Colors.greenAccent
                                          : (diff > 0 ? Colors.blueAccent : Colors.redAccent)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.lock, size: 16),
                  label: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Confirmar y Cerrar Caja'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: _isLoading ? null : () => _handleClose(expectedCash),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
