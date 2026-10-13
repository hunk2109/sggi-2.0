import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CheckoutSuccessDialog extends StatelessWidget {
  final double total;
  final String paymentMethod;
  final double change;
  final String customerName;

  const CheckoutSuccessDialog({
    super.key,
    required this.total,
    required this.paymentMethod,
    required this.change,
    required this.customerName,
  });

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
              'Cliente: $customerName',
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const Divider(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Cobrado:', style: TextStyle(fontSize: 14, color: Colors.white70)),
                Text(
                  currency.format(total),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Método de Pago:', style: TextStyle(fontSize: 13, color: Colors.white54)),
                Text(
                  _translateMethod(paymentMethod),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
            if (change > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cambio a Devolver:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber)),
                  Text(
                    currency.format(change),
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
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Imprimir Ticket'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enviando ticket a impresora POS...')),
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
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
