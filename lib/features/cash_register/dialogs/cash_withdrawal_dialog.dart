import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/cash_register_provider.dart';

class CashWithdrawalDialog extends ConsumerStatefulWidget {
  const CashWithdrawalDialog({super.key});

  @override
  ConsumerState<CashWithdrawalDialog> createState() => _CashWithdrawalDialogState();
}

class _CashWithdrawalDialogState extends ConsumerState<CashWithdrawalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _conceptController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _conceptController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) return;

    setState(() => _isLoading = true);

    final success = await ref.read(cashRegisterProvider.notifier).recordWithdrawal(
      _conceptController.text.trim(),
      amount,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Salida de efectivo registrada exitosamente'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      final err = ref.read(cashRegisterProvider).error ?? 'Error registrando salida';
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
        width: 460,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.money_off_csred_outlined, color: Colors.orangeAccent, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Registrar Salida de Efectivo / Gasto',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Divider(height: 24),

              const Text(
                'Concepto / Motivo de Salida *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _conceptController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Ej. Compra de agua, insumos de limpieza...',
                ),
                validator: (v) => v?.trim().isEmpty == true ? 'Ingrese el concepto' : null,
              ),

              const SizedBox(height: 14),

              const Text(
                'Monto a Retirar en Efectivo (RD\$) *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.attach_money, color: Colors.orangeAccent),
                  hintText: '0.00',
                ),
                validator: (v) {
                  final parsed = double.tryParse(v ?? '');
                  if (parsed == null || parsed <= 0) return 'Monto inválido';
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Quick preset chips
              Wrap(
                spacing: 8,
                children: [100, 200, 300, 500, 1000].map((preset) {
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
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : const Text('Registrar Salida', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
