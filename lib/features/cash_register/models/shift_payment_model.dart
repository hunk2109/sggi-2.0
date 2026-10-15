class ShiftPaymentModel {
  final String id;
  final double amount;
  final String paymentMethod;
  final String paymentType;
  final String status;
  final String concept;
  final String memberName;
  final String memberCode;
  final DateTime? paymentDate;
  final DateTime createdAt;

  ShiftPaymentModel({
    required this.id,
    required this.amount,
    required this.paymentMethod,
    required this.paymentType,
    required this.status,
    required this.concept,
    required this.memberName,
    required this.memberCode,
    this.paymentDate,
    required this.createdAt,
  });

  String get shortId => id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
  bool get isCash => paymentMethod.toLowerCase() == 'cash' || paymentMethod.isEmpty;
  String get planName => concept;
  String? get notes => concept;

  factory ShiftPaymentModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedPaymentDate;
    if (json['paymentDate'] != null) {
      parsedPaymentDate = DateTime.tryParse(json['paymentDate'].toString());
    }

    DateTime parsedCreatedAt = DateTime.now();
    if (json['createdAt'] != null) {
      parsedCreatedAt = DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now();
    }

    return ShiftPaymentModel(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ??
          double.tryParse(json['amount']?.toString() ?? '0') ??
          0.0,
      paymentMethod: json['paymentMethod']?.toString() ?? 'cash',
      paymentType: json['paymentType']?.toString() ?? 'membership',
      status: json['status']?.toString() ?? 'completed',
      concept: json['concept']?.toString() ?? 'Membresía',
      memberName: json['memberName']?.toString() ?? 'Socio',
      memberCode: json['memberCode']?.toString() ?? '',
      paymentDate: parsedPaymentDate,
      createdAt: parsedCreatedAt,
    );
  }
}
