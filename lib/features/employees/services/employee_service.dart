import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/employee_model.dart';
import '../models/payroll_model.dart';

class EmployeeService {
  final ApiClient _apiClient;

  EmployeeService(this._apiClient);

  Future<List<EmployeeModel>> getEmployees() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.employees);
      final payload = response.data;
      List<dynamic> list = [];

      if (payload is Map && payload.containsKey('data')) {
        final inner = payload['data'];
        if (inner is List) list = inner;
      } else if (payload is List) {
        list = payload;
      }

      return list.map((e) => EmployeeModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<EmployeeModel> createEmployee(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.employees,
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

      return EmployeeModel.fromJson(resData);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Error registrando empleado');
    }
  }

  Future<EmployeeModel> updateEmployee(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.employees}/$id',
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

      return EmployeeModel.fromJson(resData);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Error actualizando empleado');
    }
  }

  Future<void> toggleActive(String id) async {
    await _apiClient.dio.put('${ApiConstants.employees}/$id/toggle-active');
  }

  Future<void> deleteEmployee(String id) async {
    await _apiClient.dio.delete('${ApiConstants.employees}/$id');
  }

  // Payroll Methods
  Future<List<PayrollModel>> getPayrolls({int? month, int? year}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (month != null) queryParams['month'] = month;
      if (year != null) queryParams['year'] = year;

      final response = await _apiClient.dio.get(
        ApiConstants.payroll,
        queryParameters: queryParams,
      );

      final payload = response.data;
      List<dynamic> list = [];

      if (payload is Map && payload.containsKey('data')) {
        final inner = payload['data'];
        if (inner is List) list = inner;
      } else if (payload is List) {
        list = payload;
      }

      return list.map((e) => PayrollModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<PayrollModel>> generatePayroll({required int month, required int year, bool applyTSS = true}) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.payroll}/generate',
        data: {'month': month, 'year': year, 'applyTSS': applyTSS},
      );

      final payload = response.data;
      List<dynamic> list = [];

      if (payload is Map && payload.containsKey('data')) {
        final inner = payload['data'];
        if (inner is List) list = inner;
      } else if (payload is List) {
        list = payload;
      }

      return list.map((e) => PayrollModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Error generando nómina');
    }
  }

  Future<void> approvePayroll(String id) async {
    await _apiClient.dio.put('${ApiConstants.payroll}/$id/approve');
  }

  Future<void> markPayrollPaid(String id) async {
    await _apiClient.dio.put('${ApiConstants.payroll}/$id/mark-paid', data: {'paidBy': 'admin'});
  }
}
