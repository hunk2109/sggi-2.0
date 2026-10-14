import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../members/models/member_model.dart';
import '../models/campaign_model.dart';

class CampaignService {
  final ApiClient _apiClient;

  CampaignService(this._apiClient);

  List<dynamic> _extractList(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map && payload['data'] is List) {
      return payload['data'] as List;
    }
    return [];
  }

  Future<List<CampaignModel>> getCampaigns() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.campaigns);
      final list = _extractList(response.data);
      return list.map((json) => CampaignModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<CampaignTemplateModel>> getTemplates() async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.campaigns}/templates');
      final list = _extractList(response.data);
      return list.map((json) => CampaignTemplateModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<MemberModel>> getCampaignRecipients() async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.campaigns}/recipients');
      final list = _extractList(response.data);
      return list.map((json) => MemberModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> sendCampaign({
    required String name,
    required String audience,
    required String channel,
    required String messageTemplate,
    String? couponCode,
    List<String>? customMemberIds,
    DateTime? scheduledAt,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.campaigns,
        data: {
          'name': name,
          'audience': audience,
          'channel': channel,
          'messageTemplate': messageTemplate,
          if (couponCode != null && couponCode.isNotEmpty) 'couponCode': couponCode,
          if (customMemberIds != null && customMemberIds.isNotEmpty) 'customMemberIds': customMemberIds,
          if (scheduledAt != null) 'scheduledAt': scheduledAt.toIso8601String(),
        },
      );
      return {
        'success': true,
        'data': response.data,
        'message': 'Campaña masiva iniciada exitosamente',
      };
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? 'Error al iniciar campaña masiva';
      return {
        'success': false,
        'message': msg,
      };
    }
  }

  Future<bool> deleteCampaign(String id) async {
    try {
      await _apiClient.dio.delete('${ApiConstants.campaigns}/$id');
      return true;
    } on DioException {
      return false;
    }
  }
}
