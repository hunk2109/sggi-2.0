import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_permissions.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/storage_service.dart';

// Providers
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('StorageService must be overridden in ProviderScope');
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ApiClient(storageService: storage);
});

class AuthState {
  final bool isLoading;
  final UserModel? user;
  final String? error;
  final bool isAuthenticated;
  final Set<String> permissions;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.isAuthenticated = false,
    this.permissions = const {},
  });

  /// Retorna si el usuario tiene un permiso específico.
  /// Si el rol es admin, siempre tiene acceso total.
  bool hasPermission(String permId) {
    if (user?.role == UserRole.admin) return true;
    return permissions.contains(permId);
  }

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? error,
    bool? isAuthenticated,
    Set<String>? permissions,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      permissions: permissions ?? this.permissions,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final storage = ref.read(storageServiceProvider);
    final token = storage.getToken();
    final user = storage.getUser();
    final storedPerms = storage.getPermissions();

    if (token != null && user != null) {
      Set<String> perms = Set<String>.from(storedPerms);
      if (perms.isEmpty) {
        perms = Set<String>.from(AppPermissions.defaultRolePermissions[user.role] ?? []);
      }
      // Sincronizar permisos frescos del backend en segundo plano
      Future.microtask(() => fetchPermissions());
      return AuthState(
        user: user,
        isAuthenticated: true,
        permissions: perms,
      );
    }
    return const AuthState();
  }

  /// Sincroniza los permisos dinámicos asignados desde el backend
  Future<void> fetchPermissions() async {
    final user = state.user;
    if (user == null) return;

    final storage = ref.read(storageServiceProvider);
    final apiClient = ref.read(apiClientProvider);

    try {
      final response = await apiClient.dio.get('${ApiConstants.userRoles}/permissions/my-permissions');
      final payload = response.data;
      dynamic data = payload;
      if (payload is Map && payload.containsKey('data')) {
        data = payload['data'];
      }

      List<String> permsList = [];
      if (data is List) {
        permsList = data.map((e) => e.toString()).toList();
      }

      await storage.savePermissions(permsList);
      state = state.copyWith(permissions: Set<String>.from(permsList));
    } catch (_) {
      // Solo recurrir a permisos por defecto si no hay ningún permiso previo cargado
      if (state.permissions.isEmpty) {
        final fallback = AppPermissions.defaultRolePermissions[user.role] ?? [];
        state = state.copyWith(permissions: Set<String>.from(fallback));
      }
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiClient = ref.read(apiClientProvider);
      final storage = ref.read(storageServiceProvider);

      final response = await apiClient.dio.post(
        ApiConstants.login,
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      final payload = response.data;
      Map<String, dynamic> data = {};

      if (payload is Map<String, dynamic>) {
        if (payload.containsKey('data') && payload['data'] is Map<String, dynamic>) {
          data = payload['data'] as Map<String, dynamic>;
        } else {
          data = payload;
        }
      }

      final token = data['token']?.toString();
      final userData = data['user'] as Map<String, dynamic>?;

      if (token == null || userData == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Respuesta inválida del servidor.',
        );
        return false;
      }

      final user = UserModel.fromJson(userData);

      await storage.saveToken(token);
      await storage.saveUser(user);

      // Cargar permisos inmediatamente desde backend
      Set<String> initialPerms = Set<String>.from(AppPermissions.defaultRolePermissions[user.role] ?? []);
      try {
        final permRes = await apiClient.dio.get('${ApiConstants.userRoles}/permissions/my-permissions');
        final pPayload = permRes.data;
        dynamic pData;
        if (pPayload is Map && pPayload.containsKey('data')) {
          pData = pPayload['data'];
        } else {
          pData = pPayload;
        }
        if (pData is List) {
          initialPerms = pData.map((e) => e.toString()).toSet();
          await storage.savePermissions(initialPerms.toList());
        }
      } catch (_) {
        await storage.savePermissions(initialPerms.toList());
      }

      state = state.copyWith(
        isLoading: false,
        user: user,
        isAuthenticated: true,
        permissions: initialPerms,
      );
      return true;
    } on DioException catch (e) {
      String message = 'Error al iniciar sesión.';
      if (e.response != null && e.response?.data != null) {
        final serverMessage = e.response?.data['message'];
        if (serverMessage is String) {
          message = serverMessage;
        }
      }
      state = state.copyWith(isLoading: false, error: message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    final apiClient = ref.read(apiClientProvider);
    final storage = ref.read(storageServiceProvider);

    try {
      await apiClient.dio.post(ApiConstants.logout);
    } catch (_) {}
    await storage.clearSession();
    state = const AuthState();
  }

  Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
  }) async {
    final apiClient = ref.read(apiClientProvider);
    final storage = ref.read(storageServiceProvider);

    try {
      final data = <String, dynamic>{};
      if (firstName != null && firstName.trim().isNotEmpty) {
        data['firstName'] = firstName.trim();
      }
      if (lastName != null && lastName.trim().isNotEmpty) {
        data['lastName'] = lastName.trim();
      }
      if (phone != null) {
        data['phone'] = phone.trim();
      }
      if (email != null && email.trim().isNotEmpty) {
        data['email'] = email.trim();
      }

      final response = await apiClient.dio.put(
        ApiConstants.profile,
        data: data,
      );

      final payload = response.data;
      Map<String, dynamic> resData = {};
      if (payload is Map<String, dynamic>) {
        if (payload.containsKey('data') && payload['data'] is Map<String, dynamic>) {
          resData = payload['data'] as Map<String, dynamic>;
        } else {
          resData = payload;
        }
      }

      if (resData.containsKey('token') && resData['token'] != null) {
        await storage.saveToken(resData['token'].toString());
      }

      if (resData.containsKey('user') && resData['user'] is Map<String, dynamic>) {
        final updatedUser = UserModel.fromJson(resData['user'] as Map<String, dynamic>);
        await storage.saveUser(updatedUser);
        state = state.copyWith(user: updatedUser);
      } else {
        final currentUser = state.user;
        if (currentUser != null) {
          final updatedUser = UserModel(
            id: currentUser.id,
            email: data['email'] ?? currentUser.email,
            firstName: data['firstName'] ?? currentUser.firstName,
            lastName: data['lastName'] ?? currentUser.lastName,
            phone: data.containsKey('phone') ? data['phone'] : currentUser.phone,
            role: currentUser.role,
            isActive: currentUser.isActive,
          );
          await storage.saveUser(updatedUser);
          state = state.copyWith(user: updatedUser);
        }
      }

      return {'success': true, 'message': resData['message'] ?? 'Perfil actualizado correctamente'};
    } on DioException catch (e) {
      String msg = 'Error al actualizar el perfil';
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        msg = e.response?.data['message'].toString() ?? msg;
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final apiClient = ref.read(apiClientProvider);

    try {
      final response = await apiClient.dio.post(
        '/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );

      final payload = response.data;
      String message = 'Contraseña actualizada con éxito';
      if (payload is Map && payload['message'] != null) {
        message = payload['message'].toString();
      }

      return {'success': true, 'message': message};
    } on DioException catch (e) {
      String msg = 'Error al cambiar la contraseña';
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        msg = e.response?.data['message'].toString() ?? msg;
      }
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>?> fetchProfile() async {
    final apiClient = ref.read(apiClientProvider);
    final storage = ref.read(storageServiceProvider);

    try {
      final response = await apiClient.dio.get(ApiConstants.profile);
      final payload = response.data;
      Map<String, dynamic> resData = {};
      if (payload is Map<String, dynamic>) {
        if (payload.containsKey('data') && payload['data'] is Map<String, dynamic>) {
          resData = payload['data'] as Map<String, dynamic>;
        } else {
          resData = payload;
        }
      }

      final updatedUser = UserModel.fromJson(resData);
      await storage.saveUser(updatedUser);
      state = state.copyWith(user: updatedUser);
      return resData;
    } catch (_) {
      return null;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
