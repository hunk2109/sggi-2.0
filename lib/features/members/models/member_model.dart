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
  final double creditBalance;
  final String? role;
  final bool notificationsEnabled;
  final bool receiveEmails;
  final bool receiveWhatsapp;

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
    this.creditBalance = 0.0,
    this.role,
    this.notificationsEnabled = true,
    this.receiveEmails = true,
    this.receiveWhatsapp = true,
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
    if (!hasMembership || activePlanName == null) return 'Sin Plan';
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
    Map<String, dynamic>? activeMem = json['activeMembership'] as Map<String, dynamic>?;

    if (activeMem != null && activeMem['isActive'] == false) {
      activeMem = null;
    }

    if (activeMem == null) {
      final currentMem = json['currentMembership'] as Map<String, dynamic>?;
      if (currentMem != null && currentMem['isActive'] == true) {
        activeMem = currentMem;
      }
    }

    if (activeMem == null && json['memberships'] is List && (json['memberships'] as List).isNotEmpty) {
      final list = json['memberships'] as List;
      final found = list.firstWhere(
        (m) => m is Map && m['isActive'] == true,
        orElse: () => null,
      );
      if (found is Map) {
        activeMem = found.cast<String, dynamic>();
      }
    }

    if (activeMem != null && activeMem['isActive'] != false) {
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

    final bool hasMem = activeMem != null && activeMem['isActive'] == true && json['hasMembership'] != false;

    if (!hasMem) {
      planName = null;
      planId = null;
      endDate = null;
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
      creditBalance: double.tryParse(json['creditBalance']?.toString() ?? '') ?? 0.0,
      role: userMap?['role']?.toString() ?? json['role']?.toString(),
      notificationsEnabled: json['notificationsEnabled'] != null
          ? (json['notificationsEnabled'] == true || json['notificationsEnabled'] == 1 || json['notificationsEnabled'] == 'true')
          : true,
      receiveEmails: json['receiveEmails'] != null
          ? (json['receiveEmails'] == true || json['receiveEmails'] == 1 || json['receiveEmails'] == 'true')
          : true,
      receiveWhatsapp: json['receiveWhatsapp'] != null
          ? (json['receiveWhatsapp'] == true || json['receiveWhatsapp'] == 1 || json['receiveWhatsapp'] == 'true')
          : true,
    );
  }

  MemberModel copyWith({
    String? id,
    String? userId,
    String? memberCode,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? documentId,
    String? gender,
    DateTime? dateOfBirth,
    String? address,
    String? emergencyContact,
    String? emergencyPhone,
    DateTime? joinDate,
    bool? isPaid,
    bool? hasMembership,
    bool? hasPendingPayment,
    String? activePlanName,
    String? activePlanId,
    DateTime? membershipEndDate,
    bool? isSuspended,
    double? creditBalance,
    String? role,
    bool? notificationsEnabled,
    bool? receiveEmails,
    bool? receiveWhatsapp,
  }) {
    return MemberModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      memberCode: memberCode ?? this.memberCode,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      documentId: documentId ?? this.documentId,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      joinDate: joinDate ?? this.joinDate,
      isPaid: isPaid ?? this.isPaid,
      hasMembership: hasMembership ?? this.hasMembership,
      hasPendingPayment: hasPendingPayment ?? this.hasPendingPayment,
      activePlanName: activePlanName ?? this.activePlanName,
      activePlanId: activePlanId ?? this.activePlanId,
      membershipEndDate: membershipEndDate ?? this.membershipEndDate,
      isSuspended: isSuspended ?? this.isSuspended,
      creditBalance: creditBalance ?? this.creditBalance,
      role: role ?? this.role,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      receiveEmails: receiveEmails ?? this.receiveEmails,
      receiveWhatsapp: receiveWhatsapp ?? this.receiveWhatsapp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
