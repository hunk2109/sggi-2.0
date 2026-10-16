import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'license_validator.dart';

class LicenseState {
  final bool isLoading;
  final String hardwareId;
  final LicenseData? license;
  final String? error;

  const LicenseState({
    this.isLoading = true,
    this.hardwareId = '',
    this.license,
    this.error,
  });

  bool get isActivated => license != null;

  /// Si no hay licencia, nada está habilitado (la app muestra la pantalla de activación).
  bool hasModule(String module) => license?.hasModule(module) ?? false;

  /// Indica si la licencia contratada incluye sincronización en la nube o es plan solo local.
  bool get hasCloudAccess => license?.cloudAccess ?? false;

  int? get daysRemaining => license?.expiresAt?.difference(DateTime.now()).inDays;
}

class LicenseNotifier extends Notifier<LicenseState> {
  static const _prefsKey = 'sggi_license_key';

  @override
  LicenseState build() {
    _init();
    return const LicenseState();
  }

  Future<void> _init() async {
    final hw = await getHardwareId();
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);

    LicenseData? data;
    String? error;
    if (saved != null) {
      final result = LicenseValidator.validate(saved, hw);
      if (result.isValid) {
        data = result.data;
      } else {
        error = result.errorMessage;
      }
    }
    state = LicenseState(isLoading: false, hardwareId: hw, license: data, error: error);
  }

  Future<bool> activate(String key) async {
    final result = LicenseValidator.validate(key, state.hardwareId);
    if (!result.isValid) {
      state = LicenseState(
        isLoading: false,
        hardwareId: state.hardwareId,
        error: result.errorMessage,
      );
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, key.replaceAll(RegExp(r'\s'), ''));
    state = LicenseState(isLoading: false, hardwareId: state.hardwareId, license: result.data);
    return true;
  }

  Future<void> deactivate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    state = LicenseState(isLoading: false, hardwareId: state.hardwareId);
  }

  /// Mismo cálculo de HW ID que SGTIG para que el generador sirva igual.
  static Future<String> getHardwareId() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isWindows) {
        final w = await info.windowsInfo;
        return w.deviceId.replaceAll('{', '').replaceAll('}', '').toUpperCase();
      }
    } catch (e) {
      debugPrint('Error obteniendo HW ID: $e');
    }
    return 'SGIRYT-DEVICE-UNKNOWN';
  }
}

final licenseProvider = NotifierProvider<LicenseNotifier, LicenseState>(LicenseNotifier.new);
