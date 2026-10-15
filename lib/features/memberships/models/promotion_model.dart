class PromotionModel {
  final String id;
  final String code;
  final num discountPercentage;
  final String? description;
  final bool capturesBirthday;
  final int? maxUses;
  final int usesCount;
  final bool active;
  final DateTime? expiresAt;
  final bool isValid;
  final int? remainingUses;

  PromotionModel({
    required this.id,
    required this.code,
    required this.discountPercentage,
    this.description,
    this.capturesBirthday = false,
    this.maxUses,
    this.usesCount = 0,
    this.active = true,
    this.expiresAt,
    this.isValid = true,
    this.remainingUses,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: json['id']?.toString() ?? '',
      code: (json['code']?.toString() ?? '').toUpperCase(),
      discountPercentage: json['discountPercentage'] is num
          ? json['discountPercentage']
          : num.tryParse(json['discountPercentage']?.toString() ?? '0') ?? 0,
      description: json['description']?.toString(),
      capturesBirthday: json['capturesBirthday'] == true || json['capturesBirthday'] == 1,
      maxUses: json['maxUses'] != null ? int.tryParse(json['maxUses'].toString()) : null,
      usesCount: json['usesCount'] != null ? int.tryParse(json['usesCount'].toString()) ?? 0 : 0,
      active: json['active'] == true || json['active'] == 1,
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt'].toString())?.toLocal() : null,
      isValid: json['isValid'] != null ? json['isValid'] == true : (json['active'] == true || json['active'] == 1),
      remainingUses: json['remainingUses'] != null ? int.tryParse(json['remainingUses'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'discountPercentage': discountPercentage,
    'description': description,
    'capturesBirthday': capturesBirthday,
    'maxUses': maxUses,
    'usesCount': usesCount,
    'active': active,
    'expiresAt': expiresAt?.toIso8601String(),
    'isValid': isValid,
    'remainingUses': remainingUses,
  };
}

class PromotionValidationResult {
  final bool valid;
  final num discount;
  final String message;
  final String? code;

  PromotionValidationResult({
    required this.valid,
    required this.discount,
    required this.message,
    this.code,
  });

  factory PromotionValidationResult.fromJson(Map<String, dynamic> json, {String? code}) {
    return PromotionValidationResult(
      valid: json['valid'] == true,
      discount: json['discount'] is num
          ? json['discount']
          : num.tryParse(json['discount']?.toString() ?? '0') ?? 0,
      message: json['message']?.toString() ?? '',
      code: code,
    );
  }
}
