class GymSettingsModel {
  final String? id;
  final String gymName;
  final String? description;
  final String? address;
  final String? phone;
  final String? email;
  final String? rnc;
  final String? website;
  final String? openingTime;
  final String? closingTime;
  final double membershipPrice;
  final int membershipSuspensionDays;
  final String? policies;
  final String? notificationChannel;
  final String? closingReportTime1;
  final String? closingReportTime2;
  final String? closingReportRecipients;
  final String? logoImage;
  final bool mb360Enabled;
  final String? mb360Ip;
  final int? mb360Port;
  final String ticketPaperSize; // '80mm', '70mm', '58mm', 'a4'
  final bool enableMembershipRenewal;
  final bool enablePaymentReminders;
  final bool enableBirthdayEmails;
  final bool enableAnniversaryEmails;
  final bool enableExpirationWarnings;
  final bool enableCampaignScheduler;
  final bool enableDailySummaryReport;

  GymSettingsModel({
    this.id,
    this.gymName = 'GYM Manager',
    this.description,
    this.address,
    this.phone,
    this.email,
    this.rnc,
    this.website,
    this.openingTime = '06:00',
    this.closingTime = '22:00',
    this.membershipPrice = 0.0,
    this.membershipSuspensionDays = 15,
    this.policies,
    this.notificationChannel = 'both',
    this.closingReportTime1 = '12:00',
    this.closingReportTime2 = '21:00',
    this.closingReportRecipients,
    this.logoImage,
    this.mb360Enabled = false,
    this.mb360Ip,
    this.mb360Port,
    this.ticketPaperSize = '80mm',
    this.enableMembershipRenewal = true,
    this.enablePaymentReminders = true,
    this.enableBirthdayEmails = true,
    this.enableAnniversaryEmails = true,
    this.enableExpirationWarnings = true,
    this.enableCampaignScheduler = true,
    this.enableDailySummaryReport = true,
  });

