import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/membership_model.dart';

class MembershipService {
  final ApiClient _apiClient;

  MembershipService(this._apiClient);

  Future<List<MembershipModel>> getActiveMemberships() async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.memberships}/active');
      final payload = response.data;

      List<dynamic> list = [];
      if (payload is Map && payload.containsKey('data')) {
        final inner = payload['data'];
        if (inner is List) list = inner;
      } else if (payload is List) {
        list = payload;
      }

      return list.map((e) => MembershipModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // Fallback a listado general si el endpoint /active no está disponible
      try {
        final response = await _apiClient.dio.get(ApiConstants.memberships, queryParameters: {'limit': 50});
        final payload = response.data;
        List<dynamic> list = [];
        if (payload is Map && payload.containsKey('data')) {
          final inner = payload['data'];
          if (inner is Map && inner.containsKey('data') && inner['data'] is List) {
            list = inner['data'] as List;
          } else if (inner is List) {
            list = inner;
          }
        }
        return list.map((e) => MembershipModel.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        return [];
      }
    }
  }

  Future<({bool success, String? warning})> assignMembership({
    required String memberId,
    required String membershipId,
    required String startDate,
    String? endDate,
    String paymentMethod = 'cash',
  }) async {
    try {
      final data = <String, dynamic>{
        'memberId': memberId,
        'membershipId': membershipId,
        'startDate': startDate,
        'paymentMethod': paymentMethod,
      };
      if (endDate != null && endDate.isNotEmpty) {
        data['endDate'] = endDate;
      }
      final response = await _apiClient.dio.post(
        ApiConstants.memberMemberships,
        data: data,
      );

      String? warning;
      final payload = response.data;
      if (payload is Map) {
        final inner = payload['data'] ?? payload;
        if (inner is Map && inner['warning'] != null) {
          warning = inner['warning']?.toString();
        }
      }

      return (success: true, warning: warning);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Error asignando membresía');
    }
  }
}
