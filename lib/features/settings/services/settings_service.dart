import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/gym_settings_model.dart';
import '../models/whatsapp_status_model.dart';

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
      throw Exception(e.response?.data?['message'] ?? 'Error al obtener la configuración del gimnasio');
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
      throw Exception(e.response?.data?['message'] ?? 'Error al actualizar la configuración');
    }
  }

  Future<WhatsappStatusModel> getWhatsappStatus() async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.whatsappSettings}/status');
      dynamic payload = response.data;
      if (payload is Map && payload.containsKey('data')) {
        payload = payload['data'];
      }
      if (payload is Map<String, dynamic>) {
        return WhatsappStatusModel.fromJson(payload);
      }
      return WhatsappStatusModel(status: 'DISCONNECTED');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Error al obtener estado de WhatsApp');
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

  Future<({bool success, String message})> sendTestWhatsapp(String phoneNumber, String message) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.whatsappSettings}/test-message',
        data: {'phoneNumber': phoneNumber, 'message': message},
      );
      final payload = response.data;
      if (payload is Map && payload['success'] == true) {
        return (success: true, message: payload['message']?.toString() ?? 'Mensaje enviado exitosamente');
      } else {
        return (success: false, message: payload?['error']?.toString() ?? 'Error al enviar mensaje');
      }
    } on DioException catch (e) {
      return (
        success: false,
        message: e.response?.data?['error']?.toString() ??
            e.response?.data?['message']?.toString() ??
            'Error de conexión con el servicio de WhatsApp'
      );
    }
  }
}
