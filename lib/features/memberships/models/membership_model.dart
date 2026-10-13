enum MembershipType {
  individual,
  group;

  static MembershipType fromString(String? type) {
    if (type?.toLowerCase() == 'group') return MembershipType.group;
    return MembershipType.individual;
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
  final List<String> benefits;

  MembershipModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.durationMonths = 1,
    this.durationDays,
    this.type = MembershipType.individual,
    this.isActive = true,
    this.benefits = const [],
  });

  String get durationLabel {
    if (durationDays != null && durationDays! > 0) {
      return '$durationDays días';
    }
    if (durationMonths == 1) return '1 mes';
    if (durationMonths == 12) return '1 año (12 meses)';
    return '$durationMonths meses';
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
      parsedMonths = int.tryParse(rawMonths) ?? 1;
    }

    List<String> parsedBenefits = [];
    final rawBenefits = json['benefits'];
    if (rawBenefits is List) {
      parsedBenefits = rawBenefits.map((e) => e.toString()).toList();
    } else if (rawBenefits is String && rawBenefits.isNotEmpty) {
      parsedBenefits = rawBenefits.split(',');
    }

    return MembershipModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sin nombre',
      description: json['description']?.toString(),
      price: parsedPrice,
      durationMonths: parsedMonths,
      durationDays: json['durationDays'] as int?,
      type: MembershipType.fromString(json['type']?.toString()),
      isActive: json['isActive'] == true || json['isActive'] == 1,
      benefits: parsedBenefits,
    );
  }
}
