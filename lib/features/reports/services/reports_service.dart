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
}
