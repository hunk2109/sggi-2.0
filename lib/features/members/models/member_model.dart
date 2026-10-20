class MemberModel {
  final String id;
  final String? userId;
  final String? memberCode;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? documentId;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? address;
  final String? emergencyContact;
  final String? emergencyPhone;
  final DateTime joinDate;
  final bool isPaid;
  final bool hasMembership;
  final bool hasPendingPayment;
  final String? activePlanName;
  final String? activePlanId;
  final DateTime? membershipEndDate;
  final bool isSuspended;
  final String? role;

  MemberModel({
    required this.id,
    this.userId,
    this.memberCode,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.documentId,
    this.gender,
    this.dateOfBirth,
    this.address,
    this.emergencyContact,
    this.emergencyPhone,
    required this.joinDate,
    this.isPaid = false,
    this.hasMembership = false,
    this.hasPendingPayment = false,
    this.activePlanName,
    this.activePlanId,
    this.membershipEndDate,
    this.isSuspended = false,
    this.role,
  });

  bool get isAdmin => role?.toLowerCase() == 'admin';
  bool get isStaff {
    final r = role?.toLowerCase() ?? '';
    return r == 'admin' ||
        r == 'encargado' ||
        r == 'empleado_cajero' ||
        r == 'empleado_entrenador' ||
        r == 'trainer' ||
        r == 'cashier' ||
        r == 'manager' ||
        r == 'receptionist' ||
        r == 'supervisor';
  }

  String get fullName => '$firstName $lastName'.trim();
  String get displayCode => memberCode?.isNotEmpty == true ? memberCode! : 'S/C';

  bool get isExpired {
    if (membershipEndDate == null) return true;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(
      membershipEndDate!.year,
      membershipEndDate!.month,
      membershipEndDate!.day,
    );
    // Vence al día siguiente: durante todo el día de vencimiento sigue vigente.
    // Solo muestra vencido si el día de fin es estrictamente anterior a hoy (ayer o antes).
    return endDay.isBefore(todayStart);
  }

  String get statusLabel {
    if (isSuspended) return 'Suspendido';
    if (!hasMembership && activePlanName == null) return 'Sin Plan';
    if (hasPendingPayment) return 'Pago Pendiente';
    if (isExpired) return 'Vencido';
    return 'Al Día';
  }

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    // Manejar usuario anidado o campos en raíz
    final userMap = json['user'] as Map<String, dynamic>?;
    final fName = userMap?['firstName']?.toString() ?? json['firstName']?.toString() ?? 'Sin Nombre';
    final lName = userMap?['lastName']?.toString() ?? json['lastName']?.toString() ?? '';
    final mail = userMap?['email']?.toString() ?? json['email']?.toString();
    final ph = userMap?['phone']?.toString() ?? json['phone']?.toString() ?? json['emergencyPhone']?.toString();

    // Membresía activa si viene anidada
    String? planName;
    String? planId;
    DateTime? endDate;
    Map<String, dynamic>? activeMem = json['activeMembership'] as Map<String, dynamic>? ??
        json['membership'] as Map<String, dynamic>? ??
        json['currentMembership'] as Map<String, dynamic>?;

    if (activeMem == null && json['memberships'] is List && (json['memberships'] as List).isNotEmpty) {
      final list = json['memberships'] as List;
      final found = list.firstWhere(
        (m) => m is Map && (m['isActive'] == true || m['endDate'] != null),
        orElse: () => list.first,
      );
      if (found is Map) {
        activeMem = found.cast<String, dynamic>();
      }
    }

    if (activeMem != null) {
      final innerPlan = activeMem['membership'] as Map<String, dynamic>? ??
          activeMem['plan'] as Map<String, dynamic>?;
      planName = innerPlan?['name']?.toString() ??
          activeMem['name']?.toString() ??
          activeMem['membershipName']?.toString();
      planId = innerPlan?['id']?.toString() ??
          activeMem['membershipId']?.toString() ??
          activeMem['planId']?.toString();
      final rawEnd = activeMem['endDate']?.toString() ?? activeMem['acc_enddate']?.toString();
      if (rawEnd != null) {
        endDate = DateTime.tryParse(rawEnd)?.toLocal();
      }
    }

    if (planName == null) {
      if (json['membership'] is Map) {
        planName = (json['membership'] as Map)['name']?.toString();
        planId ??= (json['membership'] as Map)['id']?.toString();
      } else if (json['activePlanName'] != null) {
        planName = json['activePlanName']?.toString();
      }
    }
    if (planId == null) {
      if (json['membershipId'] != null) {
        planId = json['membershipId']?.toString();
      }
    }
    if (endDate == null && json['membershipEndDate'] != null) {
      endDate = DateTime.tryParse(json['membershipEndDate'].toString())?.toLocal();
    }

    final bool hasMem = json['hasMembership'] == true ||
        json['hasMembership'] == 1 ||
        planName != null ||
        (activeMem != null && activeMem['isActive'] != false);

    if (hasMem && planName == null) {
      planName = 'Plan Activo';
    }

    DateTime parsedJoin = DateTime.now();
    final rawJoin = json['joinDate']?.toString() ?? json['createdAt']?.toString();
    if (rawJoin != null) {
      parsedJoin = (DateTime.tryParse(rawJoin) ?? DateTime.now()).toLocal();
    }

    DateTime? parsedDob;
    if (json['dateOfBirth'] != null) {
      parsedDob = DateTime.tryParse(json['dateOfBirth'].toString())?.toLocal();
    }

    return MemberModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? userMap?['id']?.toString(),
      memberCode: json['memberCode']?.toString(),
      firstName: fName,
      lastName: lName,
      email: mail,
      phone: ph,
      documentId: json['documentId']?.toString(),
      gender: json['gender']?.toString(),
      dateOfBirth: parsedDob,
      address: json['address']?.toString(),
      emergencyContact: json['emergencyContact']?.toString(),
      emergencyPhone: json['emergencyPhone']?.toString(),
      joinDate: parsedJoin,
      isPaid: json['isPaid'] == true || json['isPaid'] == 1,
      hasMembership: hasMem,
      hasPendingPayment: json['hasPendingPayment'] == true ||
          json['hasPendingPayment'] == 1 ||
          json['hasPendingMembershipPayment'] == true ||
          json['hasPendingMembershipPayment'] == 1 ||
          (json['paymentStatus'] != null && json['paymentStatus'].toString().toLowerCase().contains('pend')) ||
          (activeMem != null && activeMem['paymentStatus'] != null && activeMem['paymentStatus'].toString().toLowerCase().contains('pend')) ||
          (json['isPaid'] == false && hasMem),
      activePlanName: planName,
      activePlanId: planId,
      membershipEndDate: endDate,
      isSuspended: json['isMembershipSuspended'] == true || json['isMembershipSuspended'] == 1,
      role: userMap?['role']?.toString() ?? json['role']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
