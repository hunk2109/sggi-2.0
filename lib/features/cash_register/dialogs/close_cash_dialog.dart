import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/cash_register_model.dart';
import '../providers/cash_register_provider.dart';

class CloseCashDialog extends ConsumerStatefulWidget {
  final CashRegisterModel register;

  const CloseCashDialog({super.key, required this.register});

  @override
  ConsumerState<CloseCashDialog> createState() => _CloseCashDialogState();
}

class _CloseCashDialogState extends ConsumerState<CloseCashDialog> {
  final _closingController = TextEditingController();
  final _currency = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$ ', decimalDigits: 2);
  bool _isLoading = false;

  @override
  void dispose() {
    _closingController.dispose();
    super.dispose();
  }

  Future<void> _handleClose() async {
    final amount = double.tryParse(_closingController.text.trim()) ?? 0.0;

    setState(() => _isLoading = true);
    final success = await ref.read(cashRegisterProvider.notifier).closeRegister(amount);

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
    final entered = double.tryParse(_closingController.text.trim()) ?? 0.0;
    final opening = widget.register.openingAmount;
    final diff = entered - opening;

    return Dialog(
      backgroundColor: const Color(0xFF1E232B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lock_clock, color: Colors.amber, size: 24),
                SizedBox(width: 10),
                Text(
                  'Cierre & Arqueo de Caja',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),

            // Opening info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Fondo Inicial de Apertura:', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  Text(
                    _currency.format(opening),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Efectivo Total Físico en Gaveta (RD\$)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _closingController,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.attach_money),
                hintText: '0.00',
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 14),

            // Live difference badge
            if (_closingController.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: diff.abs() < 0.01
                      ? Colors.green.withValues(alpha: 0.15)
                      : (diff > 0 ? Colors.blue.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      diff.abs() < 0.01 ? 'Caja Cuadrada con fondo' : (diff > 0 ? 'Excedente / Ventas en turno:' : 'Faltante:'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: diff.abs() < 0.01 ? Colors.greenAccent : (diff > 0 ? Colors.blueAccent : Colors.redAccent),
                      ),
                    ),
                    Text(
                      _currency.format(diff),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: diff.abs() < 0.01 ? Colors.greenAccent : (diff > 0 ? Colors.blueAccent : Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.lock, size: 16),
                  label: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Confirmar y Cerrar Caja'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
                  onPressed: _isLoading ? null : _handleClose,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
