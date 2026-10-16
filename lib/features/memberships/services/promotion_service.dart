import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/promotion_model.dart';

final promotionServiceProvider = Provider<PromotionService>((ref) {
  return PromotionService(ref.watch(apiClientProvider));
});

final activePromotionsProvider = FutureProvider<List<PromotionModel>>((ref) async {
  final service = ref.watch(promotionServiceProvider);
  return service.getActivePromotions();
});

class PromotionsState {
  final bool isLoading;
  final List<PromotionModel> promotions;
  final String? error;

  const PromotionsState({
    this.isLoading = false,
    this.promotions = const [],
    this.error,
  });

  PromotionsState copyWith({
    bool? isLoading,
    List<PromotionModel>? promotions,
    String? error,
  }) {
    return PromotionsState(
      isLoading: isLoading ?? this.isLoading,
      promotions: promotions ?? this.promotions,
      error: error,
    );
  }
}

class PromotionsNotifier extends Notifier<PromotionsState> {
  @override
  PromotionsState build() {
    Future.microtask(() => loadPromotions());
    return const PromotionsState(isLoading: true);
  }

  Future<void> loadPromotions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = ref.read(promotionServiceProvider);
      final list = await service.getAllPromotions();
      state = state.copyWith(isLoading: false, promotions: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createPromotion({
    required String code,
    required num discountPercentage,
    String? description,
    int? maxUses,
    DateTime? expiresAt,
  }) async {
    final service = ref.read(promotionServiceProvider);
    try {
      await service.createPromotion(
        code: code,
        discountPercentage: discountPercentage,
        description: description,
        maxUses: maxUses,
        expiresAt: expiresAt,
      );
      await loadPromotions();
      ref.invalidate(activePromotionsProvider);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updatePromotion(
    String id, {
    String? code,
    num? discountPercentage,
    String? description,
    int? maxUses,
    bool clearMaxUses = false,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
    bool? active,
  }) async {
    final service = ref.read(promotionServiceProvider);
    try {
      await service.updatePromotion(
        id,
        code: code,
        discountPercentage: discountPercentage,
        description: description,
        maxUses: maxUses,
        clearMaxUses: clearMaxUses,
        expiresAt: expiresAt,
        clearExpiresAt: clearExpiresAt,
        active: active,
      );
      await loadPromotions();
      ref.invalidate(activePromotionsProvider);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> toggleActive(String id) async {
    final service = ref.read(promotionServiceProvider);
    final success = await service.togglePromotionActive(id);
    if (success) {
      await loadPromotions();
      ref.invalidate(activePromotionsProvider);
    }
    return success;
  }

  Future<bool> deletePromotion(String id) async {
    final service = ref.read(promotionServiceProvider);
    final success = await service.deletePromotion(id);
    if (success) {
      await loadPromotions();
      ref.invalidate(activePromotionsProvider);
    }
    return success;
  }
}

final promotionsProvider = NotifierProvider<PromotionsNotifier, PromotionsState>(() {
  return PromotionsNotifier();
});

class PromotionService {
  final ApiClient _apiClient;

  PromotionService(this._apiClient);

  Future<List<PromotionModel>> getActivePromotions() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.activePromotions);
      final payload = response.data;
      List<dynamic> list = [];

      if (payload is List) {
        list = payload;
      } else if (payload is Map) {
        final inner = payload['data'] ?? payload['promotions'];
        if (inner is List) {
          list = inner;
        }
      }

      return list
          .map((e) => PromotionModel.fromJson(e as Map<String, dynamic>))
          .where((p) => p.isValid)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<PromotionModel>> getAllPromotions() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.promotions);
      final payload = response.data;
      List<dynamic> list = [];

      if (payload is List) {
        list = payload;
      } else if (payload is Map) {
        final inner = payload['data'] ?? payload['promotions'];
        if (inner is List) {
          list = inner;
        }
      }

      return list
          .map((e) => PromotionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<PromotionModel> createPromotion({
    required String code,
    required num discountPercentage,
    String? description,
    int? maxUses,
    DateTime? expiresAt,
  }) async {
    try {
      final data = <String, dynamic>{
        'code': code.trim().toUpperCase(),
        'discountPercentage': discountPercentage,
      };
      if (description != null && description.trim().isNotEmpty) {
        data['description'] = description.trim();
      }
      if (maxUses != null && maxUses > 0) {
        data['maxUses'] = maxUses;
      }
      if (expiresAt != null) {
        data['expiresAt'] = expiresAt.toIso8601String();
      }

      final response = await _apiClient.dio.post(
        ApiConstants.promotions,
        data: data,
      );

      final payload = response.data;
      Map<String, dynamic> dataMap = {};
      if (payload is Map<String, dynamic>) {
        dataMap = payload['data'] is Map<String, dynamic> ? payload['data'] : payload;
      }
      return PromotionModel.fromJson(dataMap);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Error al crear cupón');
    }
  }

  Future<PromotionModel> updatePromotion(
    String id, {
    String? code,
    num? discountPercentage,
    String? description,
    int? maxUses,
    bool clearMaxUses = false,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
    bool? active,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (code != null) data['code'] = code.trim().toUpperCase();
      if (discountPercentage != null) data['discountPercentage'] = discountPercentage;
      if (description != null) data['description'] = description.trim();
      if (clearMaxUses) {
        data['maxUses'] = null;
      } else if (maxUses != null) {
        data['maxUses'] = maxUses;
      }
      if (clearExpiresAt) {
        data['expiresAt'] = null;
      } else if (expiresAt != null) {
        data['expiresAt'] = expiresAt.toIso8601String();
      }
      if (active != null) data['active'] = active;

      final response = await _apiClient.dio.patch(
        '${ApiConstants.promotions}/$id',
        data: data,
      );

      final payload = response.data;
      Map<String, dynamic> dataMap = {};
      if (payload is Map<String, dynamic>) {
        dataMap = payload['data'] is Map<String, dynamic> ? payload['data'] : payload;
      }
      return PromotionModel.fromJson(dataMap);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Error al actualizar cupón');
    }
  }

  Future<bool> deletePromotion(String id) async {
    try {
      await _apiClient.dio.delete('${ApiConstants.promotions}/$id');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> togglePromotionActive(String id) async {
    try {
      await _apiClient.dio.patch('${ApiConstants.promotions}/$id/toggle-active');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<PromotionValidationResult> validatePromotion(String code) async {
    try {
      final cleanCode = code.trim().toUpperCase();
      final response = await _apiClient.dio.post(
        ApiConstants.validatePromotion,
        data: {'code': cleanCode},
      );

      final payload = response.data;
      Map<String, dynamic> dataMap = {};
      if (payload is Map<String, dynamic>) {
        if (payload['data'] is Map<String, dynamic>) {
          dataMap = payload['data'];
        } else {
          dataMap = payload;
        }
      }

      return PromotionValidationResult.fromJson(dataMap, code: cleanCode);
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? 'Cupón no válido o no encontrado';
      return PromotionValidationResult(
        valid: false,
        discount: 0,
        message: msg,
        code: code,
      );
    } catch (e) {
      return PromotionValidationResult(
        valid: false,
        discount: 0,
        message: 'Error al validar cupón: $e',
        code: code,
      );
    }
  }
}
