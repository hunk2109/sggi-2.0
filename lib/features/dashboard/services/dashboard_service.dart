import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/dashboard_model.dart';

class DashboardService {
  final ApiClient _apiClient;

  DashboardService(this._apiClient);

  Future<DashboardOverviewModel> getOverview() async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.dashboard}/overview');
      final payload = response.data;
      Map<String, dynamic> data = {};

      if (payload is Map && payload.containsKey('data')) {
        final inner = payload['data'];
        if (inner is Map) {
          data = inner.cast<String, dynamic>();
        }
      } else if (payload is Map) {
        data = payload.cast<String, dynamic>();
      }

      return DashboardOverviewModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Error al obtener datos del dashboard');
    }
  }
}
