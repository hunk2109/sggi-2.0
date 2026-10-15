class CampaignModel {
  final String id;
  final String name;
  final String audience;
  final String channel;
  final String messageTemplate;
  final String? attachedCouponCode;
  final String status;
  final DateTime? scheduledAt;
  final int recipientsCount;
  final int successfulSends;
  final int failedSends;
  final DateTime createdAt;

  CampaignModel({
    required this.id,
    required this.name,
    required this.audience,
    required this.channel,
    required this.messageTemplate,
    this.attachedCouponCode,
    required this.status,
    this.scheduledAt,
    required this.recipientsCount,
    required this.successfulSends,
    required this.failedSends,
    required this.createdAt,
  });

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    return CampaignModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Campaña sin nombre',
      audience: json['audience']?.toString() ?? 'ALL',
      channel: json['channel']?.toString() ?? 'BOTH',
      messageTemplate: json['messageTemplate']?.toString() ?? '',
      attachedCouponCode: json['attachedCouponCode']?.toString(),
      status: json['status']?.toString() ?? 'COMPLETED',
      scheduledAt: json['scheduledAt'] != null ? DateTime.tryParse(json['scheduledAt'].toString())?.toLocal() : null,
      recipientsCount: (json['recipientsCount'] as num?)?.toInt() ?? 0,
      successfulSends: (json['successfulSends'] as num?)?.toInt() ?? 0,
      failedSends: (json['failedSends'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? ((DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()).toLocal())
          : DateTime.now(),
    );
  }

  String get audienceLabel {
    switch (audience) {
      case 'ALL':
        return 'Todos los Socios';
      case 'ACTIVE':
        return 'Socios Activos';
      case 'INACTIVE':
        return 'Socios Inactivos';
      case 'EXPIRING_SOON':
        return 'Próximos a Vencer (7 días)';
      case 'CUSTOM':
        return 'Selección Manual';
      default:
        return audience;
    }
  }

  String get channelLabel {
    switch (channel) {
      case 'WHATSAPP':
        return 'WhatsApp';
      case 'EMAIL':
        return 'Correo Electrónico';
      case 'BOTH':
        return 'WhatsApp + Correo';
      default:
        return channel;
    }
  }
}

class CampaignTemplateModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final String defaultChannel;
  final String message;
  final List<String> variables;

  CampaignTemplateModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.defaultChannel,
    required this.message,
    required this.variables,
  });

  factory CampaignTemplateModel.fromJson(Map<String, dynamic> json) {
    return CampaignTemplateModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      description: json['description']?.toString() ?? '',
      defaultChannel: json['defaultChannel']?.toString() ?? 'BOTH',
      message: json['message']?.toString() ?? '',
      variables: (json['variables'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
