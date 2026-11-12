import 'dart:convert';

class CashRegisterModel {
  final String id;
  final String userId;
  final double openingAmount;
  final double? closingAmount;
  final double? expectedClosure;
  final double? difference;
  final bool isOpen;
  final DateTime createdAt;
  final DateTime? closedAt;

  final String? closingBillBreakdown;

  CashRegisterModel({
    required this.id,
    required this.userId,
    required this.openingAmount,
    this.closingAmount,
    this.expectedClosure,
    this.difference,
    this.closingBillBreakdown,
    required this.isOpen,
    required this.createdAt,
    this.closedAt,
  });

  bool get isBalanced => (difference ?? 0.0).abs() < 0.01;
  bool get hasSurplus => (difference ?? 0.0) > 0.01;
  bool get hasDeficit => (difference ?? 0.0) < -0.01;

  /// Devuelve el mapa de denominaciones (ej. {"2000": 3, "500": 2}) ordenado de mayor a menor.
  Map<int, int> get parsedBillBreakdown {
    final raw = closingBillBreakdown;
    if (raw == null || raw.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final entries = <MapEntry<int, int>>[];
        for (final entry in decoded.entries) {
          final denom = int.tryParse(entry.key.toString());
          final count = int.tryParse(entry.value.toString());
          if (denom != null && count != null && count > 0) {
            entries.add(MapEntry(denom, count));
          }
        }
        entries.sort((a, b) => b.key.compareTo(a.key));
        return Map.fromEntries(entries);
      }
    } catch (_) {}
    return {};
  }

  factory CashRegisterModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedCreated = DateTime.now();
    if (json['createdAt'] != null) {
      parsedCreated = (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()).toLocal();
    }

    DateTime? parsedClosed;
    if (json['closedAt'] != null) {
      parsedClosed = DateTime.tryParse(json['closedAt'].toString())?.toLocal();
    }

    String? rawBreakdown;
    final breakdownField = json['closingBillBreakdown'] ?? json['billBreakdown'];
    if (breakdownField is Map) {
      rawBreakdown = jsonEncode(breakdownField);
    } else if (breakdownField != null) {
      rawBreakdown = breakdownField.toString();
    }

    return CashRegisterModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      openingAmount: double.tryParse(json['openingAmount']?.toString() ?? '0') ?? 0.0,
      closingAmount: json['closingAmount'] != null ? double.tryParse(json['closingAmount'].toString()) : null,
      expectedClosure: json['expectedClosure'] != null ? double.tryParse(json['expectedClosure'].toString()) : null,
      difference: json['difference'] != null ? double.tryParse(json['difference'].toString()) : null,
      closingBillBreakdown: rawBreakdown,
      isOpen: json['isOpen'] == true || json['isOpen'] == 1,
      createdAt: parsedCreated,
      closedAt: parsedClosed,
    );
  }
}

class CashTransactionModel {
  final String id;
  final String cashRegisterId;
  final String type; // 'in' | 'out'
  final double amount;
  final String concept;
  final DateTime createdAt;

  CashTransactionModel({
    required this.id,
    required this.cashRegisterId,
    required this.type,
    required this.amount,
    required this.concept,
    required this.createdAt,
  });

  bool get isOut => type.toLowerCase() == 'out';
  bool get isIn => type.toLowerCase() == 'in';

  factory CashTransactionModel.fromJson(Map<String, dynamic> json) {
    return CashTransactionModel(
      id: json['id']?.toString() ?? '',
      cashRegisterId: json['cashRegisterId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'out',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      concept: json['concept']?.toString() ?? 'Gasto de caja',
      createdAt: json['createdAt'] != null
          ? ((DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()).toLocal())
          : DateTime.now(),
    );
  }
}
