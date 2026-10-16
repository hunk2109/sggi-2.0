import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sggi_desktop/core/license/license_validator.dart';

/// Replica exacta de generarLicencia() en generador_licencias_gui.html.
String generar(String hw, {bool nube = true, String mods = 'ALL', int exp = 0, String secret = 'SGIRYT_P0w3R_K3Y_2026!#_SECURE'}) {
  final payload = '${hw.toUpperCase()}|${nube ? 1 : 0}|$mods|$exp';
  final sig = Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(payload)).toString();
  return base64Encode(utf8.encode('$payload::$sig'));
}

void main() {
  const hw = 'ABCD-1234-EFGH';

  test('clave FULL permanente es válida', () {
    final r = LicenseValidator.validate(generar(hw), hw);
    expect(r.isValid, true);
    expect(r.data!.hasModule(LicenseModules.caja), true);
    expect(r.data!.expiresAt, isNull);
  });

  test('módulos parciales', () {
    final r = LicenseValidator.validate(generar(hw, mods: 'POS,CAJA', nube: false), hw);
    expect(r.isValid, true);
    expect(r.data!.cloudAccess, false);
    expect(r.data!.hasModule('POS'), true);
    expect(r.data!.hasModule('EMPLEADOS'), false);
  });

  test('otro equipo es rechazado', () {
    final r = LicenseValidator.validate(generar(hw), 'OTRO-EQUIPO');
    expect(r.error, LicenseError.wrongDevice);
  });

  test('clave expirada es rechazada', () {
    final past = DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch;
    final r = LicenseValidator.validate(generar(hw, exp: past), hw);
    expect(r.error, LicenseError.expired);
  });

  test('firma alterada es rechazada', () {
    final r = LicenseValidator.validate(generar(hw, secret: 'otra'), hw);
    expect(r.error, LicenseError.invalidSignature);
  });

  test('clave real generada por motor WebCrypto/Node.js es 100% válida', () {
    const nodeGeneratedKey = 'VEVTVC1ERVZJQ0UtV0lORE9XUy0xMjM0fDF8QUxMfDA6OmZhYTMxNzQzMWMyZDg1N2UxOTY2YzgwYTlhYjgxMTlmYzVjMTY0OTUwY2YwN2M1OTZlMDBiZDZiMjQwN2ZhZTQ=';
    final r = LicenseValidator.validate(nodeGeneratedKey, 'TEST-DEVICE-WINDOWS-1234');
    expect(r.isValid, true);
    expect(r.data!.cloudAccess, true);
    expect(r.data!.hasModule('CAJA'), true);
    expect(r.data!.hasModule('POS'), true);
  });

  test('basura es rechazada', () {
    expect(LicenseValidator.validate('no-es-una-clave', hw).isValid, false);
  });
}
