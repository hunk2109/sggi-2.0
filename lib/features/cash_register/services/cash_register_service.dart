import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/cash_register_model.dart';
import '../models/sale_history_model.dart';

class CashRegisterService {
  final ApiClient _apiClient;

  CashRegisterService(this._apiClient);

  Future<CashRegisterModel?> getTodayRegister() async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.cashRegister}/today');
      final payload = response.data;
      Map<String, dynamic>? data;

      if (payload is Map && payload.containsKey('data')) {
        final inner = payload['data'];
        if (inner is Map) data = inner.cast<String, dynamic>();
      } else if (payload is Map) {
        data = payload.cast<String, dynamic>();
      }

      if (data != null && (data['isOpen'] == true || data['isOpen'] == 1)) {
        return CashRegisterModel.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<CashRegisterModel> openRegister(double openingAmount) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.cashRegister}/open',
        data: {'openingAmount': openingAmount},
      );

      final payload = response.data;
      Map<String, dynamic> data = {};

      if (payload is Map && payload.containsKey('data')) {
        final inner = payload['data'];
        if (inner is Map) data = inner.cast<String, dynamic>();
      } else if (payload is Map) {
        data = payload.cast<String, dynamic>();
      }

      return CashRegisterModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Error al abrir caja');
    }
  }

  Future<CashRegisterModel> closeRegister(
    double closingAmount, {
    Map<String, int>? billBreakdown,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.cashRegister}/close',
        data: {
          'closingAmount': closingAmount,
          if (billBreakdown != null && billBreakdown.isNotEmpty)
            'billBreakdown': billBreakdown,
        },
      );

      final payload = response.data;
      Map<String, dynamic> data = {};

      if (payload is Map && payload.containsKey('data')) {
        final inner = payload['data'];
        if (inner is Map) data = inner.cast<String, dynamic>();
      } else if (payload is Map) {
        data = payload.cast<String, dynamic>();
      }

      return CashRegisterModel.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Error al cerrar caja');
    }
  }

  Future<List<CashRegisterModel>> getHistory({int days = 30, int page = 1, int limit = 20}) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.cashRegister}/history',
        queryParameters: {'days': days, 'page': page, 'limit': limit},
      );

      final payload = response.data;
      List<dynamic> list = [];

      if (payload is Map && payload.containsKey('data')) {
        final inner = payload['data'];
        if (inner is Map && inner['data'] is List) {
          list = inner['data'] as List;
        } else if (inner is List) {
          list = inner;
        }
      } else if (payload is List) {
        list = payload;
      }

      return list.map((e) => CashRegisterModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<CashTransactionModel>> getCashTransactions(String cashRegisterId) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.accounting}/cash-transactions/$cashRegisterId');
      final payload = response.data;
      List<dynamic> list = [];

      if (payload is Map && payload.containsKey('data')) {
        final inner = payload['data'];
        if (inner is List) list = inner;
      } else if (payload is List) {
        list = payload;
      }

      return list.map((e) => CashTransactionModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> recordCashWithdrawal({
    required String cashRegisterId,
    required String concept,
    required double amount,
  }) async {
    try {
      await _apiClient.dio.post(
        '${ApiConstants.accounting}/payables',
        data: {
          'concept': concept,
          'amount': amount,
          'isCashWithdrawal': true,
          'cashRegisterId': cashRegisterId,
        },
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Error registrando salida de efectivo');
    }
  }

  Future<List<SaleHistoryModel>> getSales({String? cashRegisterId, int limit = 50}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.sales,
        queryParameters: {
          'limit': limit,
          if (cashRegisterId != null && cashRegisterId.isNotEmpty) 'cashRegisterId': cashRegisterId,
        },
      );

      final payload = response.data;
      List<dynamic> list = [];

      if (payload is Map && payload.containsKey('data')) {
        final inner = payload['data'];
        if (inner is Map && inner['sales'] is List) {
          list = inner['sales'] as List;
        } else if (inner is List) {
          list = inner;
        }
      } else if (payload is Map && payload['sales'] is List) {
        list = payload['sales'] as List;
      } else if (payload is List) {
        list = payload;
      }

      return list.map((e) => SaleHistoryModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> cancelSale(String saleId, {String? reason}) async {
    try {
      await _apiClient.dio.delete(
        '${ApiConstants.sales}/$saleId',
        data: reason != null && reason.trim().isNotEmpty ? {'reason': reason.trim()} : null,
        queryParameters: reason != null && reason.trim().isNotEmpty ? {'reason': reason.trim()} : null,
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Error al anular la venta');
    }
  }
}
