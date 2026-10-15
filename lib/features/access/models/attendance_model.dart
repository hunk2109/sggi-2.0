class AttendanceModel {
  final String id;
  final String? memberId;
  final String? memberCode;
  final String memberName;
  final String memberLastName;
  final DateTime visitDate;
  final String status; // 'AUTHORIZED' | 'REJECTED' | 'PERMITTED'
  final String? rejectionReason;
  final String? notes;
  final String? device;
  final String? planName;

  AttendanceModel({
    required this.id,
    this.memberId,
    this.memberCode,
    required this.memberName,
    this.memberLastName = '',
    required this.visitDate,
    required this.status,
    this.rejectionReason,
    this.notes,
    this.device,
    this.planName,
  });

  String get fullName => '$memberName $memberLastName'.trim().isEmpty ? 'Socio Desconocido' : '$memberName $memberLastName'.trim();
  bool get isAuthorized => status.toUpperCase() == 'AUTHORIZED' || status.toUpperCase() == 'PERMITTED';

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    final memberMap = json['member'] as Map<String, dynamic>?;
    final userMap = memberMap?['user'] as Map<String, dynamic>?;

    final fName = json['memberName']?.toString() ??
        userMap?['firstName']?.toString() ??
        memberMap?['firstName']?.toString() ??
        'Socio';
    final lName = json['memberLastName']?.toString() ??
        userMap?['lastName']?.toString() ??
        memberMap?['lastName']?.toString() ??
        '';

    final code = json['memberCode']?.toString() ?? memberMap?['memberCode']?.toString();

    DateTime vDate = DateTime.now();
    final rawDate = json['visitDate']?.toString() ?? json['checkInTime']?.toString() ?? json['createdAt']?.toString();
    if (rawDate != null) {
      vDate = (DateTime.tryParse(rawDate) ?? DateTime.now()).toLocal();
    }

    final reason = json['reason']?.toString() ?? json['rejectionReason']?.toString() ?? json['notes']?.toString();

    return AttendanceModel(
      id: json['id']?.toString() ?? '',
      memberId: json['memberId']?.toString() ?? memberMap?['id']?.toString(),
      memberCode: code,
      memberName: fName,
      memberLastName: lName,
      visitDate: vDate,
      status: json['status']?.toString() ?? (json['success'] == false ? 'REJECTED' : 'AUTHORIZED'),
      rejectionReason: reason,
      notes: json['notes']?.toString(),
      device: json['device']?.toString() ?? 'Torniquete / Recepción',
      planName: json['planName']?.toString(),
    );
  }
}
