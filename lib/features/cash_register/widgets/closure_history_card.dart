import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_table_scroll_view.dart';
import '../models/cash_register_model.dart';
import '../models/sale_history_model.dart';
import '../models/shift_payment_model.dart';
import '../providers/cash_register_provider.dart';
import 'payment_method_badge.dart';

class ClosureHistoryCard extends ConsumerStatefulWidget {
  final CashRegisterModel register;
  final ValueChanged<SaleHistoryModel> onViewSale;
  final ValueChanged<SaleHistoryModel> onReprintSale;

  const ClosureHistoryCard({
    super.key,
    required this.register,
    required this.onViewSale,
    required this.onReprintSale,
  });

  @override
  ConsumerState<ClosureHistoryCard> createState() => _ClosureHistoryCardState();
}

class _ClosureHistoryCardState extends ConsumerState<ClosureHistoryCard> {
  final _currency = NumberFormat.currency(locale: 'en_US', symbol: 'RD\$ ', decimalDigits: 2);
  final _dateTime = DateFormat('dd/MM/yyyy hh:mm a');
  final _timeFormat = DateFormat('hh:mm a');

  bool _isExpanded = false;
  bool _isLoading = false;
  List<SaleHistoryModel>? _shiftSales;
  List<ShiftPaymentModel>? _shiftPayments;

