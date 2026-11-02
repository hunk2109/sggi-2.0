import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_permissions.dart';
import '../../../core/widgets/app_table_scroll_view.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/sale_history_model.dart';
import '../providers/cash_register_provider.dart';
import 'closure_history_card.dart';

class ClosuresHistoryTab extends ConsumerWidget {
  final CashRegisterState state;
  final ValueChanged<SaleHistoryModel> onViewSale;
  final ValueChanged<SaleHistoryModel> onReprintSale;

  const ClosuresHistoryTab({
    super.key,
    required this.state,
    required this.onViewSale,
    required this.onReprintSale,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canViewHistory = ref.watch(authProvider).hasPermission(AppPermissions.cashViewHistory);

    if (!canViewHistory) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, size: 54, color: Colors.amber),
              ),
              const SizedBox(height: 18),
              const Text(
                'Acceso Restringido al Historial de Cierres',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tu rol actual no tiene habilitado el permiso para consultar el historial de arqueos y turnos de caja anteriores.\nContacta al Administrador si requieres acceso a esta auditoría.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.white54, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    if (state.history.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        padding: const EdgeInsets.all(32),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined, size: 48, color: Colors.white24),
              SizedBox(height: 12),
              Text(
                'No hay registros históricos de cajas cerradas',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return AppTableScrollView(
      minWidth: 1020,
      expandChildToWidth: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int index = 0; index < state.history.length; index++) ...[
            if (index > 0) const SizedBox(height: 12),
            ClosureHistoryCard(
              register: state.history[index],
              onViewSale: onViewSale,
              onReprintSale: onReprintSale,
            ),
          ],
        ],
      ),
    );
  }
}

