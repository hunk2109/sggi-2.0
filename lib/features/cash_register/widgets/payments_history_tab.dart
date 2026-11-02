import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_table_scroll_view.dart';
import '../providers/cash_register_provider.dart';
import 'payment_method_badge.dart';

class PaymentsHistoryTab extends StatefulWidget {
  final CashRegisterState state;
  final VoidCallback onOpenRegister;

  const PaymentsHistoryTab({
    super.key,
    required this.state,
    required this.onOpenRegister,
  });

  @override
  State<PaymentsHistoryTab> createState() => _PaymentsHistoryTabState();
}

class _PaymentsHistoryTabState extends State<PaymentsHistoryTab> {
  final _currency = NumberFormat.currency(locale: 'en_US', symbol: 'RD\$ ', decimalDigits: 2);
  final _timeFormat = DateFormat('hh:mm a');
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
                'Esta sección solo muestra los cobros de membresías del turno activo actual.\nPara consultar turnos anteriores, diríjase a la pestaña "Historial de Cierres".',
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
    final filteredPayments = state.payments.where((p) {
      if (query.isEmpty) return true;
      final matchMember = p.memberName.toLowerCase().contains(query);
      final matchCode = p.memberCode.toLowerCase().contains(query);
      final matchPlan = p.planName.toLowerCase().contains(query);
      final matchId = p.id.toLowerCase().contains(query);
      return matchMember || matchCode || matchPlan || matchId;
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
          // Barra de Búsqueda y Estadísticas de Membresías
          Row(
            children: [
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar por socio, código de socio, plan...',
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
                  color: Colors.cyanAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.card_membership, size: 18, color: Colors.cyanAccent),
                    const SizedBox(width: 6),
                    Text(
                      'Total Membresías: ${_currency.format(state.totalPaymentsAmount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.cyanAccent),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '(Efectivo: ${_currency.format(state.cashPaymentsAmount)})',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(
            child: filteredPayments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.card_membership_outlined, size: 48, color: Colors.white24),
                        const SizedBox(height: 10),
                        Text(
                          query.isEmpty
                              ? 'No se han registrado cobros de membresías en este turno'
                              : 'No se encontraron cobros para "$query"',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  )
                : AppTableScrollView(
                    child: DataTable(
                      headingRowHeight: 42,
                      dataRowMinHeight: 48,
                      dataRowMaxHeight: 52,
                      horizontalMargin: 16,
                      columnSpacing: 20,
                      columns: const [
                        DataColumn(label: Text('Recibo', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Hora', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Socio', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Plan / Concepto', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Método', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: filteredPayments.map((p) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                '#${p.shortId}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            DataCell(Text(_timeFormat.format(p.paymentDate ?? p.createdAt), style: const TextStyle(fontSize: 12))),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(p.memberName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  if (p.memberCode.isNotEmpty)
                                    Text(p.memberCode, style: const TextStyle(fontSize: 11, color: Colors.white54)),
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
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.greenAccent),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'COMPLETADO',
                                  style: TextStyle(
                                    fontSize: 10,
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
          ),
        ],
      ),
    );
  }
}

