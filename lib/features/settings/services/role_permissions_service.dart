import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_permissions.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';
import '../models/permission_model.dart';

class RolePermissionsService {
  final ApiClient _apiClient;

  RolePermissionsService(this._apiClient);

  dynamic _extractData(dynamic payload) {
    if (payload is Map && payload.containsKey('data')) {
      final inner = payload['data'];
      if (inner is Map && inner.containsKey('data')) {
        return inner['data'];
      }
      return inner;
    }
    return payload;
  }

  Future<List<PermissionDefinitionModel>> getCatalog() async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.userRoles}/permissions/catalog');
      final data = _extractData(response.data);
      List<dynamic> list = [];

      if (data is List) {
        list = data;
      }

      final parsed = list
          .whereType<Map>()
          .map((e) => PermissionDefinitionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (parsed.isNotEmpty) {
        return parsed;
      }
    } catch (_) {}

    return AppPermissions.catalogDefinitions
        .map((m) => PermissionDefinitionModel(
              id: m['id']!,
              name: m['name']!,
              description: m['description']!,
              module: m['module']!,
            ))
        .toList();
  }

  Future<Map<String, List<String>>> getAllRolePermissions() async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.userRoles}/permissions/all');
      final raw = _extractData(response.data);
      Map<String, dynamic> data = {};

      if (raw is Map) {
        data = Map<String, dynamic>.from(raw);
      }

      final Map<String, List<String>> result = {};
      data.forEach((role, perms) {
        if (perms is List) {
          result[role] = perms.map((e) => e.toString()).toList();
        } else {
          result[role] = [];
        }
      });

      if (result.isNotEmpty) {
        return result;
      }
    } catch (_) {}

    return Map<String, List<String>>.from(AppPermissions.defaultRolePermissionsAsStrings);
  }

  Future<List<String>> getRolePermissions(String role) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.userRoles}/permissions/$role');
      final data = _extractData(response.data);
      List<dynamic> list = [];

      if (data is List) {
        list = data;
      }

      return list.map((e) => e.toString()).toList();
    } catch (e) {
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
      final data = _extractData(response.data);
      List<dynamic> list = [];

      if (data is List) {
        list = data;
      }

      return list.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.userRoles}/by-role/$role');
      final data = _extractData(response.data);
      List<dynamic> list = [];

      if (data is List) {
        list = data;
      }

      return list
          .whereType<Map>()
          .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<UserModel>> searchUsers({String? search, int limit = 50}) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      final response = await _apiClient.dio.get(
        '${ApiConstants.userRoles}/clients',
        queryParameters: queryParams,
      );
      final data = _extractData(response.data);
      List<dynamic> list = [];

      if (data is List) {
        list = data;
      }

      return list
          .whereType<Map>()
          .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> assignRole(String userId, String role) async {
    try {
      await _apiClient.dio.post(
        '${ApiConstants.userRoles}/assign/$userId',
        data: {'role': role},
      );
      return true;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Error asignando rol al usuario');
    }
  }
}
