import 'package:flutter/material.dart';

/// Badge visual para representar el método de pago (Efectivo, Tarjeta, Transferencia, etc.)
class PaymentMethodBadge extends StatelessWidget {
  final String method;

  const PaymentMethodBadge({super.key, required this.method});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (method.toLowerCase()) {
      case 'cash':
      case 'efectivo':
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.greenAccent;
        label = 'Efectivo';
        icon = Icons.attach_money;
        break;
      case 'card':
      case 'tarjeta':
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blueAccent;
        label = 'Tarjeta';
        icon = Icons.credit_card;
        break;
      case 'transfer':
      case 'transferencia':
        bg = Colors.purple.withValues(alpha: 0.15);
        fg = Colors.purpleAccent;
        label = 'Transferencia';
        icon = Icons.account_balance;
        break;
      case 'credit_balance':
      case 'saldo a favor':
        bg = Colors.teal.withValues(alpha: 0.15);
        fg = Colors.tealAccent;
        label = 'Saldo a Favor';
        icon = Icons.account_balance_wallet;
        break;
      default:
        bg = Colors.white10;
        fg = Colors.white70;
        label = method.isEmpty ? 'Efectivo' : method;
        icon = Icons.payment;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
          ),
        ],
      ),
    );
  }
}

