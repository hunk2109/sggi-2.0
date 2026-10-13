import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/cash_register_provider.dart';

class OpenCashDialog extends ConsumerStatefulWidget {
  const OpenCashDialog({super.key});

  @override
  ConsumerState<OpenCashDialog> createState() => _OpenCashDialogState();
}

class _OpenCashDialogState extends ConsumerState<OpenCashDialog> {
  final _amountController = TextEditingController(text: '1000.00');
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleOpen() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount < 0) return;

    setState(() => _isLoading = true);
    final success = await ref.read(cashRegisterProvider.notifier).openRegister(amount);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Caja abierta exitosamente. ¡Buen turno!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      final err = ref.read(cashRegisterProvider).error ?? 'Error abriendo caja';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E232B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lock_open, color: Colors.greenAccent, size: 24),
                SizedBox(width: 10),
                Text(
                  'Apertura de Turno / Caja',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),

            const Text(
              'Fondo Inicial en Efectivo (RD\$)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.attach_money, color: Colors.greenAccent),
                hintText: '0.00',
              ),
            ),

            const SizedBox(height: 14),

            // Quick preset chips
            Wrap(
              spacing: 8,
              children: [500, 1000, 1500, 2000, 3000].map((preset) {
                return ActionChip(
                  label: Text('RD\$ $preset', style: const TextStyle(fontSize: 11)),
                  backgroundColor: const Color(0xFF16191E),
                  onPressed: () => _amountController.text = preset.toDouble().toStringAsFixed(2),
                );
              }).toList(),
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
                  icon: const Icon(Icons.check, size: 18),
                  label: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Confirmar Apertura'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, foregroundColor: Colors.white),
                  onPressed: _isLoading ? null : _handleOpen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
