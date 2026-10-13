import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/inventory_product_model.dart';

class InventoryService {
  final ApiClient _apiClient;

  InventoryService(this._apiClient);

  Future<List<InventoryProductModel>> getProducts({int limit = 200}) async {
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

      return list.map((e) => InventoryProductModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<InventoryProductModel> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.products,
        data: data,
      );

      final payload = response.data;
      Map<String, dynamic> resData = {};
      if (payload is Map && payload.containsKey('data')) {
        final inner = payload['data'];
        if (inner is Map) resData = inner.cast<String, dynamic>();
      } else if (payload is Map) {
        resData = payload.cast<String, dynamic>();
      }

      return InventoryProductModel.fromJson(resData);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Error creando producto');
    }
  }

  Future<InventoryProductModel> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.products}/$id',
        data: data,
      );

      final payload = response.data;
      Map<String, dynamic> resData = {};
      if (payload is Map && payload.containsKey('data')) {
        final inner = payload['data'];
        if (inner is Map) resData = inner.cast<String, dynamic>();
      } else if (payload is Map) {
        resData = payload.cast<String, dynamic>();
      }

      return InventoryProductModel.fromJson(resData);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Error actualizando producto');
    }
  }

  Future<void> deleteProduct(String id) async {
    await _apiClient.dio.delete('${ApiConstants.products}/$id');
  }

  Future<void> addStock(String id, int quantity) async {
    await _apiClient.dio.post('${ApiConstants.products}/$id/stock/add', data: {'quantity': quantity});
  }

  Future<void> removeStock(String id, int quantity) async {
    await _apiClient.dio.post('${ApiConstants.products}/$id/stock/remove', data: {'quantity': quantity});
  }
}