  factory GymSettingsModel.fromJson(Map<String, dynamic> json) {
    return GymSettingsModel(
      id: json['id']?.toString(),
      gymName: json['gymName']?.toString() ?? 'GYM Manager',
      description: json['description']?.toString(),
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      rnc: json['rnc']?.toString(),
      website: json['website']?.toString(),
      openingTime: json['openingTime']?.toString() ?? '06:00',
      closingTime: json['closingTime']?.toString() ?? '22:00',
      membershipPrice: (json['membershipPrice'] is num)
          ? (json['membershipPrice'] as num).toDouble()
          : double.tryParse(json['membershipPrice']?.toString() ?? '0') ?? 0.0,
      membershipSuspensionDays: (json['membershipSuspensionDays'] is num)
          ? (json['membershipSuspensionDays'] as num).toInt()
          : int.tryParse(json['membershipSuspensionDays']?.toString() ?? '15') ?? 15,
      policies: json['policies']?.toString(),
      notificationChannel: json['notificationChannel']?.toString() ?? 'both',
      closingReportTime1: json['closingReportTime1']?.toString() ?? '12:00',
      closingReportTime2: json['closingReportTime2']?.toString() ?? '21:00',
      closingReportRecipients: json['closingReportRecipients']?.toString(),
      logoImage: json['logoImage']?.toString(),
      mb360Enabled: json['mb360Enabled'] == true || json['mb360Enabled'] == 1,
      mb360Ip: json['mb360Ip']?.toString(),
      mb360Port: (json['mb360Port'] is num)
          ? (json['mb360Port'] as num).toInt()
          : int.tryParse(json['mb360Port']?.toString() ?? ''),
      ticketPaperSize: json['ticketPaperSize']?.toString() ?? '80mm',
      enableMembershipRenewal: json['enableMembershipRenewal'] != false,
      enablePaymentReminders: json['enablePaymentReminders'] != false,
      enableBirthdayEmails: json['enableBirthdayEmails'] != false,
      enableAnniversaryEmails: json['enableAnniversaryEmails'] != false,
      enableExpirationWarnings: json['enableExpirationWarnings'] != false,
      enableCampaignScheduler: json['enableCampaignScheduler'] != false,
      enableDailySummaryReport: json['enableDailySummaryReport'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gymName': gymName,
      'description': description ?? '',
      'address': address ?? '',
      'phone': phone ?? '',
      'email': email ?? '',
      'rnc': rnc ?? '',
      'website': website ?? '',
      'openingTime': openingTime ?? '06:00',
      'closingTime': closingTime ?? '22:00',
      'membershipPrice': membershipPrice,
      'membershipSuspensionDays': membershipSuspensionDays,
      'policies': policies ?? '',
      'notificationChannel': notificationChannel ?? 'both',
      'closingReportTime1': closingReportTime1 ?? '12:00',
      'closingReportTime2': closingReportTime2 ?? '21:00',
      if (closingReportRecipients != null) 'closingReportRecipients': closingReportRecipients,
      if (logoImage != null) 'logoImage': logoImage,
      'mb360Enabled': mb360Enabled,
      if (mb360Ip != null) 'mb360Ip': mb360Ip,
      if (mb360Port != null) 'mb360Port': mb360Port,
      'ticketPaperSize': ticketPaperSize,
      'enableMembershipRenewal': enableMembershipRenewal,
      'enablePaymentReminders': enablePaymentReminders,
      'enableBirthdayEmails': enableBirthdayEmails,
      'enableAnniversaryEmails': enableAnniversaryEmails,
      'enableExpirationWarnings': enableExpirationWarnings,
      'enableCampaignScheduler': enableCampaignScheduler,
      'enableDailySummaryReport': enableDailySummaryReport,
    };
  }

  GymSettingsModel copyWith({
    String? id,
    String? gymName,
    String? description,
    String? address,
    String? phone,
    String? email,
    String? rnc,
    String? website,
    String? openingTime,
    String? closingTime,
    double? membershipPrice,
    int? membershipSuspensionDays,
    String? policies,
    String? notificationChannel,
    String? closingReportTime1,
    String? closingReportTime2,
    String? closingReportRecipients,
    String? logoImage,
    bool? mb360Enabled,
    String? mb360Ip,
    int? mb360Port,
    String? ticketPaperSize,
    bool? enableMembershipRenewal,
    bool? enablePaymentReminders,
    bool? enableBirthdayEmails,
    bool? enableAnniversaryEmails,
    bool? enableExpirationWarnings,
    bool? enableCampaignScheduler,
    bool? enableDailySummaryReport,
  }) {
    return GymSettingsModel(
      id: id ?? this.id,
      gymName: gymName ?? this.gymName,
      description: description ?? this.description,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      rnc: rnc ?? this.rnc,
      website: website ?? this.website,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      membershipPrice: membershipPrice ?? this.membershipPrice,
      membershipSuspensionDays: membershipSuspensionDays ?? this.membershipSuspensionDays,
      policies: policies ?? this.policies,
      notificationChannel: notificationChannel ?? this.notificationChannel,
      closingReportTime1: closingReportTime1 ?? this.closingReportTime1,
      closingReportTime2: closingReportTime2 ?? this.closingReportTime2,
      closingReportRecipients: closingReportRecipients ?? this.closingReportRecipients,
      logoImage: logoImage ?? this.logoImage,
      mb360Enabled: mb360Enabled ?? this.mb360Enabled,
      mb360Ip: mb360Ip ?? this.mb360Ip,
      mb360Port: mb360Port ?? this.mb360Port,
      ticketPaperSize: ticketPaperSize ?? this.ticketPaperSize,
      enableMembershipRenewal: enableMembershipRenewal ?? this.enableMembershipRenewal,
      enablePaymentReminders: enablePaymentReminders ?? this.enablePaymentReminders,
      enableBirthdayEmails: enableBirthdayEmails ?? this.enableBirthdayEmails,
      enableAnniversaryEmails: enableAnniversaryEmails ?? this.enableAnniversaryEmails,
      enableExpirationWarnings: enableExpirationWarnings ?? this.enableExpirationWarnings,
      enableCampaignScheduler: enableCampaignScheduler ?? this.enableCampaignScheduler,
      enableDailySummaryReport: enableDailySummaryReport ?? this.enableDailySummaryReport,
    );
  }
}