  Future<void> _toggleExpansion() async {
    setState(() => _isExpanded = !_isExpanded);

    if (_isExpanded && (_shiftSales == null || _shiftPayments == null)) {
      setState(() => _isLoading = true);
      try {
        final service = ref.read(cashRegisterServiceProvider);
        final results = await Future.wait([
          service.getSales(cashRegisterId: widget.register.id, limit: 100),
          service.getPayments(widget.register.id),
        ]);
        if (mounted) {
          setState(() {
            _shiftSales = results[0] as List<SaleHistoryModel>;
            _shiftPayments = results[1] as List<ShiftPaymentModel>;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Widget _buildShiftSummaryItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white38)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final reg = widget.register;
    final diff = reg.difference ?? 0.0;
    final isBalanced = diff.abs() < 0.01;
    final shiftSales = _shiftSales ?? [];
    final shiftPayments = _shiftPayments ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isExpanded ? AppTheme.primary.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.06),
          width: _isExpanded ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila Principal del Turno (Clickeable para desplegar ventas)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _toggleExpansion,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: reg.isOpen ? Colors.green.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      reg.isOpen ? Icons.lock_open : Icons.lock_outline,
                      size: 20,
                      color: reg.isOpen ? Colors.greenAccent : Colors.white54,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              reg.isOpen ? 'Turno en Curso' : 'Turno Cerrado',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: reg.isOpen ? Colors.green.withValues(alpha: 0.2) : Colors.white10,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                reg.isOpen ? 'ABIERTA' : 'CERRADA',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: reg.isOpen ? Colors.greenAccent : Colors.white54,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Apertura: ${_dateTime.format(reg.createdAt)}${reg.closedAt != null ? ' • Cierre: ${_dateTime.format(reg.closedAt!)}' : ''}',
                          style: const TextStyle(fontSize: 12, color: Colors.white54),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Desglose de Valores
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildShiftSummaryItem('Fondo Inicial', _currency.format(reg.openingAmount), Colors.white70),
                      const SizedBox(width: 20),
                      _buildShiftSummaryItem(
                        'Efectivo Real',
                        reg.closingAmount != null ? _currency.format(reg.closingAmount!) : '-',
                        Colors.white,
                      ),
                      const SizedBox(width: 20),
                      _buildShiftSummaryItem(
                        'Efectivo Esperado',
                        reg.expectedClosure != null ? _currency.format(reg.expectedClosure!) : '-',
                        Colors.white70,
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Descuadre', style: TextStyle(fontSize: 11, color: Colors.white38)),
                          const SizedBox(height: 2),
                          if (reg.difference != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isBalanced
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : (diff > 0 ? Colors.blue.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _currency.format(diff),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isBalanced
                                      ? Colors.greenAccent
                                      : (diff > 0 ? Colors.blueAccent : Colors.redAccent),
                                ),
                              ),
                            )
                          else
                            const Text('-', style: TextStyle(fontSize: 12, color: Colors.white54)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  // Botón / Chevron Expandir
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isExpanded ? AppTheme.primary.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isExpanded ? AppTheme.primary : Colors.white12,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isExpanded ? 'Ocultar Detalles' : 'Ver Detalles',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _isExpanded ? AppTheme.primary : Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          size: 18,
                          color: _isExpanded ? AppTheme.primary : Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lista Desplegable / Contraíble de Ventas y Membresías del Turno
          if (_isExpanded) ...[
            const Divider(height: 1, color: Colors.white10),
            Container(
              width: double.infinity,
              color: Colors.black.withValues(alpha: 0.25),
              padding: const EdgeInsets.all(16),
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 12),
                            Text('Cargando registros de este turno...', style: TextStyle(color: Colors.white54, fontSize: 13)),
                          ],
                        ),
                      ),
                    )
                  : (shiftSales.isEmpty && shiftPayments.isEmpty)
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.info_outline, size: 18, color: Colors.white38),
                                SizedBox(width: 8),
                                Text(
                                  'No se realizaron ventas ni cobros de membresías durante este turno de caja.',
                                  style: TextStyle(color: Colors.white54, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Resumen Financiero por Método de Pago
                            Builder(
                              builder: (context) {
                                final activeSales = shiftSales.where((s) => s.status != 'cancelled');
                                final cashSales = activeSales
                                    .where((s) => s.paymentMethod.toLowerCase() == 'cash' || s.paymentMethod.toLowerCase() == 'efectivo' || s.paymentMethod.isEmpty)
                                    .fold(0.0, (sum, s) => sum + s.totalAmount);
                                final cardSales = activeSales
                                    .where((s) => s.paymentMethod.toLowerCase() == 'card' || s.paymentMethod.toLowerCase() == 'tarjeta')
                                    .fold(0.0, (sum, s) => sum + s.totalAmount);
                                final transferSales = activeSales
                                    .where((s) => s.paymentMethod.toLowerCase() == 'transfer' || s.paymentMethod.toLowerCase() == 'transferencia')
                                    .fold(0.0, (sum, s) => sum + s.totalAmount);

                                final activePayments = shiftPayments.where((p) => p.status != 'cancelled');
                                final cashPayments = activePayments
                                    .where((p) => p.paymentMethod.toLowerCase() == 'cash' || p.paymentMethod.toLowerCase() == 'efectivo' || p.paymentMethod.isEmpty)
                                    .fold(0.0, (sum, p) => sum + p.amount);
                                final cardPayments = activePayments
                                    .where((p) => p.paymentMethod.toLowerCase() == 'card' || p.paymentMethod.toLowerCase() == 'tarjeta')
                                    .fold(0.0, (sum, p) => sum + p.amount);
                                final transferPayments = activePayments
                                    .where((p) => p.paymentMethod.toLowerCase() == 'transfer' || p.paymentMethod.toLowerCase() == 'transferencia')
                                    .fold(0.0, (sum, p) => sum + p.amount);

                                final totalCashIncome = cashSales + cashPayments;
                                final totalCard = cardSales + cardPayments;
                                final totalTransfer = transferSales + transferPayments;
                                final totalRevenue = totalCashIncome + totalCard + totalTransfer;
                                final openingCash = reg.openingAmount;
                                final expectedCash = reg.expectedClosure ?? (openingCash + totalCashIncome);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF161A22),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(Icons.analytics_outlined, size: 16, color: AppTheme.primary),
                                              SizedBox(width: 8),
                                              Text(
                                                'Resumen Financiero del Turno',
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primary.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Total Facturado: ${_currency.format(totalRevenue)}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primary),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          // Tarjeta 1: Efectivo Físico en Gaveta
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Row(
                                                    children: [
                                                      Icon(Icons.attach_money, size: 14, color: Colors.greenAccent),
                                                      SizedBox(width: 4),
                                                      Text('Efectivo en Gaveta', style: TextStyle(fontSize: 11, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(_currency.format(expectedCash), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Fondo (${_currency.format(openingCash)}) + Cobros (${_currency.format(totalCashIncome)})',
                                                    style: const TextStyle(fontSize: 10, color: Colors.white54),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          // Tarjeta 2: Tarjeta (Banco / POS)
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Row(
                                                    children: [
                                                      Icon(Icons.credit_card, size: 14, color: Colors.blueAccent),
                                                      SizedBox(width: 4),
                                                      Text('Tarjetas (Banco)', style: TextStyle(fontSize: 11, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(_currency.format(totalCard), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                                  const SizedBox(height: 2),
                                                  const Text(
                                                    'Entra a cuenta de banco',
                                                    style: TextStyle(fontSize: 10, color: Colors.white54),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          // Tarjeta 3: Transferencias (Banco)
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.purple.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.purple.withValues(alpha: 0.25)),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Row(
                                                    children: [
                                                      Icon(Icons.account_balance, size: 14, color: Colors.purpleAccent),
                                                      SizedBox(width: 4),
                                                      Text('Transferencias (Banco)', style: TextStyle(fontSize: 11, color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(_currency.format(totalTransfer), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                                  const SizedBox(height: 2),
                                                  const Text(
                                                    'Entra a cuenta de banco',
                                                    style: TextStyle(fontSize: 10, color: Colors.white54),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            if (shiftSales.isNotEmpty) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.receipt_long, size: 16, color: AppTheme.primary),
                                      SizedBox(width: 8),
                                      Text(
                                        'Ventas mostrador en este turno (${shiftSales.length})',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Subtotal Ventas: ${_currency.format(shiftSales.where((s) => s.status != 'cancelled').fold(0.0, (sum, s) => sum + s.totalAmount))}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.greenAccent),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              AppTableScrollView(
                                minWidth: 900,
                                child: DataTable(
                                  headingRowHeight: 36,
                                  dataRowMinHeight: 44,
                                  dataRowMaxHeight: 48,
                                  horizontalMargin: 12,
                                  columnSpacing: 16,
                                  columns: const [
                                    DataColumn(label: Text('Ticket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    DataColumn(label: Text('Hora', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    DataColumn(label: Text('Cliente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    DataColumn(label: Text('Artículos Comprados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    DataColumn(label: Text('Método', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  ],
                                  rows: shiftSales.map((sale) {
                                    final isCancelled = sale.status == 'cancelled';
                                    final itemsSummary = sale.items.isNotEmpty
                                        ? sale.items.map((i) => '${i.quantity}x ${i.productName}').join(', ')
                                        : 'Sin desglose';

                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            '#${sale.shortId}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              decoration: isCancelled ? TextDecoration.lineThrough : null,
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(_timeFormat.format(sale.createdAt), style: const TextStyle(fontSize: 12))),
                                        DataCell(Text(sale.customerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                        DataCell(
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 220),
                                            child: Text(itemsSummary, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                                          ),
                                        ),
                                        DataCell(PaymentMethodBadge(method: sale.paymentMethod)),
                                        DataCell(
                                          Text(
                                            _currency.format(sale.totalAmount),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: isCancelled ? Colors.redAccent.withValues(alpha: 0.6) : Colors.greenAccent,
                                              decoration: isCancelled ? TextDecoration.lineThrough : null,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isCancelled ? Colors.red.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isCancelled ? 'ANULADA' : 'COMPLETADA',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: isCancelled ? Colors.redAccent : Colors.greenAccent,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.visibility_outlined, size: 16),
                                                tooltip: 'Ver Detalle',
                                                onPressed: () => widget.onViewSale(sale),
                                              ),
                                              if (!isCancelled)
                                                IconButton(
                                                  icon: const Icon(Icons.print, size: 16, color: Colors.blueAccent),
                                                  tooltip: 'Reimprimir Ticket',
                                                  onPressed: () => widget.onReprintSale(sale),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],

                            if (shiftSales.isNotEmpty && shiftPayments.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Divider(color: Colors.white12),
                              ),

                            if (shiftPayments.isNotEmpty) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.card_membership, size: 16, color: Colors.cyanAccent),
                                      SizedBox(width: 8),
                                      Text(
                                        'Cobros de membresías en este turno',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Subtotal Membresías: ${_currency.format(shiftPayments.fold(0.0, (sum, p) => sum + p.amount))}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.cyanAccent),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              AppTableScrollView(
                                minWidth: 900,
                                child: DataTable(
                                  headingRowHeight: 36,
                                  dataRowMinHeight: 44,
                                  dataRowMaxHeight: 48,
                                  horizontalMargin: 12,
                                  columnSpacing: 16,
                                  columns: const [
                                    DataColumn(label: Text('Recibo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    DataColumn(label: Text('Hora', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    DataColumn(label: Text('Socio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    DataColumn(label: Text('Plan / Concepto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    DataColumn(label: Text('Método', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  ],
                                  rows: shiftPayments.map((p) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text('#${p.shortId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        DataCell(Text(_timeFormat.format(p.paymentDate ?? p.createdAt), style: const TextStyle(fontSize: 12))),
                                        DataCell(
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(p.memberName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                              if (p.memberCode.isNotEmpty)
                                                Text(p.memberCode, style: const TextStyle(fontSize: 10, color: Colors.white54)),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            p.planName.isNotEmpty ? p.planName : (p.notes ?? 'Membresía'),
                                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                                          ),
                                        ),
                                        DataCell(PaymentMethodBadge(method: p.paymentMethod)),
                                        DataCell(
                                          Text(
                                            _currency.format(p.amount),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.greenAccent),
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'COMPLETADO',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.greenAccent,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ],
                        ),
            ),
          ],
        ],
      ),
    );
  }
}

