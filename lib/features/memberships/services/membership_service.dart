import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/membership_model.dart';

class MembershipService {
  final ApiClient _apiClient;

  MembershipService(this._apiClient);

  List<dynamic> _extractList(dynamic payload) {
    dynamic current = payload;
    while (current is Map && current.containsKey('data')) {
      current = current['data'];
    }
    if (current is List) return current;
    return [];
  }

  Future<List<MembershipModel>> getActiveMemberships() async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.memberships}/active');
      final list = _extractList(response.data);
      return list.map((e) => MembershipModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      try {
        final response = await _apiClient.dio.get(ApiConstants.memberships, queryParameters: {'limit': 50});
        final list = _extractList(response.data);
        return list.map((e) => MembershipModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      } catch (e) {
        return [];
      }
    }
  }

  Future<List<MembershipModel>> getAllMemberships({int page = 1, int limit = 50}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.memberships,
        queryParameters: {'page': page, 'limit': limit},
      );
      final list = _extractList(response.data);
      return list.map((e) => MembershipModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      return [];
    }
  }

  Future<MembershipModel> createMembership(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.memberships,
        data: data,
      );
      final payload = response.data;
      dynamic current = payload;
      while (current is Map && current.containsKey('data') && current['data'] is Map) {
        current = current['data'];
      }
      Map<String, dynamic> resMap = current is Map ? Map<String, dynamic>.from(current) : {};
      return MembershipModel.fromJson(resMap);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Error al crear membresía';
      throw Exception(msg is List ? msg.join(', ') : msg);
    }
  }

  Future<MembershipModel> updateMembership(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.memberships}/$id',
        data: data,
      );
      final payload = response.data;
      dynamic current = payload;
      while (current is Map && current.containsKey('data') && current['data'] is Map) {
        current = current['data'];
      }
      Map<String, dynamic> resMap = current is Map ? Map<String, dynamic>.from(current) : {};
      return MembershipModel.fromJson(resMap);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Error al actualizar membresía';
      throw Exception(msg is List ? msg.join(', ') : msg);
    }
  }

  Future<bool> deleteMembership(String id) async {
    try {
      await _apiClient.dio.delete('${ApiConstants.memberships}/$id');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleActive(String id, bool currentStatus) async {
    try {
      await updateMembership(id, {'isActive': !currentStatus});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<({bool success, String? warning})> assignMembership({
    required String memberId,
    required String membershipId,
    required String startDate,
    String? endDate,
    String paymentMethod = 'cash',
    String? promotionCode,
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
      if (promotionCode != null && promotionCode.trim().isNotEmpty) {
        data['promotionCode'] = promotionCode.trim().toUpperCase();
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
