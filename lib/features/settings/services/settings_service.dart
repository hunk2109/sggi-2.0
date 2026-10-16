import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/gym_settings_model.dart';
import '../models/whatsapp_status_model.dart';
import '../models/email_config_model.dart';

class SettingsService {
  final ApiClient _apiClient;

  SettingsService(this._apiClient);

  Future<GymSettingsModel> getGymSettings() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.gymSettings);
      dynamic payload = response.data;
      if (payload is Map && payload.containsKey('data')) {
        payload = payload['data'];
        if (payload is Map && payload.containsKey('data')) {
          payload = payload['data'];
        }
      }
      if (payload is Map<String, dynamic>) {
        return GymSettingsModel.fromJson(payload);
      }
      return GymSettingsModel();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ??
            'Error al obtener la configuración del gimnasio',
      );
    }
  }

  Future<GymSettingsModel> updateGymSettings(GymSettingsModel settings) async {
    try {
      final response = await _apiClient.dio.put(
        ApiConstants.gymSettings,
        data: settings.toJson(),
      );
      dynamic payload = response.data;
      if (payload is Map && payload.containsKey('data')) {
        payload = payload['data'];
        if (payload is Map && payload.containsKey('data')) {
          payload = payload['data'];
        }
      }
      if (payload is Map<String, dynamic>) {
        return GymSettingsModel.fromJson(payload);
      }
      return settings;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Error al actualizar la configuración',
      );
    }
  }

  Future<WhatsappStatusModel> getWhatsappStatus() async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.whatsappSettings}/status',
      );
      dynamic payload = response.data;
      if (payload is Map && payload.containsKey('data')) {
        payload = payload['data'];
      }
      if (payload is Map<String, dynamic>) {
        return WhatsappStatusModel.fromJson(payload);
      }
      return WhatsappStatusModel(status: 'DISCONNECTED');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Error al obtener estado de WhatsApp',
      );
    }
  }

  Future<bool> restartWhatsapp() async {
    try {
      await _apiClient.dio.post('${ApiConstants.whatsappSettings}/restart');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> logoutWhatsapp() async {
    try {
      await _apiClient.dio.post('${ApiConstants.whatsappSettings}/logout');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<({bool success, String message})> sendTestWhatsapp(
    String phoneNumber,
    String message,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.whatsappSettings}/test-message',
        data: {'phoneNumber': phoneNumber, 'message': message},
      );
      final payload = response.data;
      if (payload is Map && payload['success'] == true) {
        return (
          success: true,
          message:
              payload['message']?.toString() ?? 'Mensaje enviado exitosamente',
        );
      } else {
        return (
          success: false,
          message: payload?['error']?.toString() ?? 'Error al enviar mensaje',
        );
      }
    } on DioException catch (e) {
      return (
        success: false,
        message:
            e.response?.data?['error']?.toString() ??
            e.response?.data?['message']?.toString() ??
            'Error de conexión con el servicio de WhatsApp',
      );
    }
  }

  Future<String?> getAccessDbPath() async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.sync}/access-path',
      );
      final data = response.data;
      if (data is Map) {
        if (data['data'] is Map && data['data']['path'] != null) {
          final p = data['data']['path'].toString();
          if (!p.startsWith('/api/')) return p;
        }
        if (data['path'] != null) {
          final p = data['path'].toString();
          if (!p.startsWith('/api/')) return p;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> setAccessDbPath(String path) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.sync}/access-path',
        data: {'path': path},
      );
      if (response.data is Map) {
        final d = response.data as Map;
        if (d['success'] == true) return true;
        if (d['data'] is Map && d['data']['success'] == true) return true;
      }
      return (response.statusCode ?? 500) < 300;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> testAccessConnection() async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.sync}/access-dashboard',
      );
      if (response.data is Map) {
        final d = response.data as Map;
        if (d['data'] is Map) {
          return Map<String, dynamic>.from(d['data'] as Map);
        }
        return Map<String, dynamic>.from(d);
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> performMigrationToDatabase() async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.sync}/initial',
      );
      if (response.data is Map) {
        final d = response.data as Map;
        if (d['data'] is Map) {
          return Map<String, dynamic>.from(d['data'] as Map);
        }
        return Map<String, dynamic>.from(d);
      }
      return {'success': false, 'message': 'Respuesta no válida'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message ?? 'Error durante la migración',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateMachineIp({
    required String ip,
    int port = 4370,
    int? machineId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'ip': ip,
        'port': port,
      };
      if (machineId != null) payload['machineId'] = machineId;

      final response = await _apiClient.dio.put(
        '${ApiConstants.sync}/machine-ip',
        data: payload,
      );
      if (response.data is Map) {
        final d = response.data as Map;
        if (d['data'] is Map) {
          return Map<String, dynamic>.from(d['data'] as Map);
        }
        return Map<String, dynamic>.from(d);
      }
      return {'success': false, 'message': 'Respuesta no válida'};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['message'] ?? e.message ?? 'Error al actualizar IP del equipo',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> testMachineConnection({
    int? machineId,
    String? ip,
    int? port,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (machineId != null) payload['machineId'] = machineId;
      if (ip != null) payload['ip'] = ip;
      if (port != null) payload['port'] = port;

      final response = await _apiClient.dio.post(
        '${ApiConstants.sync}/access-machine/test',
        data: payload,
      );
      if (response.data is Map) {
        final d = response.data as Map;
        if (d['data'] is Map) {
          return Map<String, dynamic>.from(d['data'] as Map);
        }
        return Map<String, dynamic>.from(d);
      }
      return {'success': false};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> getZktecoSyncEnabled() async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.sync}/zkteco-status');
      if (response.data is Map && response.data['enabled'] != null) {
        return response.data['enabled'] == true;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> setZktecoSyncEnabled(bool enabled) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.sync}/zkteco-status',
        data: {'enabled': enabled},
      );
      if (response.data is Map && response.data['success'] == true) {
        return true;
      }
      return (response.statusCode ?? 500) < 300;
    } catch (_) {
      return false;
    }
  }

  // ================= EMAIL SETTINGS =================

  Future<EmailConfigModel?> getEmailConfig() async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.emailSettings}/config/current');
      dynamic payload = response.data;
      if (payload is Map && payload.containsKey('data')) {
        payload = payload['data'];
      }
      if (payload is Map<String, dynamic> && payload.isNotEmpty) {
        return EmailConfigModel.fromJson(payload);
      }
      // Fallback: array de configs
      final listResp = await _apiClient.dio.get('${ApiConstants.emailSettings}/config');
      dynamic listData = listResp.data;
      if (listData is Map && listData.containsKey('data')) listData = listData['data'];
      if (listData is List && listData.isNotEmpty) {
        final active = listData.firstWhere(
          (e) => (e is Map && (e['isActive'] == true || e['isActive'] == 1)),
          orElse: () => listData.first,
        );
        return EmailConfigModel.fromJson(Map<String, dynamic>.from(active as Map));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<EmailConfigModel> saveEmailConfig(EmailConfigModel config) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.emailSettings}/config/save',
        data: config.toJson(),
      );
      dynamic payload = response.data;
      if (payload is Map && payload.containsKey('data')) {
        payload = payload['data'];
      }
      if (payload is Map<String, dynamic>) {
        return EmailConfigModel.fromJson(payload);
      }
      return config;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Error al guardar la configuración de correo',
      );
    }
  }

  Future<({bool success, String message})> verifyEmailConfig(String testEmail) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.emailSettings}/config/verify-active',
        data: {'recipientEmail': testEmail.trim()},
      );
      final payload = response.data;
      if (payload is Map && payload['success'] == true) {
        return (
          success: true,
          message: payload['message']?.toString() ?? 'Configuración de correo verificada exitosamente',
        );
      }
      return (
        success: false,
        message: payload?['message']?.toString() ?? 'Error al verificar la configuración',
      );
    } on DioException catch (e) {
      return (
        success: false,
        message: e.response?.data?['message']?.toString() ??
            e.message ??
            'Error al verificar la configuración de correo',
      );
    } catch (e) {
      return (success: false, message: e.toString());
    }
  }

  Future<({bool success, String message})> sendTestEmail(
    String recipientEmail, {
    String? subject,
    String? message,
  }) async {
    try {
      await _apiClient.dio.post(
        '${ApiConstants.emailSettings}/send-test',
        data: {
          'recipientEmail': recipientEmail.trim(),
          if (subject != null && subject.isNotEmpty) 'subject': subject,
          if (message != null && message.isNotEmpty) 'message': message,
        },
      );
      return (
        success: true,
        message: 'Correo de prueba enviado exitosamente a $recipientEmail',
      );
    } on DioException catch (e) {
      return (
        success: false,
        message: e.response?.data?['message']?.toString() ??
            e.message ??
            'Error al enviar correo de prueba',
      );
    } catch (e) {
      return (success: false, message: e.toString());
    }
  }
}
