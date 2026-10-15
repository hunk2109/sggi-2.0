import 'package:intl/intl.dart';

class AppFormatters {
  /// Formato de moneda para República Dominicana / Norteamérica: RD$ 1,000.00
  static final NumberFormat currency = NumberFormat.currency(
    locale: 'en_US',
    symbol: 'RD\$ ',
    decimalDigits: 2,
  );

  /// Formatea un monto a RD$ 1,000.00
  static String formatCurrency(num? amount) {
    if (amount == null) return 'RD\$ 0.00';
    return currency.format(amount);
  }

  /// Formato estándar de fecha y hora local: 15/10/2026 02:30 PM
  static final DateFormat dateTime = DateFormat('dd/MM/yyyy hh:mm a');

  /// Formato estándar de solo fecha: 15/10/2026
  static final DateFormat dateOnly = DateFormat('dd/MM/yyyy');

  /// Formato estándar de solo hora: 02:30 PM
  static final DateFormat timeOnly = DateFormat('hh:mm a');

  /// Formatea una fecha a hora local
  static String formatDateTime(dynamic date) {
    if (date == null) return '-';
    DateTime? dt;
    if (date is DateTime) {
      dt = date;
    } else {
      dt = DateTime.tryParse(date.toString());
    }
    if (dt == null) return '-';
    return dateTime.format(dt.isUtc ? dt.toLocal() : dt);
  }

  /// Formatea solo la fecha (día/mes/año)
  static String formatDate(dynamic date) {
    if (date == null) return '-';
    DateTime? dt;
    if (date is DateTime) {
      dt = date;
    } else {
      dt = DateTime.tryParse(date.toString());
    }
    if (dt == null) return '-';
    return dateOnly.format(dt);
  }
}
