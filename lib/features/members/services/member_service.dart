import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/member_model.dart';

class MemberService {
  final ApiClient _apiClient;

  MemberService(this._apiClient);

  Future<({List<MemberModel> members, int total, int totalPages})> getMembers({
    int page = 1,
    int limit = 25,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.members,
        queryParameters: {'page': page, 'limit': limit},
      );

      final payload = response.data;
      List<dynamic> list = [];
      int total = 0;
      int totalPages = 1;

      // Unpack { statusCode, success, data: { data: [...], pagination: { total, ... } } }
      if (payload is Map && payload.containsKey('data')) {
        final inner = payload['data'];
        if (inner is Map) {
          if (inner['data'] is List) list = inner['data'] as List;
          final pag = inner['pagination'] as Map?;
          if (pag != null) {
            total = int.tryParse(pag['total']?.toString() ?? '') ?? list.length;
            totalPages = int.tryParse(pag['pages']?.toString() ?? '') ?? 1;
          }
        } else if (inner is List) {
          list = inner;
          total = list.length;
        }
      }

      final members = list.map((e) => MemberModel.fromJson(e as Map<String, dynamic>)).toList();
      return (members: members, total: total, totalPages: totalPages);
    } catch (e) {
      return (members: <MemberModel>[], total: 0, totalPages: 1);
    }
  }

  Future<List<MemberModel>> searchMembers(String query, {int limit = 100}) async {
    try {
      if (query.trim().isEmpty) {
        final res = await getMembers(page: 1, limit: 25);
        return res.members;
      }

      final response = await _apiClient.dio.get(
        '${ApiConstants.members}/search',
        queryParameters: {'q': query.trim(), 'limit': limit},
      );

      final payload = response.data;
      List<dynamic> list = [];

      if (payload is Map && payload.containsKey('data')) {
        final inner = payload['data'];
        if (inner is Map && inner['data'] is List) {
          list = inner['data'] as List;
        } else if (inner is Map && inner['members'] is List) {
          list = inner['members'] as List;
        } else if (inner is List) {
          list = inner;
        }
      } else if (payload is List) {
        list = payload;
      }

      return list.map((e) => MemberModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<MemberModel> getMemberById(String id) async {
    final response = await _apiClient.dio.get('${ApiConstants.members}/$id');
    final payload = response.data;
    Map<String, dynamic> data = {};
    if (payload is Map && payload.containsKey('data')) {
      data = payload['data'] as Map<String, dynamic>;
    } else if (payload is Map) {
      data = payload as Map<String, dynamic>;
    }
    return MemberModel.fromJson(data);
  }

  Future<MemberModel> createMember(Map<String, dynamic> memberData) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.members,
        data: memberData,
      );
      final payload = response.data;
      Map<String, dynamic> data = {};
      if (payload is Map && payload.containsKey('data')) {
        data = payload['data'] as Map<String, dynamic>;
      } else if (payload is Map) {
        data = payload as Map<String, dynamic>;
      }
      return MemberModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Error creando socio');
    }
  }

  Future<MemberModel> updateMember(String id, Map<String, dynamic> memberData) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.members}/$id',
        data: memberData,
      );
      final payload = response.data;
      Map<String, dynamic> data = {};
      if (payload is Map && payload.containsKey('data')) {
        data = payload['data'] as Map<String, dynamic>;
      } else if (payload is Map) {
        data = payload as Map<String, dynamic>;
      }
      return MemberModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Error actualizando socio');
    }
  }

  Future<void> deleteMember(String id) async {
    await _apiClient.dio.delete('${ApiConstants.members}/$id');
  }

  Future<List<Map<String, dynamic>>> getMembershipsHistory(String memberId) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.memberMemberships}/history/$memberId');
      final payload = response.data;
      if (payload is Map && payload.containsKey('data')) {
        final inner = payload['data'];
        if (inner is List) return inner.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        if (inner is Map && inner['data'] is List) {
          return (inner['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } else if (payload is List) {
        return payload.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getPaymentHistory(String memberId) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.payments}/member/$memberId');
      final payload = response.data;
      if (payload is Map && payload.containsKey('data')) {
        final inner = payload['data'];
        if (inner is Map) return Map<String, dynamic>.from(inner);
      } else if (payload is Map) {
        return Map<String, dynamic>.from(payload);
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getAttendancesHistory(String memberId, {int limit = 50}) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.attendances}/member/$memberId',
        queryParameters: {'limit': limit},
      );
      final payload = response.data;
      if (payload is Map && payload.containsKey('data')) {
        final inner = payload['data'];
        if (inner is Map && inner['data'] is List) {
          return (inner['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        if (inner is List) {
          return inner.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      } else if (payload is List) {
        return payload.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> payPayment(
    String paymentId, {
    String paymentMethod = 'cash',
    String? discountCode,
    double? discountAmount,
  }) async {
    try {
      final data = <String, dynamic>{
        'paymentMethod': paymentMethod,
        if (discountCode != null && discountCode.trim().isNotEmpty) 'discountCode': discountCode.trim(),
        if (discountAmount != null && discountAmount > 0) 'discountAmount': discountAmount,
      };
      await _apiClient.dio.post(
        '${ApiConstants.payments}/$paymentId/pay',
        data: data,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> removeMembership(String memberId, {String? action}) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiConstants.memberMemberships}/$memberId',
        queryParameters: action != null ? {'action': action} : null,
      );
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return {'success': true, 'message': 'Membresía cancelada correctamente'};
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Error cancelando membresía');
    }
  }
}
