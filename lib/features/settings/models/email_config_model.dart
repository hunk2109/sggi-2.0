class EmailConfigModel {
  final String? id;
  final String provider; // 'GOOGLE', 'MICROSOFT', 'SMTP'
  final String email;
  final String? password;
  final String? senderName;
  final String? smtpHost;
  final int? smtpPort;
  final String? smtpUser;
  final String? smtpPassword;
  final bool useSSL;
  final bool useTLS;
  final bool isActive;
  final bool isVerified;
  final String? verificationError;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EmailConfigModel({
    this.id,
    this.provider = 'GOOGLE',
    this.email = '',
    this.password,
    this.senderName,
    this.smtpHost,
    this.smtpPort = 587,
    this.smtpUser,
    this.smtpPassword,
    this.useSSL = false,
    this.useTLS = true,
    this.isActive = true,
    this.isVerified = false,
    this.verificationError,
    this.createdAt,
    this.updatedAt,
  });

  factory EmailConfigModel.fromJson(Map<String, dynamic> json) {
    return EmailConfigModel(
      id: json['id']?.toString(),
      provider: json['provider']?.toString() ?? 'GOOGLE',
      email: json['email']?.toString() ?? '',
      password: json['password']?.toString(),
      senderName: json['senderName']?.toString(),
      smtpHost: json['smtpHost']?.toString(),
      smtpPort: json['smtpPort'] is int
          ? json['smtpPort']
          : int.tryParse(json['smtpPort']?.toString() ?? '587'),
      smtpUser: json['smtpUser']?.toString(),
      smtpPassword: json['smtpPassword']?.toString(),
      useSSL: json['useSSL'] == true || json['useSSL'] == 1,
      useTLS: json['useTLS'] == true || json['useTLS'] == 1,
      isActive: json['isActive'] == true || json['isActive'] == 1,
      isVerified: json['isVerified'] == true || json['isVerified'] == 1,
      verificationError: json['verificationError']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'provider': provider,
      'email': email.trim(),
      'useSSL': useSSL,
      'useTLS': useTLS,
      'isActive': isActive,
    };

    if (id != null && id!.isNotEmpty) map['id'] = id;
    if (password != null && password!.isNotEmpty) map['password'] = password;
    if (senderName != null && senderName!.isNotEmpty) map['senderName'] = senderName;

    if (provider == 'SMTP') {
      if (smtpHost != null && smtpHost!.isNotEmpty) map['smtpHost'] = smtpHost;
      if (smtpPort != null) map['smtpPort'] = smtpPort;
      if (smtpUser != null && smtpUser!.isNotEmpty) map['smtpUser'] = smtpUser;
      if (smtpPassword != null && smtpPassword!.isNotEmpty) map['smtpPassword'] = smtpPassword;
    }

    return map;
  }

  EmailConfigModel copyWith({
    String? id,
    String? provider,
    String? email,
    String? password,
    String? senderName,
    String? smtpHost,
    int? smtpPort,
    String? smtpUser,
    String? smtpPassword,
    bool? useSSL,
    bool? useTLS,
    bool? isActive,
    bool? isVerified,
    String? verificationError,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmailConfigModel(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      email: email ?? this.email,
      password: password ?? this.password,
      senderName: senderName ?? this.senderName,
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      smtpUser: smtpUser ?? this.smtpUser,
      smtpPassword: smtpPassword ?? this.smtpPassword,
      useSSL: useSSL ?? this.useSSL,
      useTLS: useTLS ?? this.useTLS,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      verificationError: verificationError ?? this.verificationError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
