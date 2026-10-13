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

  Future<bool> assignMembership({
    required String memberId,
    required String membershipId,
    required String startDate,
    String paymentMethod = 'cash',
  }) async {
    try {
      await _apiClient.dio.post(
        ApiConstants.memberMemberships,
        data: {
          'memberId': memberId,
          'membershipId': membershipId,
          'startDate': startDate,
          'paymentMethod': paymentMethod,
        },
      );
      return true;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Error asignando membresía');
    }
  }
}
