import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../dialogs/cash_withdrawal_dialog.dart';
import '../dialogs/close_cash_dialog.dart';
import '../dialogs/open_cash_dialog.dart';
import '../providers/cash_register_provider.dart';

class CashRegisterScreen extends ConsumerStatefulWidget {
  const CashRegisterScreen({super.key});

  @override
  ConsumerState<CashRegisterScreen> createState() => _CashRegisterScreenState();
}

class _CashRegisterScreenState extends ConsumerState<CashRegisterScreen> {
  final _currency = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$ ', decimalDigits: 2);
  final _dateTime = DateFormat('dd/MM/yyyy hh:mm a');
  final _timeFormat = DateFormat('hh:mm a');

  Future<void> _openOpenDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const OpenCashDialog(),
    );
    if (result == true) {
      ref.read(cashRegisterProvider.notifier).loadInitialData();
    }
  }

  Future<void> _openWithdrawalDialog() async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CashWithdrawalDialog(),
    );
  }

  Future<void> _openCloseDialog() async {
    final register = ref.read(cashRegisterProvider).currentRegister;
    if (register == null) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CloseCashDialog(register: register),
    );
    if (result == true) {
      ref.read(cashRegisterProvider.notifier).loadInitialData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cashRegisterProvider);
    final notifier = ref.read(cashRegisterProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, color: AppTheme.primary, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Control de Caja & Arqueo de Turno',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualizar estado de caja',
                onPressed: () => notifier.loadInitialData(),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Active Shift Banner / Hero Card
          state.isLoading
              ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              : _buildShiftHeroCard(state),

          const SizedBox(height: 20),

          // If shift has cash withdrawals, show them in an activity strip
          if (state.isRegisterOpen && state.currentTransactions.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E232B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.receipt_outlined, size: 16, color: Colors.orangeAccent),
                          SizedBox(width: 8),
                          Text('Salidas y Gastos Registrados en este Turno', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      Text(
                        'Total Egresos: ${_currency.format(state.totalWithdrawals)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: state.currentTransactions.map((tx) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${tx.concept}: -${_currency.format(tx.amount)} (${_timeFormat.format(tx.createdAt)})',
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // History Section Header
          const Text(
            'Historial de Turnos y Cierres Anteriores',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              padding: const EdgeInsets.all(16),
              child: state.history.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.white24),
                          SizedBox(height: 10),
                          Text('No hay registros históricos de cajas cerradas', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          headingRowHeight: 42,
                          dataRowMinHeight: 48,
                          dataRowMaxHeight: 48,
                          columns: const [
                            DataColumn(label: Text('Fecha y Hora Apertura', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Fondo Inicial', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Efectivo al Cierre', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Esperado', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Descuadre / Diferencia', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: state.history.map((reg) {
                            final diff = reg.difference ?? 0.0;
                            final isBalanced = diff.abs() < 0.01;

                            return DataRow(
                              cells: [
                                DataCell(Text(_dateTime.format(reg.createdAt))),
                                DataCell(Text(_currency.format(reg.openingAmount))),
                                DataCell(Text(reg.closingAmount != null ? _currency.format(reg.closingAmount!) : '-')),
                                DataCell(Text(reg.expectedClosure != null ? _currency.format(reg.expectedClosure!) : '-')),
                                DataCell(
                                  reg.difference != null
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                      : const Text('-'),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: reg.isOpen ? Colors.green.withValues(alpha: 0.15) : Colors.white10,
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
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftHeroCard(CashRegisterState state) {
    final reg = state.currentRegister;

    if (reg == null || !reg.isOpen) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E232B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.lock_outline, size: 42, color: Colors.white38),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Caja Cerrada • No Hay Turno Activo',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Debe registrar el fondo inicial para habilitar las operaciones de cobro en mostrador.',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ],
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.lock_open, size: 18),
              label: const Text('Iniciar Turno / Abrir Caja'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onPressed: _openOpenDialog,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2618),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_open, color: Colors.greenAccent, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'TURNO ACTIVO • CAJA ABIERTA',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Apertura: ${_dateTime.format(reg.createdAt)}',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Fondo Inicial: ', style: TextStyle(fontSize: 14, color: Colors.white60)),
                      Text(
                        _currency.format(reg.openingAmount),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      if (state.totalWithdrawals > 0) ...[
                        const SizedBox(width: 16),
                        const Text('Egresos en turno: ', style: TextStyle(fontSize: 13, color: Colors.white60)),
                        Text(
                          '-${_currency.format(state.totalWithdrawals)}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.money_off_csred_outlined, size: 16),
                label: const Text('Registrar Salida / Gasto'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orangeAccent,
                  side: const BorderSide(color: Colors.orangeAccent),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onPressed: _openWithdrawalDialog,
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.lock_clock, size: 18),
                label: const Text('Cerrar Turno & Arqueo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                onPressed: _openCloseDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
