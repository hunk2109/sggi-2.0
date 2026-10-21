import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/receipt_printing_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/member_model.dart';
import '../providers/members_provider.dart';

class AddCreditDialog extends ConsumerStatefulWidget {
  final MemberModel member;

  const AddCreditDialog({super.key, required this.member});

  @override
  ConsumerState<AddCreditDialog> createState() => _AddCreditDialogState();
}

class _AddCreditDialogState extends ConsumerState<AddCreditDialog> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(symbol: 'RD\$ ', decimalDigits: 2);

  String _paymentMethod = 'cash';
  bool _isLoading = false;
  double _amount = 0.0;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() {
      final parsed = double.tryParse(_amountController.text) ?? 0.0;
      if (parsed != _amount) {
        setState(() => _amount = parsed);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _setQuickAmount(double value) {
    _amountController.text = value.toStringAsFixed(0);
    setState(() => _amount = value);
  }

  Future<void> _handleConfirm() async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un monto válido mayor a 0.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final memberService = ref.read(memberServiceProvider);
    final gymSettings = ref.read(gymSettingsProvider).settings;

    try {
      final success = await memberService.addCredit(
        memberId: widget.member.id,
        amount: _amount,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        final navigator = Navigator.of(context);
        final messenger = ScaffoldMessenger.of(context);

        // Diálogo para imprimir comprobante opcional
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1B2028),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: const Row(
              children: [
                Icon(Icons.print_outlined, color: Colors.tealAccent, size: 24),
                SizedBox(width: 10),
                Text('¿Imprimir Comprobante de Recarga?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Text(
              'Recarga de RD\$ ${_amount.toStringAsFixed(2)} aplicada exitosamente al socio ${widget.member.fullName}.\n\nNuevo saldo: RD\$ ${(widget.member.creditBalance + _amount).toStringAsFixed(2)}\n\n¿Deseas imprimir el recibo para el socio?',
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('No imprimir', style: TextStyle(color: Colors.white60)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                icon: const Icon(Icons.print, size: 16),
                label: const Text('Imprimir Recibo'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ReceiptPrintingService.printMembershipReceipt(
                    memberName: widget.member.fullName,
                    displayCode: widget.member.displayCode,
                    planName: 'Recarga Saldo a Favor',
                    amountPaid: _amount,
                    paymentMethod: _paymentMethod,
                    startDate: DateTime.now(),
                    endDate: null,
                    gymSettings: gymSettings,
                  );
                },
              ),
            ],
          ),
        );

        if (!mounted) return;
        navigator.pop(true);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Se agregaron ${_currencyFormat.format(_amount)} al saldo de ${widget.member.fullName}.'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final newBalance = widget.member.creditBalance + _amount;

    return Dialog(
      backgroundColor: const Color(0xFF16191E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.tealAccent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recargar Saldo a Favor',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.member.fullName} (#${widget.member.displayCode})',
                        style: const TextStyle(fontSize: 12, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Balances Summary Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E232B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Saldo Actual', style: TextStyle(fontSize: 11, color: Colors.white54)),
                      const SizedBox(height: 3),
                      Text(
                        _currencyFormat.format(widget.member.creditBalance),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward, size: 18, color: Colors.tealAccent),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Nuevo Saldo Estimado', style: TextStyle(fontSize: 11, color: Colors.tealAccent)),
                      const SizedBox(height: 3),
                      Text(
                        _currencyFormat.format(newBalance),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.tealAccent),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Amount Input
            const Text('Monto a Recargar *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.attach_money, color: Colors.tealAccent),
                hintText: '0.00',
              ),
            ),

            const SizedBox(height: 10),

            // Quick preset chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildQuickChip(500),
                _buildQuickChip(1000),
                _buildQuickChip(2000),
                _buildQuickChip(5000),
              ],
            ),

            const SizedBox(height: 18),

            // Payment method selector
            const Text('Método de Cobro en Caja *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Efectivo (Entra a caja registradora)')),
                DropdownMenuItem(value: 'card', child: Text('Tarjeta de Crédito / Débito')),
                DropdownMenuItem(value: 'transfer', child: Text('Transferencia Bancaria')),
              ],
              onChanged: (v) => setState(() => _paymentMethod = v ?? 'cash'),
            ),

            const SizedBox(height: 14),

            // Notes / Concept
            const Text('Concepto / Nota (Opcional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Ej. Anticipo mensualidad, Saldo por devolución...',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  icon: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check, size: 18),
                  label: Text(_isLoading ? 'Procesando...' : 'Confirmar Recarga'),
                  onPressed: _isLoading ? null : _handleConfirm,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(double value) {
    final isSelected = _amount == value;
    return InkWell(
      onTap: () => _setQuickAmount(value),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal : const Color(0xFF1E232B),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.tealAccent : Colors.white12,
          ),
        ),
        child: Text(
          '+ ${_currencyFormat.format(value)}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }
}
