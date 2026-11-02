import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_table_scroll_view.dart';
import '../models/sale_history_model.dart';
import '../providers/cash_register_provider.dart';
import 'payment_method_badge.dart';

class SalesHistoryTab extends StatefulWidget {
  final CashRegisterState state;
  final VoidCallback onOpenRegister;
  final ValueChanged<SaleHistoryModel> onViewSale;
  final ValueChanged<SaleHistoryModel> onReprintSale;
  final ValueChanged<SaleHistoryModel> onCancelSale;

  const SalesHistoryTab({
    super.key,
    required this.state,
    required this.onOpenRegister,
    required this.onViewSale,
    required this.onReprintSale,
    required this.onCancelSale,
  });

  @override
  State<SalesHistoryTab> createState() => _SalesHistoryTabState();
}

class _SalesHistoryTabState extends State<SalesHistoryTab> {
  final _currency = NumberFormat.currency(locale: 'en_US', symbol: 'RD\$ ', decimalDigits: 2);
  final _dateTime = DateFormat('dd/MM/yyyy hh:mm a');
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    if (!state.isRegisterOpen) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, size: 48, color: Colors.white38),
              ),
              const SizedBox(height: 16),
              const Text(
                'No hay un turno de caja abierto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                'Esta sección solo muestra las ventas del turno activo actual.\nPara consultar ventas de turnos anteriores, diríjase a la pestaña "Historial de Cierres de Turno".',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.white54, height: 1.4),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.lock_open, size: 18),
                label: const Text('Iniciar Turno / Abrir Caja'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                ),
                onPressed: widget.onOpenRegister,
              ),
            ],
          ),
        ),
      );
    }

    final query = _searchCtrl.text.trim().toLowerCase();
    final filteredSales = state.sales.where((s) {
      if (query.isEmpty) return true;
      final matchCustomer = s.customerName.toLowerCase().contains(query);
      final matchId = s.id.toLowerCase().contains(query);
      final matchProduct = s.items.any((i) => i.productName.toLowerCase().contains(query));
      return matchCustomer || matchId || matchProduct;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barra de Búsqueda y Estadísticas de Ventas
          Row(
            children: [
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar por cliente, ticket o producto...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    fillColor: AppTheme.darkSurface,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.darkBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.darkBorder)),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_money, size: 18, color: Colors.greenAccent),
                    const SizedBox(width: 4),
                    Text(
                      'Total Facturado: ${_currency.format(state.totalSalesAmount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.greenAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(
            child: filteredSales.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.white24),
                        const SizedBox(height: 10),
                        Text(
                          query.isEmpty
                              ? 'No se han registrado ventas en este turno aún'
                              : 'No se encontraron ventas para "$query"',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  )
                : AppTableScrollView(
                    child: DataTable(
                      columnSpacing: 18,
                      horizontalMargin: 14,
                      headingRowHeight: 42,
                      dataRowMinHeight: 48,
                      dataRowMaxHeight: 52,
                      columns: const [
                        DataColumn(label: Text('Ticket No.', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Fecha y Hora', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Cliente', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Artículos Comprados', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Método', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: filteredSales.map((sale) {
                        final isCancelled = sale.status == 'cancelled';
                        final itemsSummary = sale.items.isNotEmpty
                            ? sale.items.map((i) => '${i.quantity}x ${i.productName}').join(', ')
                            : 'Sin desglose';

                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isCancelled ? Icons.cancel_outlined : Icons.receipt_outlined,
                                    size: 14,
                                    color: isCancelled ? Colors.redAccent : Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '#${sale.shortId}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isCancelled ? Colors.white54 : Colors.white,
                                      decoration: isCancelled ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(Text(_dateTime.format(sale.createdAt))),
                            DataCell(
                              Text(
                                sale.customerName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 240),
                                child: Text(
                                  itemsSummary,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                                ),
                              ),
                            ),
                            DataCell(PaymentMethodBadge(method: sale.paymentMethod)),
                            DataCell(
                              Text(
                                _currency.format(sale.totalAmount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isCancelled ? Colors.redAccent.withValues(alpha: 0.6) : Colors.greenAccent,
                                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isCancelled
                                      ? Colors.red.withValues(alpha: 0.15)
                                      : Colors.green.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isCancelled ? 'ANULADA' : 'COMPLETADA',
                                  style: TextStyle(
                                    fontSize: 10,
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
                                    icon: const Icon(Icons.visibility_outlined, size: 18),
                                    tooltip: 'Ver Detalle',
                                    onPressed: () => widget.onViewSale(sale),
                                  ),
                                  if (!isCancelled)
                                    IconButton(
                                      icon: const Icon(Icons.print, size: 18, color: Colors.blueAccent),
                                      tooltip: 'Reimprimir Ticket (Windows)',
                                      onPressed: () => widget.onReprintSale(sale),
                                    ),
                                  if (!isCancelled && state.isRegisterOpen)
                                    IconButton(
                                      icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.redAccent),
                                      tooltip: 'Anular Venta de este Turno',
                                      onPressed: () => widget.onCancelSale(sale),
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
        ],
      ),
    );
  }
}

