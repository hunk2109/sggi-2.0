import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Módulos licenciables de SGGI 2.0.
/// Deben coincidir con los IDs de `sggi` en generador_licencias_gui.html.
class LicenseModules {
  static const all = 'ALL';
  static const miembros = 'MIEMBROS';
  static const membresias = 'MEMBRESIAS';
  static const acceso = 'ACCESO';
  static const pos = 'POS';
  static const caja = 'CAJA';
  static const inventario = 'INVENTARIO';
  static const empleados = 'EMPLEADOS';
  static const campanas = 'CAMPANAS';
  static const reportes = 'REPORTES';
}

class LicenseData {
  final String hardwareId;
  final bool cloudAccess;
  final List<String> modules;
  final DateTime? expiresAt;

  const LicenseData({
    required this.hardwareId,
    required this.cloudAccess,
    required this.modules,
    this.expiresAt,
  });

  bool hasModule(String module) =>
      modules.contains(LicenseModules.all) || modules.contains(module.toUpperCase());
}

enum LicenseError { invalidFormat, invalidSignature, wrongDevice, expired }

class LicenseResult {
  final LicenseData? data;
  final LicenseError? error;

  const LicenseResult.ok(LicenseData this.data) : error = null;
  const LicenseResult.fail(LicenseError this.error) : data = null;

  bool get isValid => data != null;

  String get errorMessage => switch (error) {
        LicenseError.invalidFormat => 'La clave no tiene un formato válido.',
        LicenseError.invalidSignature => 'La clave no es auténtica (firma inválida).',
        LicenseError.wrongDevice => 'La clave fue generada para otro equipo.',
        LicenseError.expired => 'La licencia ha expirado.',
        null => '',
      };
}

/// Valida claves con el mismo formato del generador (y de SGTIG/PhonStore):
/// base64("HWID|nube|MOD1,MOD2|expMs::hmacSha256Hex")
class LicenseValidator {
  // Misma clave que usa generador_licencias_gui.html.
  static const _secretKey = 'SGIRYT_P0w3R_K3Y_2026!#_SECURE';

  static LicenseResult validate(String license, String hardwareId, {DateTime? now}) {
    final clean = license.replaceAll(RegExp(r'\s'), '');
    final targetHw = hardwareId.trim().toUpperCase();
    final key = utf8.encode(_secretKey);

    String decoded;
    try {
      decoded = utf8.decode(base64Decode(clean));
    } catch (_) {
      return _validateLegacy(clean, targetHw, key);
    }

    final parts = decoded.split('::');
    if (parts.length != 2) return _validateLegacy(clean, targetHw, key);

    final payload = parts[0];
    final signature = parts[1].trim().toLowerCase();
    final expected = Hmac(sha256, key).convert(utf8.encode(payload)).toString();
    if (expected != signature) {
      return const LicenseResult.fail(LicenseError.invalidSignature);
    }

    final p = payload.split('|');
    if (p.length < 3) return const LicenseResult.fail(LicenseError.invalidFormat);

    final payloadHw = p[0].trim().toUpperCase();
    if (payloadHw != targetHw) return const LicenseResult.fail(LicenseError.wrongDevice);

    final exp = p.length >= 4 ? int.tryParse(p[3].trim()) ?? 0 : 0;
    final expiresAt = exp > 0 ? DateTime.fromMillisecondsSinceEpoch(exp) : null;
    if (expiresAt != null && (now ?? DateTime.now()).isAfter(expiresAt)) {
      return const LicenseResult.fail(LicenseError.expired);
    }

    final modules = p[2]
        .toUpperCase()
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return LicenseResult.ok(LicenseData(
      hardwareId: payloadHw,
      cloudAccess: p[1].trim() == '1',
      modules: modules.isEmpty ? [LicenseModules.all] : modules,
      expiresAt: expiresAt,
    ));
  }

  /// Compatibilidad con claves antiguas: base64(hmac(HWID)) => FULL permanente.
  static LicenseResult _validateLegacy(String clean, String targetHw, List<int> key) {
    final legacy = base64Encode(Hmac(sha256, key).convert(utf8.encode(targetHw)).bytes);
    if (clean == legacy) {
      return LicenseResult.ok(LicenseData(
        hardwareId: targetHw,
        cloudAccess: true,
        modules: const [LicenseModules.all],
      ));
    }
    return const LicenseResult.fail(LicenseError.invalidFormat);
  }
}
