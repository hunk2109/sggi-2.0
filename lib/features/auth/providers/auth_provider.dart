import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
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

  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final storage = ref.read(storageServiceProvider);
    final token = storage.getToken();
    final user = storage.getUser();

    if (token != null && user != null) {
      return AuthState(user: user, isAuthenticated: true);
    }
    return const AuthState();
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

      state = state.copyWith(
        isLoading: false,
        user: user,
        isAuthenticated: true,
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
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
