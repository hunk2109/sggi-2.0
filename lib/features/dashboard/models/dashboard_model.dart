class DashboardOverviewModel {
  final double todayRevenue;
  final double todaySalesRevenue;
  final double todayMembershipRevenue;
  final int todaySalesCount;
  final int todayCheckinsCount;
  final int expiringMembershipsCount;
  final int totalMembers;
  final int activeMembers;
  final int inactiveMembers;
  final bool cashShiftOpen;
  final String? cashierName;
  final double shiftOpeningAmount;
  final String? shiftOpenedAt;
  final bool syncConfigured;
  final String? syncDbPath;
  final String? deviceIp;
  final List<MonthlySaleStat> monthlySales;
  final List<RevenueDistributionItem> revenueDistribution;
  final List<TopProductItem> topProducts;
  final List<RecentAttendanceItem> recentAttendances;
  final List<RecentSaleItem> recentSales;

  DashboardOverviewModel({
    required this.todayRevenue,
    required this.todaySalesRevenue,
    required this.todayMembershipRevenue,
    required this.todaySalesCount,
    required this.todayCheckinsCount,
    required this.expiringMembershipsCount,
    required this.totalMembers,
    required this.activeMembers,
    required this.inactiveMembers,
    required this.cashShiftOpen,
    this.cashierName,
    required this.shiftOpeningAmount,
    this.shiftOpenedAt,
    required this.syncConfigured,
    this.syncDbPath,
    this.deviceIp,
    required this.monthlySales,
    required this.revenueDistribution,
    required this.topProducts,
    required this.recentAttendances,
    required this.recentSales,
  });

  factory DashboardOverviewModel.fromJson(Map<String, dynamic> json) {
    final today = json['today'] as Map<String, dynamic>? ?? {};
    final members = json['members'] as Map<String, dynamic>? ?? {};
    final shift = json['cashShift'] as Map<String, dynamic>? ?? {};
    final sync = json['syncStatus'] as Map<String, dynamic>? ?? {};

    final monthly = (json['monthlySales'] as List?)
            ?.map((e) => MonthlySaleStat.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final dist = (json['revenueComparison'] as List?)
            ?.map((e) => RevenueDistributionItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final products = (json['topProducts'] as List?)
            ?.map((e) => TopProductItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final attendances = (json['recentAttendances'] as List?)
            ?.map((e) => RecentAttendanceItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final sales = (json['recentSales'] as List?)
            ?.map((e) => RecentSaleItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return DashboardOverviewModel(
      todayRevenue: _toDouble(today['totalRevenue']),
      todaySalesRevenue: _toDouble(today['salesRevenue']),
      todayMembershipRevenue: _toDouble(today['membershipRevenue']),
      todaySalesCount: _toInt(today['salesCount']),
      todayCheckinsCount: _toInt(today['checkinsCount']),
      expiringMembershipsCount: _toInt(today['expiringMembershipsCount']),
      totalMembers: _toInt(members['total']),
      activeMembers: _toInt(members['active']),
      inactiveMembers: _toInt(members['inactive']),
      cashShiftOpen: shift['isOpen'] == true,
      cashierName: shift['cashierName']?.toString(),
      shiftOpeningAmount: _toDouble(shift['openingAmount']),
      shiftOpenedAt: shift['openedAt']?.toString(),
      syncConfigured: sync['isConfigured'] == true,
      syncDbPath: sync['dbPath']?.toString(),
      deviceIp: sync['deviceIp']?.toString(),
      monthlySales: monthly,
      revenueDistribution: dist,
      topProducts: products,
      recentAttendances: attendances,
      recentSales: sales,
    );
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  static int _toInt(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? 0;
  }
}

class MonthlySaleStat {
  final int year;
  final int month;
  final int transactionCount;
  final double totalRevenue;

  MonthlySaleStat({
    required this.year,
    required this.month,
    required this.transactionCount,
    required this.totalRevenue,
  });

  factory MonthlySaleStat.fromJson(Map<String, dynamic> json) {
    return MonthlySaleStat(
      year: json['year'] as int? ?? DateTime.now().year,
      month: json['month'] as int? ?? 1,
      transactionCount: json['transactionCount'] as int? ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String get monthName {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return 'Mes $month';
  }
}

class RevenueDistributionItem {
  final String name;
  final double revenue;
  final double percentage;

  RevenueDistributionItem({
    required this.name,
    required this.revenue,
    required this.percentage,
  });

  factory RevenueDistributionItem.fromJson(Map<String, dynamic> json) {
    return RevenueDistributionItem(
      name: json['name']?.toString() ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
      percentage: double.tryParse(json['percentage']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class TopProductItem {
  final String name;
  final int quantity;
  final double revenue;

  TopProductItem({
    required this.name,
    required this.quantity,
    required this.revenue,
  });

  factory TopProductItem.fromJson(Map<String, dynamic> json) {
    return TopProductItem(
      name: json['name']?.toString() ?? 'Producto',
      quantity: json['quantity'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RecentAttendanceItem {
  final String id;
  final String name;
  final String memberCode;
  final String type;
  final String status;
  final DateTime? time;

  RecentAttendanceItem({
    required this.id,
    required this.name,
    required this.memberCode,
    required this.type,
    required this.status,
    this.time,
  });

  factory RecentAttendanceItem.fromJson(Map<String, dynamic> json) {
    DateTime? parsedTime;
    if (json['time'] != null) {
      parsedTime = DateTime.tryParse(json['time'].toString());
    }
    return RecentAttendanceItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Socio',
      memberCode: json['memberCode']?.toString() ?? '',
      type: json['type']?.toString() ?? 'member',
      status: json['status']?.toString() ?? 'accepted',
      time: parsedTime,
    );
  }
}

class RecentSaleItem {
  final String id;
  final String? invoiceNumber;
  final String clientName;
  final double amount;
  final String paymentMethod;
  final DateTime? time;

  RecentSaleItem({
    required this.id,
    this.invoiceNumber,
    required this.clientName,
    required this.amount,
    required this.paymentMethod,
    this.time,
  });

  factory RecentSaleItem.fromJson(Map<String, dynamic> json) {
    DateTime? parsedTime;
    if (json['time'] != null) {
      parsedTime = DateTime.tryParse(json['time'].toString());
    }
    return RecentSaleItem(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString(),
      clientName: json['clientName']?.toString() ?? 'Cliente mostrador',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod']?.toString() ?? 'cash',
      time: parsedTime,
    );
  }
}
