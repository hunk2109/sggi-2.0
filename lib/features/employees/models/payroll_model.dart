class PayrollModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String employeeRole;
  final int month;
  final int year;
  final double baseSalary;
  final double bonuses;
  final double deductions;
  final double netSalary;
  final String status;
  final DateTime? paymentDate;
  final String? bank;
  final String? accountNumber;

  PayrollModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeRole,
    required this.month,
    required this.year,
    required this.baseSalary,
    this.bonuses = 0.0,
    this.deductions = 0.0,
    required this.netSalary,
    required this.status,
    this.paymentDate,
    this.bank,
    this.accountNumber,
  });

  bool get isPaid => status.toLowerCase() == 'paid';
  bool get isApproved => status.toLowerCase() == 'approved';

  factory PayrollModel.fromJson(Map<String, dynamic> json) {
    final emp = json['employee'] as Map<String, dynamic>?;
    final fName = emp?['firstName']?.toString() ?? 'Empleado';
    final lName = emp?['lastName']?.toString() ?? '';
    final role = emp?['role']?.toString() ?? '';

    final bSalary = double.tryParse(json['baseSalary']?.toString() ?? '0') ?? 0.0;
    final bon = double.tryParse(json['bonuses']?.toString() ?? '0') ?? 0.0;
    final ded = double.tryParse(json['deductions']?.toString() ?? '0') ?? 0.0;
    final net = double.tryParse(json['netSalary']?.toString() ?? json['finalSalary']?.toString() ?? '') ?? (bSalary + bon - ded);

    DateTime? pDate;
    if (json['paymentDate'] != null) {
      pDate = DateTime.tryParse(json['paymentDate'].toString());
    }

    return PayrollModel(
      id: json['id']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? emp?['id']?.toString() ?? '',
      employeeName: '$fName $lName'.trim(),
      employeeRole: role,
      month: int.tryParse(json['month']?.toString() ?? '1') ?? 1,
      year: int.tryParse(json['year']?.toString() ?? '2026') ?? 2026,
      baseSalary: bSalary,
      bonuses: bon,
      deductions: ded,
      netSalary: net,
      status: json['status']?.toString() ?? 'draft',
      paymentDate: pDate,
      bank: emp?['bank']?.toString(),
      accountNumber: emp?['accountNumber']?.toString(),
    );
  }
}
