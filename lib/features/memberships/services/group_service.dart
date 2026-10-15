import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/group_model.dart';

class GroupService {
  final ApiClient _apiClient;

  GroupService(this._apiClient);

  List<dynamic> _extractList(dynamic payload) {
    dynamic current = payload;
    while (current is Map && current.containsKey('data')) {
      current = current['data'];
    }
    if (current is List) return current;
    return [];
  }

  /// Obtiene los grupos vinculados a un socio (como responsable o como acompañante)
  Future<List<GroupModel>> getMemberGroups(String memberId) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.groups}/member/$memberId/groups');
      final list = _extractList(response.data);
      return list
          .whereType<Map<String, dynamic>>()
          .map((e) => GroupModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtiene los detalles completos de un grupo (con sus acompañantes)
  Future<GroupModel?> getGroupById(String groupId) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.groups}/$groupId');
      dynamic current = response.data;
      while (current is Map && current.containsKey('data') && current['data'] is Map) {
        current = current['data'];
      }
      if (current is Map) {
        return GroupModel.fromJson(Map<String, dynamic>.from(current));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Agrega un acompañante familiar al grupo
  Future<({bool success, String? message})> addCompanion({
    required String groupId,
    required String memberId,
    required String relationship,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.groups}/$groupId/companions',
        data: {
          'memberId': memberId,
          'relationship': relationship,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return (success: true, message: null);
      }
      return (success: false, message: 'No se pudo agregar el acompañante');
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['message']?.toString() ?? e.message)
          : e.message;
      return (success: false, message: msg ?? 'Error agregando acompañante');
    } catch (e) {
      return (success: false, message: e.toString());
    }
  }

  /// Remueve un acompañante familiar del grupo
  Future<({bool success, String? message})> removeCompanion({
    required String groupId,
    required String companionId,
  }) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiConstants.groups}/$groupId/companions/$companionId',
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return (success: true, message: null);
      }
      return (success: false, message: 'No se pudo remover el acompañante');
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['message']?.toString() ?? e.message)
          : e.message;
      return (success: false, message: msg ?? 'Error removiendo acompañante');
    } catch (e) {
      return (success: false, message: e.toString());
    }
  }
}
