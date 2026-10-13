enum UserRole {
  admin,
  encargado,
  empleadoCajero,
  empleadoEntrenador,
  cliente;

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'encargado':
        return UserRole.encargado;
      case 'empleado_cajero':
        return UserRole.empleadoCajero;
      case 'empleado_entrenador':
        return UserRole.empleadoEntrenador;
      default:
        return UserRole.cliente;
    }
  }

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.encargado:
        return 'Encargado';
      case UserRole.empleadoCajero:
        return 'Cajero / Recepción';
      case UserRole.empleadoEntrenador:
        return 'Entrenador';
      case UserRole.cliente:
        return 'Socio / Cliente';
    }
  }

  bool get isAdmin => this == UserRole.admin;
  bool get canSell => this == UserRole.admin || this == UserRole.encargado || this == UserRole.empleadoCajero;
}

class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final UserRole role;
  final bool isActive;

  UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.role,
    this.isActive = true,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      phone: json['phone']?.toString(),
      role: UserRole.fromString(json['role']?.toString() ?? ''),
      isActive: json['isActive'] == true || json['isActive'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'role': role.name,
      'isActive': isActive,
    };
  }
}
