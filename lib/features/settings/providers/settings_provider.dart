import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/gym_settings_model.dart';
import '../models/whatsapp_status_model.dart';
import '../models/email_config_model.dart';
import '../services/settings_service.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SettingsService(apiClient);
});

// State for Gym Settings
class GymSettingsState {
  final bool isLoading;
  final bool isSaving;
  final GymSettingsModel? settings;
  final String? error;
  final String? successMessage;

  GymSettingsState({
    this.isLoading = false,
    this.isSaving = false,
    this.settings,
    this.error,
    this.successMessage,
  });

  GymSettingsState copyWith({
    bool? isLoading,
    bool? isSaving,
    GymSettingsModel? settings,
    String? error,
    String? successMessage,
  }) {
    return GymSettingsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      settings: settings ?? this.settings,
      error: error,
      successMessage: successMessage,
    );
  }
}

class GymSettingsNotifier extends Notifier<GymSettingsState> {
  @override
  GymSettingsState build() {
    Future.microtask(() => loadSettings());
    return GymSettingsState(isLoading: true);
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = ref.read(settingsServiceProvider);
      final data = await service.getGymSettings();
      state = state.copyWith(isLoading: false, settings: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> saveSettings(GymSettingsModel updated) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      final service = ref.read(settingsServiceProvider);
      final saved = await service.updateGymSettings(updated);
      state = state.copyWith(
        isSaving: false,
        settings: saved,
        successMessage: 'Configuración guardada exitosamente',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}

final gymSettingsProvider = NotifierProvider<GymSettingsNotifier, GymSettingsState>(() {
  return GymSettingsNotifier();
});

// State for WhatsApp Connection
class WhatsappState {
  final bool isLoading;
  final WhatsappStatusModel? status;
  final String? error;
  final bool isSendingTest;

  WhatsappState({
    this.isLoading = false,
    this.status,
    this.error,
    this.isSendingTest = false,
  });

  WhatsappState copyWith({
    bool? isLoading,
    WhatsappStatusModel? status,
    String? error,
    bool? isSendingTest,
  }) {
    return WhatsappState(
      isLoading: isLoading ?? this.isLoading,
      status: status ?? this.status,
      error: error,
      isSendingTest: isSendingTest ?? this.isSendingTest,
    );
  }
}

class WhatsappNotifier extends Notifier<WhatsappState> {
  Timer? _pollingTimer;

  @override
  WhatsappState build() {
    ref.onDispose(() {
      _pollingTimer?.cancel();
    });
    Future.microtask(() => checkStatus());
    _startPolling();
    return WhatsappState(isLoading: true);
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      checkStatus(silent: true);
    });
  }

  Future<void> checkStatus({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final service = ref.read(settingsServiceProvider);
      final res = await service.getWhatsappStatus();
      state = state.copyWith(isLoading: false, status: res);
    } catch (e) {
      if (!silent) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  Future<void> restart() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = ref.read(settingsServiceProvider);
      await service.restartWhatsapp();
      await Future.delayed(const Duration(seconds: 2));
      await checkStatus();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = ref.read(settingsServiceProvider);
      await service.logoutWhatsapp();
      await Future.delayed(const Duration(seconds: 2));
      await checkStatus();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<({bool success, String message})> sendTestMessage(String phoneNumber, String message) async {
    state = state.copyWith(isSendingTest: true);
    try {
      final service = ref.read(settingsServiceProvider);
      final res = await service.sendTestWhatsapp(phoneNumber, message);
      state = state.copyWith(isSendingTest: false);
      return res;
    } catch (e) {
      state = state.copyWith(isSendingTest: false);
      return (success: false, message: e.toString());
    }
  }
}

final whatsappProvider = NotifierProvider<WhatsappNotifier, WhatsappState>(() {
  return WhatsappNotifier();
});

// ================= EMAIL CONFIGURATION STATE =================

class EmailConfigState {
  final bool isLoading;
  final bool isSaving;
  final bool isVerifying;
  final bool isSendingTest;
  final EmailConfigModel? config;
  final String? error;
  final String? successMessage;

  EmailConfigState({
    this.isLoading = false,
    this.isSaving = false,
    this.isVerifying = false,
    this.isSendingTest = false,
    this.config,
    this.error,
    this.successMessage,
  });

  EmailConfigState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isVerifying,
    bool? isSendingTest,
    EmailConfigModel? config,
    String? error,
    String? successMessage,
  }) {
    return EmailConfigState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isVerifying: isVerifying ?? this.isVerifying,
      isSendingTest: isSendingTest ?? this.isSendingTest,
      config: config ?? this.config,
      error: error,
      successMessage: successMessage,
    );
  }
}

class EmailConfigNotifier extends Notifier<EmailConfigState> {
  @override
  EmailConfigState build() {
    Future.microtask(() => loadConfig());
    return EmailConfigState(isLoading: true);
  }

  Future<void> loadConfig() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = ref.read(settingsServiceProvider);
      final cfg = await service.getEmailConfig();
      state = state.copyWith(isLoading: false, config: cfg ?? EmailConfigModel());
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> saveConfig(EmailConfigModel newConfig) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    try {
      final service = ref.read(settingsServiceProvider);
      final saved = await service.saveEmailConfig(newConfig);
      state = state.copyWith(
        isSaving: false,
        config: saved,
        successMessage: 'Configuración de correo guardada exitosamente.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<({bool success, String message})> verifyConfig(String testEmail) async {
    state = state.copyWith(isVerifying: true, error: null, successMessage: null);
    try {
      final service = ref.read(settingsServiceProvider);
      final res = await service.verifyEmailConfig(testEmail);
      if (res.success) {
        final refreshed = await service.getEmailConfig();
        state = state.copyWith(isVerifying: false, config: refreshed, successMessage: res.message);
      } else {
        state = state.copyWith(isVerifying: false, error: res.message);
      }
      return res;
    } catch (e) {
      state = state.copyWith(isVerifying: false, error: e.toString());
      return (success: false, message: e.toString());
    }
  }

  Future<({bool success, String message})> sendTestEmail(String testEmail, {String? subject, String? message}) async {
    state = state.copyWith(isSendingTest: true, error: null, successMessage: null);
    try {
      final service = ref.read(settingsServiceProvider);
      final res = await service.sendTestEmail(testEmail, subject: subject, message: message);
      state = state.copyWith(isSendingTest: false);
      return res;
    } catch (e) {
      state = state.copyWith(isSendingTest: false, error: e.toString());
      return (success: false, message: e.toString());
    }
  }
}

final emailConfigProvider = NotifierProvider<EmailConfigNotifier, EmailConfigState>(() {
  return EmailConfigNotifier();
});

class ZktecoSyncNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    final service = ref.read(settingsServiceProvider);
    final enabled = await service.getZktecoSyncEnabled();
    state = enabled;
  }

  Future<bool> setEnabled(bool enabled) async {
    final service = ref.read(settingsServiceProvider);
    final ok = await service.setZktecoSyncEnabled(enabled);
    if (ok) {
      state = enabled;
    }
    return ok;
  }
}

final zktecoSyncProvider = NotifierProvider<ZktecoSyncNotifier, bool>(ZktecoSyncNotifier.new);

