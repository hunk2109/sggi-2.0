import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/cash_register_provider.dart';

class ShiftHeroCard extends StatelessWidget {
  final CashRegisterState state;
  final bool canOpen;
  final bool canClose;
  final bool canWithdraw;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final VoidCallback onWithdraw;

  const ShiftHeroCard({
    super.key,
    required this.state,
    required this.canOpen,
    required this.canClose,
    required this.canWithdraw,
    required this.onOpen,
    required this.onClose,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_US', symbol: 'RD\$ ', decimalDigits: 2);
    final dateTime = DateFormat('dd/MM/yyyy hh:mm a');
    final reg = state.currentRegister;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 840;

        if (reg == null || !reg.isOpen) {
          final openButton = ElevatedButton.icon(
            icon: Icon(canOpen ? Icons.lock_open : Icons.lock_outline, size: 18),
            label: Text(canOpen ? 'Iniciar Turno / Abrir Caja' : 'Abrir Caja (Sin permiso)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: canOpen ? AppTheme.success : Colors.white12,
              foregroundColor: canOpen ? Colors.white : Colors.white38,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            onPressed: canOpen ? onOpen : null,
          );

          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(isCompact ? 16 : 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E232B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lock_outline, size: 38, color: Colors.white38),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Caja Cerrada • No Hay Turno Activo',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Debe registrar el fondo inicial para habilitar las operaciones de cobro.',
                                  style: TextStyle(fontSize: 12, color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: openButton,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const Icon(Icons.lock_outline, size: 42, color: Colors.white38),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Caja Cerrada • No Hay Turno Activo',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Debe registrar el fondo inicial para habilitar las operaciones de cobro en mostrador.',
                              style: TextStyle(fontSize: 12, color: Colors.white54),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      openButton,
                    ],
                  ),
          );
        }

        final hasActions = canWithdraw || canClose;
        final isNarrowOpen = constraints.maxWidth < 980;

        Widget infoBlock = Row(
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
            Expanded(
              child: Column(
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
                      Flexible(
                        child: Text(
                          'Apertura: ${dateTime.format(reg.createdAt)}',
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Fondo Inicial: ', style: TextStyle(fontSize: 13, color: Colors.white60)),
                          Text(
                            currency.format(reg.openingAmount),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Ventas Mostrador: ', style: TextStyle(fontSize: 13, color: Colors.white60)),
                          Text(
                            currency.format(state.totalSalesAmount),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Membresías: ', style: TextStyle(fontSize: 13, color: Colors.white60)),
                          Text(
                            currency.format(state.totalPaymentsAmount),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                          ),
                        ],
                      ),
                      if (state.totalInflows > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Otros Ingresos: ', style: TextStyle(fontSize: 13, color: Colors.white60)),
                            Text(
                              '+${currency.format(state.totalInflows)}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                            ),
                          ],
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Total Cobrado: ', style: TextStyle(fontSize: 13, color: Colors.white60)),
                          Text(
                            currency.format(state.totalShiftRevenue),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                          ),
                        ],
                      ),
                      if (state.totalWithdrawals > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Egresos: ', style: TextStyle(fontSize: 13, color: Colors.white60)),
                            Text(
                              '-${currency.format(state.totalWithdrawals)}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );

        Widget actionsBlock = Wrap(
          spacing: 10,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            if (canWithdraw)
              OutlinedButton.icon(
                icon: const Icon(Icons.money_off_csred_outlined, size: 16),
                label: const Text('Registrar Salida / Gasto'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orangeAccent,
                  side: const BorderSide(color: Colors.orangeAccent),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onPressed: onWithdraw,
              ),
            if (canClose)
              ElevatedButton.icon(
                icon: const Icon(Icons.lock_clock, size: 18),
                label: const Text('Cerrar Turno & Arqueo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                onPressed: onClose,
              ),
          ],
        );

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isNarrowOpen ? 16 : 22),
          decoration: BoxDecoration(
            color: const Color(0xFF0F2618),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.6), width: 1.5),
          ),
          child: isNarrowOpen
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    infoBlock,
                    if (hasActions) ...[
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: actionsBlock,
                      ),
                    ],
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: infoBlock),
                    if (hasActions) ...[
                      const SizedBox(width: 14),
                      actionsBlock,
                    ],
                  ],
                ),
        );
      },
    );
  }
}
