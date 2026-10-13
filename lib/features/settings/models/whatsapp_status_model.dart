class WhatsappStatusModel {
  final String status;
  final String? qr;

  WhatsappStatusModel({
    required this.status,
    this.qr,
  });

  bool get isConnected => status == 'CONNECTED';
  bool get isQrReady => status == 'QR_READY' && qr != null && qr!.isNotEmpty;
  bool get isInitializing => status == 'INITIALIZING';
  bool get isDisconnected => status == 'DISCONNECTED';
  bool get isAuthFailure => status == 'AUTH_FAILURE';

  String get label {
    switch (status) {
      case 'CONNECTED':
        return 'Conectado';
      case 'QR_READY':
        return 'Esperando escaneo de código QR';
      case 'INITIALIZING':
        return 'Iniciando servicio...';
      case 'AUTHENTICATING':
        return 'Autenticando...';
      case 'AUTH_FAILURE':
        return 'Fallo de autenticación';
      default:
        return 'Desconectado';
    }
  }

  factory WhatsappStatusModel.fromJson(Map<String, dynamic> json) {
    return WhatsappStatusModel(
      status: json['status']?.toString() ?? 'DISCONNECTED',
      qr: json['qr']?.toString(),
    );
  }
}
