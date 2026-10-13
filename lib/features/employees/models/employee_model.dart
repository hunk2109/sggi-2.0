class EmployeeModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role;
  final DateTime hireDate;
  final double salary;
  final bool isActive;
  final String? specialization;
  final String? emergencyContact;
  final String? bank;
  final String? accountNumber;
  final String? accessCode;

  EmployeeModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    required this.hireDate,
    required this.salary,
    this.isActive = true,
    this.specialization,
    this.emergencyContact,
    this.bank,
    this.accountNumber,
    this.accessCode,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get roleLabel {
    switch (role.toLowerCase()) {
      case 'manager':
        return 'Encargado / Gerente';
      case 'trainer':
        return 'Entrenador';
      case 'receptionist':
        return 'Recepcionista';
      case 'cashier':
        return 'Cajero';
      case 'cleaner':
        return 'Mantenimiento';
      case 'nutritionist':
        return 'Nutricionista';
      case 'supervisor':
        return 'Supervisor';
      default:
        return role;
    }
  }

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    DateTime hDate = DateTime.now();
    if (json['hireDate'] != null) {
      hDate = DateTime.tryParse(json['hireDate'].toString()) ?? DateTime.now();
    }

    return EmployeeModel(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? 'Sin Nombre',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'trainer',
      hireDate: hDate,
      salary: double.tryParse(json['salary']?.toString() ?? '0') ?? 0.0,
      isActive: json['isActive'] != false,
      specialization: json['specialization']?.toString(),
      emergencyContact: json['emergencyContact']?.toString(),
      bank: json['bank']?.toString(),
      accountNumber: json['accountNumber']?.toString(),
      accessCode: json['accessCode']?.toString(),
    );
  }
}
