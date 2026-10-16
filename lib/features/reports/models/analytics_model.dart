class PeriodData {
  final String startDate;
  final String endDate;
  final String range;

  PeriodData({
    required this.startDate,
    required this.endDate,
    required this.range,
  });

  factory PeriodData.fromJson(Map<String, dynamic> json) {
    return PeriodData(
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      range: json['range']?.toString() ?? 'monthly',
    );
  }
}

class FinancialData {
  final double totalRevenue;
  final double membershipRevenue;
  final double posSalesRevenue;
  final double totalExpenses;
  final double payrollExpenses;
  final double operationalExpenses;
  final double cashWithdrawals;
  final double netProfit;
  final double profitMarginPercent;
  final double payrollRatioPercent;

  FinancialData({
    required this.totalRevenue,
    required this.membershipRevenue,
    required this.posSalesRevenue,
    required this.totalExpenses,
    required this.payrollExpenses,
    required this.operationalExpenses,
    required this.cashWithdrawals,
    required this.netProfit,
    required this.profitMarginPercent,
    required this.payrollRatioPercent,
  });

  factory FinancialData.fromJson(Map<String, dynamic> json) {
    return FinancialData(
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      membershipRevenue: (json['membershipRevenue'] as num?)?.toDouble() ?? 0.0,
      posSalesRevenue: (json['posSalesRevenue'] as num?)?.toDouble() ?? 0.0,
      totalExpenses: (json['totalExpenses'] as num?)?.toDouble() ?? 0.0,
      payrollExpenses: (json['payrollExpenses'] as num?)?.toDouble() ?? 0.0,
      operationalExpenses: (json['operationalExpenses'] as num?)?.toDouble() ?? 0.0,
      cashWithdrawals: (json['cashWithdrawals'] as num?)?.toDouble() ?? 0.0,
      netProfit: (json['netProfit'] as num?)?.toDouble() ?? 0.0,
      profitMarginPercent: (json['profitMarginPercent'] as num?)?.toDouble() ?? 0.0,
      payrollRatioPercent: (json['payrollRatioPercent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PeakHoursData {
  final int morningCheckins;
  final int afternoonCheckins;
  final int eveningCheckins;
  final String busiestTimeSlot;
  final double busiestPercentage;

  PeakHoursData({
    required this.morningCheckins,
    required this.afternoonCheckins,
    required this.eveningCheckins,
    required this.busiestTimeSlot,
    required this.busiestPercentage,
  });

  factory PeakHoursData.fromJson(Map<String, dynamic> json) {
    return PeakHoursData(
      morningCheckins: (json['morningCheckins'] as num?)?.toInt() ?? 0,
      afternoonCheckins: (json['afternoonCheckins'] as num?)?.toInt() ?? 0,
      eveningCheckins: (json['eveningCheckins'] as num?)?.toInt() ?? 0,
      busiestTimeSlot: json['busiestTimeSlot']?.toString() ?? 'N/A',
      busiestPercentage: (json['busiestPercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class WeekdayCheckin {
  final String day;
  final int checkins;

  WeekdayCheckin({
    required this.day,
    required this.checkins,
  });

  factory WeekdayCheckin.fromJson(Map<String, dynamic> json) {
    return WeekdayCheckin(
      day: json['day']?.toString() ?? '',
      checkins: (json['checkins'] as num?)?.toInt() ?? 0,
    );
  }
}

class MembersStatsData {
  final int totalMembers;
  final int activeMembers;
  final int expiredRecentMembers;
  final double retentionRatePercent;
  final double averageRevenuePerActiveMember;

  MembersStatsData({
    required this.totalMembers,
    required this.activeMembers,
    required this.expiredRecentMembers,
    required this.retentionRatePercent,
    required this.averageRevenuePerActiveMember,
  });

  factory MembersStatsData.fromJson(Map<String, dynamic> json) {
    return MembersStatsData(
      totalMembers: (json['totalMembers'] as num?)?.toInt() ?? 0,
      activeMembers: (json['activeMembers'] as num?)?.toInt() ?? 0,
      expiredRecentMembers: (json['expiredRecentMembers'] as num?)?.toInt() ?? 0,
      retentionRatePercent: (json['retentionRatePercent'] as num?)?.toDouble() ?? 0.0,
      averageRevenuePerActiveMember: (json['averageRevenuePerActiveMember'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class BehaviorData {
  final int totalCheckins;
  final PeakHoursData peakHours;
  final List<WeekdayCheckin> weekdays;
  final MembersStatsData membersStats;

  BehaviorData({
    required this.totalCheckins,
    required this.peakHours,
    required this.weekdays,
    required this.membersStats,
  });

  factory BehaviorData.fromJson(Map<String, dynamic> json) {
    return BehaviorData(
      totalCheckins: (json['totalCheckins'] as num?)?.toInt() ?? 0,
      peakHours: PeakHoursData.fromJson(json['peakHours'] as Map<String, dynamic>? ?? {}),
      weekdays: ((json['weekdays'] as List<dynamic>?) ?? [])
          .map((item) => WeekdayCheckin.fromJson(item as Map<String, dynamic>))
          .toList(),
      membersStats: MembersStatsData.fromJson(json['membersStats'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class RecommendationItem {
  final String id;
  final String category; // 'FINANCIAL' | 'OPERATIONS' | 'RETENTION' | 'SALES'
  final String priority; // 'HIGH' | 'MEDIUM' | 'LOW'
  final String title;
  final String description;
  final String? actionLabel;

  RecommendationItem({
    required this.id,
    required this.category,
    required this.priority,
    required this.title,
    required this.description,
    this.actionLabel,
  });

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? 'OPERATIONS',
      priority: json['priority']?.toString() ?? 'MEDIUM',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      actionLabel: json['actionLabel']?.toString(),
    );
  }
}

class FinancialAnalyticsModel {
  final PeriodData period;
  final FinancialData financial;
  final BehaviorData behavior;
  final List<RecommendationItem> recommendations;

  FinancialAnalyticsModel({
    required this.period,
    required this.financial,
    required this.behavior,
    required this.recommendations,
  });

  factory FinancialAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return FinancialAnalyticsModel(
      period: PeriodData.fromJson(json['period'] as Map<String, dynamic>? ?? {}),
      financial: FinancialData.fromJson(json['financial'] as Map<String, dynamic>? ?? {}),
      behavior: BehaviorData.fromJson(json['behavior'] as Map<String, dynamic>? ?? {}),
      recommendations: ((json['recommendations'] as List<dynamic>?) ?? [])
          .map((item) => RecommendationItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
