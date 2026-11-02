import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../models/sale_history_model.dart';
import '../widgets/payment_method_badge.dart';

class SaleDetailDialog extends StatelessWidget {
  final SaleHistoryModel sale;
  final bool isRegisterOpen;
  final bool canVoidSale;
  final VoidCallback onReprint;
  final VoidCallback onCancelSale;

  const SaleDetailDialog({
    super.key,
    required this.sale,
    required this.isRegisterOpen,
    required this.canVoidSale,
    required this.onReprint,
    required this.onCancelSale,
  });

  static Future<void> show({
    required BuildContext context,
    required SaleHistoryModel sale,
    required bool isRegisterOpen,
    required bool canVoidSale,
    required VoidCallback onReprint,
    required VoidCallback onCancelSale,
  }) {
    return showDialog(
      context: context,
      builder: (_) => SaleDetailDialog(
        sale: sale,
        isRegisterOpen: isRegisterOpen,
        canVoidSale: canVoidSale,
        onReprint: onReprint,
        onCancelSale: onCancelSale,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_US', symbol: 'RD\$ ', decimalDigits: 2);
    final dateTime = DateFormat('dd/MM/yyyy hh:mm a');
    final isCancelled = sale.status == 'cancelled';

    return AlertDialog(
      backgroundColor: const Color(0xFF1B2028),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Row(
        children: [
          Icon(
            isCancelled ? Icons.cancel : Icons.receipt_long,
            color: isCancelled ? Colors.redAccent : AppTheme.primary,
            size: 24,
          ),
          const SizedBox(width: 10),
          Text(
            'Detalle de Venta #${sale.shortId}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCancelled) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sale.notes?.contains('[ANULADA') == true
                            ? sale.notes!
                            : 'Esta venta ha sido anulada y sus productos reintegrados al inventario.',
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cliente: ${sale.customerName}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  dateTime.format(sale.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('Método de pago: ', style: TextStyle(fontSize: 12, color: Colors.white60)),
                PaymentMethodBadge(method: sale.paymentMethod),
              ],
            ),
            const Divider(height: 24, color: AppTheme.darkBorder),
            const Text(
              'Artículos Comprados:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sale.items.length,
                separatorBuilder: (_, _) => const Divider(height: 12, color: Colors.white10),
                itemBuilder: (_, index) {
                  final item = sale.items[index];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('${item.quantity}x ${item.productName}', style: const TextStyle(fontSize: 13)),
                      ),
                      Text(
                        currency.format(item.subtotal),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 24, color: AppTheme.darkBorder),
            if (sale.discount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Descuento aplicado:', style: TextStyle(fontSize: 13, color: Colors.amberAccent)),
                    Text(
                      '- ${currency.format(sale.discount)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                    ),
                  ],
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL COBRADO:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text(
                  currency.format(sale.totalAmount),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isCancelled ? Colors.redAccent : Colors.greenAccent,
                    decoration: isCancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar', style: TextStyle(color: Colors.white60)),
        ),
        if (!isCancelled && isRegisterOpen && canVoidSale)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
            ),
            icon: const Icon(Icons.cancel_outlined, size: 16),
            label: const Text('Anular Venta'),
            onPressed: () {
              Navigator.of(context).pop();
              onCancelSale();
            },
          ),
        if (!isCancelled)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            icon: const Icon(Icons.print, size: 16),
            label: const Text('Imprimir Ticket (Windows)'),
            onPressed: () {
              Navigator.of(context).pop();
              onReprint();
            },
          ),
      ],
    );
  }
}
