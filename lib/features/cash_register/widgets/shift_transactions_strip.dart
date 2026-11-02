import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cash_register_model.dart';

class ShiftTransactionsStrip extends StatelessWidget {
  final List<CashTransactionModel> transactions;
  final double totalInflows;
  final double totalWithdrawals;

  const ShiftTransactionsStrip({
    super.key,
    required this.transactions,
    required this.totalInflows,
    required this.totalWithdrawals,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_US', symbol: 'RD\$ ', decimalDigits: 2);
    final timeFormat = DateFormat('hh:mm a');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E232B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.receipt_outlined, size: 16, color: Colors.white70),
                  SizedBox(width: 8),
                  Text(
                    'Movimientos de Caja Registrados en este Turno',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (totalInflows > 0)
                    Text(
                      'Total Ingresos: +${currency.format(totalInflows)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                    ),
                  if (totalWithdrawals > 0)
                    Text(
                      'Total Egresos: -${currency.format(totalWithdrawals)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: transactions.map((tx) {
              final isIncome = tx.isIn;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isIncome
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.orangeAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isIncome
                        ? Colors.green.withValues(alpha: 0.35)
                        : Colors.orangeAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
                      color: isIncome ? Colors.greenAccent : Colors.orangeAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${tx.concept}: ${isIncome ? '+' : '-'}${currency.format(tx.amount)} (${timeFormat.format(tx.createdAt)})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isIncome ? Colors.greenAccent : Colors.white70,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

