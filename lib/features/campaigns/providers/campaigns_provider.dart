import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../members/models/member_model.dart';
import '../models/campaign_model.dart';
import '../services/campaign_service.dart';

final campaignServiceProvider = Provider<CampaignService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CampaignService(apiClient);
});

class CampaignsState {
  final List<CampaignModel> campaigns;
  final List<CampaignTemplateModel> templates;
  final List<MemberModel> recipients;
  final bool isLoading;
  final bool isLoadingRecipients;
  final bool isSending;
  final String selectedAudience;
  final String selectedChannel;
  final Set<String> selectedMemberIds;
  final String memberSearchQuery;
  final CampaignTemplateModel? selectedTemplate;
  final String messageText;
  final String campaignName;
  final String? error;

  const CampaignsState({
    this.campaigns = const [],
    this.templates = const [],
    this.recipients = const [],
    this.isLoading = false,
    this.isLoadingRecipients = false,
    this.isSending = false,
    this.selectedAudience = 'ALL',
    this.selectedChannel = 'WHATSAPP',
    this.selectedMemberIds = const {},
    this.memberSearchQuery = '',
    this.selectedTemplate,
    this.messageText = '',
    this.campaignName = '',
    this.error,
  });

  CampaignsState copyWith({
    List<CampaignModel>? campaigns,
    List<CampaignTemplateModel>? templates,
    List<MemberModel>? recipients,
    bool? isLoading,
    bool? isLoadingRecipients,
    bool? isSending,
    String? selectedAudience,
    String? selectedChannel,
    Set<String>? selectedMemberIds,
    String? memberSearchQuery,
    CampaignTemplateModel? selectedTemplate,
    String? messageText,
    String? campaignName,
    String? error,
  }) {
    return CampaignsState(
      campaigns: campaigns ?? this.campaigns,
      templates: templates ?? this.templates,
      recipients: recipients ?? this.recipients,
      isLoading: isLoading ?? this.isLoading,
      isLoadingRecipients: isLoadingRecipients ?? this.isLoadingRecipients,
      isSending: isSending ?? this.isSending,
      selectedAudience: selectedAudience ?? this.selectedAudience,
      selectedChannel: selectedChannel ?? this.selectedChannel,
      selectedMemberIds: selectedMemberIds ?? this.selectedMemberIds,
      memberSearchQuery: memberSearchQuery ?? this.memberSearchQuery,
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
      messageText: messageText ?? this.messageText,
      campaignName: campaignName ?? this.campaignName,
      error: error,
    );
  }
}

class CampaignsNotifier extends Notifier<CampaignsState> {
  CampaignService get _service => ref.read(campaignServiceProvider);

  @override
  CampaignsState build() {
    Future.microtask(() => init());
    return const CampaignsState(isLoading: true, isLoadingRecipients: true);
  }

  Future<void> init() async {
    await Future.wait([
      loadCampaigns(),
      loadTemplates(),
      loadRecipients(),
    ]);
  }

  Future<void> loadCampaigns() async {
    state = state.copyWith(isLoading: true);
    final campaigns = await _service.getCampaigns();
    state = state.copyWith(campaigns: campaigns, isLoading: false);
  }

  Future<void> loadTemplates() async {
    final templates = await _service.getTemplates();
    state = state.copyWith(templates: templates);
    if (templates.isNotEmpty && state.selectedTemplate == null) {
      applyTemplate(templates.first);
    }
  }

  Future<void> loadRecipients() async {
    state = state.copyWith(isLoadingRecipients: true);
    final list = await _service.getCampaignRecipients();
    state = state.copyWith(recipients: list, isLoadingRecipients: false);
  }

  void setAudience(String audience) {
    state = state.copyWith(selectedAudience: audience);
  }

  void setChannel(String channel) {
    state = state.copyWith(selectedChannel: channel);
  }

  void setMemberSearchQuery(String query) {
    state = state.copyWith(memberSearchQuery: query);
  }

  void toggleMember(String memberId) {
    final newSet = Set<String>.from(state.selectedMemberIds);
    if (newSet.contains(memberId)) {
      newSet.remove(memberId);
    } else {
      newSet.add(memberId);
    }
    state = state.copyWith(
      selectedMemberIds: newSet,
      selectedAudience: 'CUSTOM',
    );
  }

  void selectAllMembers(List<String> allIds) {
    state = state.copyWith(
      selectedMemberIds: Set<String>.from(allIds),
      selectedAudience: 'CUSTOM',
    );
  }

  void clearMemberSelection() {
    state = state.copyWith(
      selectedMemberIds: const {},
      selectedAudience: 'ALL',
    );
  }

  void setMessageText(String text) {
    state = state.copyWith(messageText: text);
  }

  void setCampaignName(String name) {
    state = state.copyWith(campaignName: name);
  }

  void applyTemplate(CampaignTemplateModel template) {
    state = state.copyWith(
      selectedTemplate: template,
      messageText: template.message,
      selectedChannel: template.defaultChannel,
      campaignName: state.campaignName.isEmpty ? template.name : state.campaignName,
    );
  }

  Future<Map<String, dynamic>> sendCampaign({
    required String name,
    required String audience,
    required String channel,
    required String messageTemplate,
    String? couponCode,
    List<String>? customMemberIds,
  }) async {
    state = state.copyWith(isSending: true);
    final result = await _service.sendCampaign(
      name: name,
      audience: audience,
      channel: channel,
      messageTemplate: messageTemplate,
      couponCode: couponCode,
      customMemberIds: audience == 'CUSTOM' ? customMemberIds : null,
    );
    state = state.copyWith(isSending: false);
    if (result['success'] == true) {
      await loadCampaigns();
    }
    return result;
  }

  Future<bool> deleteCampaign(String id) async {
    final ok = await _service.deleteCampaign(id);
    if (ok) {
      await loadCampaigns();
    }
    return ok;
  }
}

final campaignsProvider = NotifierProvider<CampaignsNotifier, CampaignsState>(() {
  return CampaignsNotifier();
});
