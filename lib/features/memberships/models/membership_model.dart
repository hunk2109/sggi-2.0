enum MembershipType {
  individual,
  group;

  static MembershipType fromString(String? type) {
    if (type?.toLowerCase() == 'group') return MembershipType.group;
    return MembershipType.individual;
  }

  String get label {
    switch (this) {
      case MembershipType.individual:
        return 'Individual';
      case MembershipType.group:
        return 'Grupal';
    }
  }
}

class MembershipModel {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int durationMonths;
  final int? durationDays;
  final MembershipType type;
  final bool isActive;
  final bool isRecurring;
  final String priceType; // 'fixed' | 'variable'
  final double? pricePerCompanion;
  final int? maxGroupCompanions;
  final List<String> benefits;
  final List<Map<String, dynamic>> accessSchedules;

  MembershipModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.durationMonths = 1,
    this.durationDays,
    this.type = MembershipType.individual,
    this.isActive = true,
    this.isRecurring = true,
    this.priceType = 'fixed',
    this.pricePerCompanion,
    this.maxGroupCompanions,
    this.benefits = const [],
    this.accessSchedules = const [],
  });

  String get durationLabel {
    if (durationDays != null && durationDays! > 0) {
      return '$durationDays ${durationDays == 1 ? "día" : "días"}';
    }
    if (durationMonths == 1) return '1 mes';
    if (durationMonths == 12) return '1 año (12 meses)';
    return '$durationMonths meses';
  }

  MembershipModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? durationMonths,
    int? durationDays,
    MembershipType? type,
    bool? isActive,
    bool? isRecurring,
    String? priceType,
    double? pricePerCompanion,
    int? maxGroupCompanions,
    List<String>? benefits,
    List<Map<String, dynamic>>? accessSchedules,
  }) {
    return MembershipModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      durationMonths: durationMonths ?? this.durationMonths,
      durationDays: durationDays ?? this.durationDays,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      isRecurring: isRecurring ?? this.isRecurring,
      priceType: priceType ?? this.priceType,
      pricePerCompanion: pricePerCompanion ?? this.pricePerCompanion,
      maxGroupCompanions: maxGroupCompanions ?? this.maxGroupCompanions,
      benefits: benefits ?? this.benefits,
      accessSchedules: accessSchedules ?? this.accessSchedules,
    );
  }

  factory MembershipModel.fromJson(Map<String, dynamic> json) {
    double parsedPrice = 0.0;
    final rawPrice = json['price'];
    if (rawPrice is num) {
      parsedPrice = rawPrice.toDouble();
    } else if (rawPrice is String) {
      parsedPrice = double.tryParse(rawPrice) ?? 0.0;
    }

    int parsedMonths = 1;
    final rawMonths = json['durationMonths'];
    if (rawMonths is num) {
      parsedMonths = rawMonths.toInt();
    } else if (rawMonths is String) {
      parsedMonths = (double.tryParse(rawMonths) ?? 1.0).toInt();
    }

    int? parsedDays;
    final rawDays = json['durationDays'];
    if (rawDays is num) {
      parsedDays = rawDays.toInt();
    } else if (rawDays is String) {
      parsedDays = int.tryParse(rawDays);
    }

    List<String> parsedBenefits = [];
    final rawBenefits = json['benefits'];
    if (rawBenefits is List) {
      parsedBenefits = rawBenefits.map((e) => e.toString()).toList();
    } else if (rawBenefits is String && rawBenefits.isNotEmpty) {
      parsedBenefits = rawBenefits.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    List<Map<String, dynamic>> parsedSchedules = [];
    final rawSchedules = json['accessSchedules'];
    if (rawSchedules is List) {
      parsedSchedules = rawSchedules.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }

    double? parsedCompanionPrice;
    final rawCompanion = json['pricePerCompanion'];
    if (rawCompanion is num) {
      parsedCompanionPrice = rawCompanion.toDouble();
    } else if (rawCompanion is String) {
      parsedCompanionPrice = double.tryParse(rawCompanion);
    }

    int? parsedMaxCompanions;
    final rawMax = json['maxGroupCompanions'];
    if (rawMax is num) {
      parsedMaxCompanions = rawMax.toInt();
    } else if (rawMax is String) {
      parsedMaxCompanions = int.tryParse(rawMax);
    }

    return MembershipModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sin nombre',
      description: json['description']?.toString(),
      price: parsedPrice,
      durationMonths: parsedMonths,
      durationDays: parsedDays,
      type: MembershipType.fromString(json['type']?.toString()),
      isActive: json['isActive'] == true || json['isActive'] == 1,
      isRecurring: json['isRecurring'] == null ? true : (json['isRecurring'] == true || json['isRecurring'] == 1),
      priceType: json['priceType']?.toString() ?? 'fixed',
      pricePerCompanion: parsedCompanionPrice,
      maxGroupCompanions: parsedMaxCompanions,
      benefits: parsedBenefits,
      accessSchedules: parsedSchedules,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null && description!.trim().isNotEmpty) 'description': description!.trim(),
      'price': price,
      'durationMonths': durationMonths,
      if (durationDays != null && durationDays! > 0) 'durationDays': durationDays,
      'type': type == MembershipType.group ? 'group' : 'individual',
      'isActive': isActive,
      'isRecurring': isRecurring,
      'priceType': priceType,
      if (pricePerCompanion != null && pricePerCompanion! > 0) 'pricePerCompanion': pricePerCompanion,
      if (maxGroupCompanions != null && maxGroupCompanions! > 0) 'maxGroupCompanions': maxGroupCompanions,
      'benefits': benefits,
    };
  }
}
