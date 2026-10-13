class ApiConstants {
  static const String baseUrl = 'http://localhost:3000/api';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Auth endpoints
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/profile';

  // Core endpoints
  static const String members = '/members';
  static const String memberships = '/memberships';
  static const String memberMemberships = '/member-memberships';
  static const String sales = '/sales';
  static const String products = '/products';
  static const String cashRegister = '/cash-register';
  static const String attendances = '/attendances';
  static const String sync = '/sync';
}
