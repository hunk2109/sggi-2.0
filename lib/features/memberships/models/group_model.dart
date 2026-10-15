class GroupCompanionModel {
  final String id;
  final String groupId;
  final String memberId;
  final String relationship;
  final String status;
  final String memberName;
  final String? memberCode;
  final String? memberPhone;
  final String? memberEmail;
  final DateTime? createdAt;

  GroupCompanionModel({
    required this.id,
    required this.groupId,
    required this.memberId,
    required this.relationship,
    this.status = 'active',
    required this.memberName,
    this.memberCode,
    this.memberPhone,
    this.memberEmail,
    this.createdAt,
  });

  factory GroupCompanionModel.fromJson(Map<String, dynamic> json) {
    String name = 'Socio Familiar';
    String? code;
    String? phone;
    String? email;

    final memberMap = json['member'] as Map<String, dynamic>?;
    if (memberMap != null) {
      code = memberMap['memberCode']?.toString();
      final userMap = memberMap['user'] as Map<String, dynamic>?;
      if (userMap != null) {
        final fName = userMap['firstName']?.toString() ?? '';
        final lName = userMap['lastName']?.toString() ?? '';
        final full = '$fName $lName'.trim();
        if (full.isNotEmpty) name = full;
        email = userMap['email']?.toString();
        phone = userMap['phone']?.toString();
      } else {
        final fName = memberMap['firstName']?.toString() ?? '';
        final lName = memberMap['lastName']?.toString() ?? '';
        final full = '$fName $lName'.trim();
        if (full.isNotEmpty) name = full;
        email = memberMap['email']?.toString();
        phone = memberMap['phone']?.toString();
      }
    }

    DateTime? created;
    if (json['createdAt'] != null) {
      created = DateTime.tryParse(json['createdAt'].toString())?.toLocal();
    }

    return GroupCompanionModel(
      id: json['id']?.toString() ?? '',
      groupId: json['groupId']?.toString() ?? '',
      memberId: json['memberId']?.toString() ?? '',
      relationship: json['relationship']?.toString() ?? 'Familiar',
      status: json['status']?.toString() ?? 'active',
      memberName: name,
      memberCode: code,
      memberPhone: phone,
      memberEmail: email,
      createdAt: created,
    );
  }
}

class GroupModel {
  final String id;
  final String name;
  final String? description;
  final String membershipId;
  final String? membershipName;
  final int? maxGroupCompanions;
  final double? pricePerCompanion;
  final String responsibleUserId;
  final String? responsibleUserName;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final int companionCount;
  final List<GroupCompanionModel> companions;

  GroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.membershipId,
    this.membershipName,
    this.maxGroupCompanions,
    this.pricePerCompanion,
    required this.responsibleUserId,
    this.responsibleUserName,
    this.startDate,
    this.endDate,
    this.status = 'active',
    this.companionCount = 0,
    this.companions = const [],
  });

  bool get isActive => status == 'active';
  int get maxCompanions => maxGroupCompanions ?? 0;
  bool get canAddCompanions => maxCompanions == 0 || companions.length < maxCompanions;
  int get availableSlots => maxCompanions > 0 ? (maxCompanions - companions.length).clamp(0, 999) : 999;

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    String? memName;
    int? maxCompanions;
    double? companionPrice;

    final memMap = json['membership'] as Map<String, dynamic>?;
    if (memMap != null) {
      memName = memMap['name']?.toString();
      if (memMap['maxGroupCompanions'] != null) {
        maxCompanions = int.tryParse(memMap['maxGroupCompanions'].toString());
      }
      if (memMap['pricePerCompanion'] != null) {
        companionPrice = double.tryParse(memMap['pricePerCompanion'].toString());
      }
    }

    String? respName;
    final respUser = json['responsibleUser'] as Map<String, dynamic>?;
    if (respUser != null) {
      final f = respUser['firstName']?.toString() ?? '';
      final l = respUser['lastName']?.toString() ?? '';
      respName = '$f $l'.trim();
    }

    List<GroupCompanionModel> comps = [];
    if (json['companions'] is List) {
      comps = (json['companions'] as List)
          .whereType<Map<String, dynamic>>()
          .map((c) => GroupCompanionModel.fromJson(c))
          .toList();
    }

    DateTime? sDate;
    if (json['startDate'] != null) {
      sDate = DateTime.tryParse(json['startDate'].toString())?.toLocal();
    }
    DateTime? eDate;
    if (json['endDate'] != null) {
      eDate = DateTime.tryParse(json['endDate'].toString())?.toLocal();
    }

    return GroupModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Grupo Familiar',
      description: json['description']?.toString(),
      membershipId: json['membershipId']?.toString() ?? '',
      membershipName: memName,
      maxGroupCompanions: maxCompanions,
      pricePerCompanion: companionPrice,
      responsibleUserId: json['responsibleUserId']?.toString() ?? '',
      responsibleUserName: respName,
      startDate: sDate,
      endDate: eDate,
      status: json['status']?.toString() ?? 'active',
      companionCount: json['companionCount'] is int
          ? json['companionCount']
          : int.tryParse(json['companionCount']?.toString() ?? '0') ?? comps.length,
      companions: comps,
    );
  }
}
