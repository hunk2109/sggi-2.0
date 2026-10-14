import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/receipt_printing_service.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/product_model.dart';

class CheckoutSuccessDialog extends ConsumerStatefulWidget {
  final double total;
  final double subtotal;
  final double discount;
  final String paymentMethod;
  final double amountReceived;
  final double change;
  final String customerName;
  final List<CartItemModel> items;
  final String? saleId;

  const CheckoutSuccessDialog({
    super.key,
    required this.total,
    this.subtotal = 0.0,
    this.discount = 0.0,
    required this.paymentMethod,
    this.amountReceived = 0.0,
    required this.change,
    required this.customerName,
    this.items = const [],
    this.saleId,
  });

  @override
  ConsumerState<CheckoutSuccessDialog> createState() => _CheckoutSuccessDialogState();
}

class _CheckoutSuccessDialogState extends ConsumerState<CheckoutSuccessDialog> {
  bool _isPrinting = false;

  Future<void> _handlePrint() async {
    setState(() => _isPrinting = true);
    final gymSettings = ref.read(gymSettingsProvider).settings;

    try {
      await ReceiptPrintingService.printSaleReceipt(
        items: widget.items,
        total: widget.total,
        subtotal: widget.subtotal > 0 ? widget.subtotal : widget.total + widget.discount,
        discount: widget.discount,
        paymentMethod: widget.paymentMethod,
        amountReceived: widget.amountReceived,
        change: widget.change,
        customerName: widget.customerName,
        saleId: widget.saleId,
        gymSettings: gymSettings,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir diálogo de impresión: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'es_DO', symbol: 'RD\$ ', decimalDigits: 2);

    return Dialog(
      backgroundColor: const Color(0xFF1B2028),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF0F381E),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 48, color: Colors.greenAccent),
            ),
            const SizedBox(height: 16),
            const Text(
              '¡Cobro Realizado!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              'Cliente: ${widget.customerName}',
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const Divider(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Cobrado:', style: TextStyle(fontSize: 14, color: Colors.white70)),
                Text(
                  currency.format(widget.total),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                ),
              ],
            ),
            if (widget.discount > 0) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Descuento aplicado:', style: TextStyle(fontSize: 12, color: Colors.amberAccent)),
                  Text(
                    '- ${currency.format(widget.discount)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Método de Pago:', style: TextStyle(fontSize: 13, color: Colors.white54)),
                Text(
                  _translateMethod(widget.paymentMethod),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
            if (widget.change > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cambio a Devolver:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber)),
                  Text(
                    currency.format(widget.change),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 28),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: _isPrinting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.print, size: 18),
                    label: Text(_isPrinting ? 'Abriendo...' : 'Imprimir Ticket'),
                    onPressed: _isPrinting ? null : _handlePrint,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.add_shopping_cart, size: 18),
                    label: const Text('Nueva Venta'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _translateMethod(String m) {
    if (m == 'cash') return 'Efectivo';
    if (m == 'card') return 'Tarjeta';
    if (m == 'transfer') return 'Transferencia';
    return m;
  }
}
