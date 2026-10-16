class ApiConstants {
  static const String baseUrl = 'http://localhost:3000/api';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Auth endpoints
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/profile';

  // Core endpoints
  static const String members = '/members';
  static const String memberships = '/memberships';
  static const String memberMemberships = '/member-memberships';
  static const String groups = '/groups';
  static const String payments = '/payments';
  static const String sales = '/sales';
  static const String products = '/products';
  static const String cashRegister = '/cash-register';
  static const String attendances = '/attendances';
  static const String employees = '/employees';
  static const String accounting = '/accounting';
  static const String payroll = '/payroll';
  static const String sync = '/sync';
  static const String gymSettings = '/gym-settings';
  static const String whatsappSettings = '/whatsapp-settings';
  static const String emailSettings = '/email-settings';
  static const String campaigns = '/campaigns';
  static const String promotions = '/promotions';
  static const String activePromotions = '/promotions/active';
  static const String validatePromotion = '/promotions/validate';
  static const String userRoles = '/user-roles';
  static const String dashboard = '/dashboard';
  static const String reports = '/reports';
  static const String reportsAnalytics = '/reports/analytics/financial-and-behavior';
}
