import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/product_model.dart';

class PosService {
  final ApiClient _apiClient;

  PosService(this._apiClient);

  Future<List<ProductModel>> getProducts({int limit = 150}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.products,
        queryParameters: {'page': 1, 'limit': limit},
      );

      final payload = response.data;
      List<dynamic> list = [];

      if (payload is Map && payload.containsKey('data')) {
        final inner = payload['data'];
        if (inner is Map) {
          if (inner['products'] is List) {
            list = inner['products'] as List;
          } else if (inner['data'] is List) {
            list = inner['data'] as List;
          }
        } else if (inner is List) {
          list = inner;
        }
      } else if (payload is Map && payload['products'] is List) {
        list = payload['products'] as List;
      } else if (payload is List) {
        list = payload;
      }

      return list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.products}/search',
        queryParameters: {'query': query.trim()},
      );

      final payload = response.data;
      List<dynamic> list = [];

      if (payload is Map && payload.containsKey('data')) {
        final inner = payload['data'];
        if (inner is List) list = inner;
      } else if (payload is List) {
        list = payload;
      }

      return list.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createSale({
    String? memberId,
    String? customerName,
    required List<Map<String, dynamic>> items,
    double discount = 0.0,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.sales,
        data: {
          if (memberId != null && memberId.isNotEmpty) 'memberId': memberId,
          if (customerName != null && customerName.isNotEmpty) 'customerName': customerName,
          'items': items,
          'discount': discount,
          'paymentMethod': paymentMethod,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );

      final payload = response.data;
      if (payload is Map && payload.containsKey('data')) {
        final inner = payload['data'];
        if (inner is Map) return Map<String, dynamic>.from(inner);
      } else if (payload is Map) {
        return Map<String, dynamic>.from(payload);
      }
      return {};
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Error al procesar venta');
    }
  }
}
