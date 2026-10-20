import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/attendance_model.dart';

class AccessScanResult {
  final bool allowed;
  final String status;
  final String message;
  final String? reason;
  final String? memberCode;
  final String? memberName;
  final String? memberId;
  final DateTime timestamp;
  final AttendanceModel? attendance;

  AccessScanResult({
    required this.allowed,
    required this.status,
    required this.message,
    this.reason,
    this.memberCode,
    this.memberName,
    this.memberId,
    required this.timestamp,
    this.attendance,
  });
}

class AccessService {
  final ApiClient _apiClient;

  AccessService(this._apiClient);

  Future<AccessScanResult> registerByCode(String code) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.attendances}/register-by-code',
        data: {'memberCode': code.trim()},
      );

      final payload = response.data;
      Map<String, dynamic> data = {};
      if (payload is Map && payload.containsKey('data')) {
        final inner = payload['data'];
        if (inner is Map) data = inner.cast<String, dynamic>();
      } else if (payload is Map) {
        data = payload.cast<String, dynamic>();
      }

      final isSuccess = data['success'] != false && data['status'] != 'REJECTED';
      final msg = data['message']?.toString() ?? (isSuccess ? 'Acceso Autorizado' : 'Acceso Denegado');
      final reason = data['reason']?.toString();
      AttendanceModel? att;
      if (data['attendance'] is Map) {
        att = AttendanceModel.fromJson(data['attendance'] as Map<String, dynamic>);
      } else {
        att = AttendanceModel.fromJson(data);
      }

      final attName = (att.fullName.isNotEmpty && att.fullName != 'Socio Desconocido') ? att.fullName : null;
      final rootName = data['memberName'] != null ? '${data['memberName']} ${data['memberLastName'] ?? ''}'.trim() : null;
      final name = rootName ?? attName;
      final resolvedCode = data['memberCode']?.toString() ?? att.memberCode ?? code;

      return AccessScanResult(
        allowed: isSuccess,
        status: isSuccess ? 'AUTHORIZED' : 'REJECTED',
        message: msg,
        reason: reason,
        memberCode: resolvedCode,
        memberName: name,
        memberId: data['memberId']?.toString() ?? att.memberId,
        timestamp: DateTime.now(),
        attendance: att,
      );
    } on DioException catch (e) {
      final resData = e.response?.data;
      String err = 'Error al registrar acceso';
      if (resData is Map && resData['message'] != null) {
        err = resData['message'].toString();
      }
      return AccessScanResult(
        allowed: false,
        status: 'REJECTED',
        message: err,
        reason: err,
        memberCode: code,
        timestamp: DateTime.now(),
      );
    }
  }

  Future<AccessScanResult> registerById(String memberId, {String? notes}) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.attendances}/register-by-id',
        data: {'memberId': memberId, 'notes': notes},
      );

      final payload = response.data;
      Map<String, dynamic> data = {};
      if (payload is Map && payload.containsKey('data')) {
        final inner = payload['data'];
        if (inner is Map) data = inner.cast<String, dynamic>();
      } else if (payload is Map) {
        data = payload.cast<String, dynamic>();
      }

      final isSuccess = data['success'] != false && data['status'] != 'REJECTED';
      final msg = data['message']?.toString() ?? (isSuccess ? 'Acceso Autorizado' : 'Acceso Denegado');
      AttendanceModel? att;
      if (data['attendance'] is Map) {
        att = AttendanceModel.fromJson(data['attendance'] as Map<String, dynamic>);
      } else {
        att = AttendanceModel.fromJson(data);
      }

      final attName = (att.fullName.isNotEmpty && att.fullName != 'Socio Desconocido') ? att.fullName : null;
      final rootName = data['memberName'] != null ? '${data['memberName']} ${data['memberLastName'] ?? ''}'.trim() : null;
      final name = rootName ?? attName;
      final resolvedCode = data['memberCode']?.toString() ?? att.memberCode;

      return AccessScanResult(
        allowed: isSuccess,
        status: isSuccess ? 'AUTHORIZED' : 'REJECTED',
        message: msg,
        reason: data['reason']?.toString(),
        memberCode: resolvedCode,
        memberName: name,
        memberId: memberId,
        timestamp: DateTime.now(),
        attendance: att,
      );
    } on DioException catch (e) {
      final resData = e.response?.data;
      String err = 'Error al registrar acceso';
      if (resData is Map && resData['message'] != null) {
        err = resData['message'].toString();
      }
      return AccessScanResult(
        allowed: false,
        status: 'REJECTED',
        message: err,
        reason: err,
        memberId: memberId,
        timestamp: DateTime.now(),
      );
    }
  }

  Future<List<AttendanceModel>> getRecentAttendances({int limit = 60}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.attendances,
        queryParameters: {'page': 1, 'limit': limit},
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

      return list.map((e) => AttendanceModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
