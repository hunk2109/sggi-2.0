import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/analytics_model.dart';

class ReportsService {
  final ApiClient _apiClient;

  ReportsService(this._apiClient);

  Future<FinancialAnalyticsModel> getFinancialAndBehaviorAnalytics({
    String range = 'monthly',
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'range': range,
      };
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['startDate'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['endDate'] = endDate;
      }

      final response = await _apiClient.dio.get(
        ApiConstants.reportsAnalytics,
        queryParameters: queryParams,
      );

      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        final targetJson = (map['data'] is Map<String, dynamic>)
            ? map['data'] as Map<String, dynamic>
            : map;
        return FinancialAnalyticsModel.fromJson(targetJson);
      }
      throw Exception('Formato de respuesta inválido');
    } catch (e) {
      rethrow;
    }
  }

  Future<({bool success, String message})> sendDailySummaryReport() async {
    try {
      final response = await _apiClient.dio.post(ApiConstants.sendDailySummary);
      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        final msg = map['message']?.toString() ??
            (map['data'] is Map ? map['data']['message']?.toString() : null) ??
            'Reporte generado y enviado con éxito.';
        return (success: true, message: msg);
      }
      return (success: true, message: 'Reporte generado y enviado con éxito.');
    } catch (e) {
      return (
        success: false,
        message: 'Error al enviar reporte: ${e.toString()}',
      );
    }
  }
}
