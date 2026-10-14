import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/permission_model.dart';

class RolePermissionsService {
  final ApiClient _apiClient;

  RolePermissionsService(this._apiClient);

  Future<List<PermissionDefinitionModel>> getCatalog() async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.userRoles}/permissions/catalog');
      final payload = response.data;
      List<dynamic> list = [];

      if (payload is Map && payload.containsKey('data')) {
        final inner = payload['data'];
        if (inner is List) list = inner;
      } else if (payload is List) {
        list = payload;
      }

      return list
          .map((e) => PermissionDefinitionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, List<String>>> getAllRolePermissions() async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.userRoles}/permissions/all');
      final payload = response.data;
      Map<String, dynamic> data = {};

      if (payload is Map && payload.containsKey('data')) {
        final inner = payload['data'];
        if (inner is Map) data = inner.cast<String, dynamic>();
      } else if (payload is Map) {
        data = payload.cast<String, dynamic>();
      }

      final Map<String, List<String>> result = {};
      data.forEach((role, perms) {
        if (perms is List) {
          result[role] = perms.map((e) => e.toString()).toList();
        } else {
          result[role] = [];
        }
      });

      return result;
    } catch (_) {
      return {};
    }
  }

  Future<List<String>> getRolePermissions(String role) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.userRoles}/permissions/$role');
      final payload = response.data;
      List<dynamic> list = [];

      if (payload is Map && payload.containsKey('data')) {
        final inner = payload['data'];
        if (inner is List) list = inner;
      } else if (payload is List) {
        list = payload;
      }

      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> updateRolePermissions(String role, List<String> permissions) async {
    try {
      await _apiClient.dio.post(
        '${ApiConstants.userRoles}/permissions/$role',
        data: {'permissions': permissions},
      );
      return true;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Error al actualizar permisos');
    }
  }

  Future<List<String>> getMyPermissions() async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.userRoles}/permissions/my-permissions');
      final payload = response.data;
      List<dynamic> list = [];

      if (payload is Map && payload.containsKey('data')) {
        final inner = payload['data'];
        if (inner is List) list = inner;
      } else if (payload is List) {
        list = payload;
      }

      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }
}
