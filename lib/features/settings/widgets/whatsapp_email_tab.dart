import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../models/email_config_model.dart';
import '../providers/settings_provider.dart';

class WhatsappEmailTab extends ConsumerStatefulWidget {
  const WhatsappEmailTab({super.key});

  @override
  ConsumerState<WhatsappEmailTab> createState() => _WhatsappEmailTabState();
}

class _WhatsappEmailTabState extends ConsumerState<WhatsappEmailTab> {
  // WhatsApp test controllers
  final _testPhoneCtrl = TextEditingController();
  final _testMessageCtrl = TextEditingController(text: '¡Hola! Este es un mensaje de prueba desde SGGI 2.0.');

  // Email configuration controllers
  final _emailSenderEmailCtrl = TextEditingController();
  final _emailPasswordCtrl = TextEditingController();
  final _emailSenderNameCtrl = TextEditingController();
  final _emailSmtpHostCtrl = TextEditingController(text: 'smtp.gmail.com');
  final _emailSmtpPortCtrl = TextEditingController(text: '587');
  final _emailSmtpUserCtrl = TextEditingController();
  final _emailSmtpPasswordCtrl = TextEditingController();
  final _emailTestRecipientCtrl = TextEditingController();
  String _emailProvider = 'GOOGLE';
  bool _emailUseSsl = false;
  bool _emailUseTls = true;
  bool _emailPasswordVisible = false;
  bool _isEmailInitialized = false;

  @override
  void dispose() {
    _testPhoneCtrl.dispose();
    _testMessageCtrl.dispose();
    _emailSenderEmailCtrl.dispose();
    _emailPasswordCtrl.dispose();
    _emailSenderNameCtrl.dispose();
    _emailSmtpHostCtrl.dispose();
    _emailSmtpPortCtrl.dispose();
    _emailSmtpUserCtrl.dispose();
    _emailSmtpPasswordCtrl.dispose();
    _emailTestRecipientCtrl.dispose();
    super.dispose();
  }

  void _populateEmailFields(EmailConfigModel config) {
    if (_isEmailInitialized) return;
    _emailSenderEmailCtrl.text = config.email;
    _emailPasswordCtrl.text = config.password ?? '';
    _emailSenderNameCtrl.text = config.senderName ?? '';
    _emailProvider = config.provider.isNotEmpty ? config.provider : 'GOOGLE';
    _emailSmtpHostCtrl.text = config.smtpHost ??
        (_emailProvider == 'GOOGLE'
            ? 'smtp.gmail.com'
            : _emailProvider == 'MICROSOFT'
                ? 'smtp.office365.com'
                : '');
    _emailSmtpPortCtrl.text = (config.smtpPort ?? 587).toString();
    _emailSmtpUserCtrl.text = config.smtpUser ?? '';
    _emailSmtpPasswordCtrl.text = config.smtpPassword ?? '';
    _emailUseSsl = config.useSSL;
    _emailUseTls = config.useTLS;
    _isEmailInitialized = true;
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: AppTheme.primary,
            child: Text(number, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildWhatsappSectionHeader(bool isConnected, bool isQrReady) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chat_bubble_outline, color: Colors.green, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Instancia y Servicio de WhatsApp Web',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  'Conecta el teléfono del gimnasio mediante código QR para enviar comprobantes, recordatorios y alertas instantáneas.',
                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isConnected
                  ? AppTheme.success.withValues(alpha: 0.15)
                  : isQrReady
                      ? Colors.orange.withValues(alpha: 0.15)
                      : Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isConnected
                    ? AppTheme.success
                    : isQrReady
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isConnected
                        ? AppTheme.success
                        : isQrReady
                            ? Colors.orange
                            : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isConnected
                      ? 'WhatsApp Conectado'
                      : isQrReady
                          ? 'Escanea Código QR'
                          : 'Desconectado',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isConnected
                        ? AppTheme.success
                        : isQrReady
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSection(EmailConfigState emailState) {
    final emailConfig = emailState.config;
    final isVerified = emailConfig?.isVerified ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.darkBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.mark_email_read_outlined, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuración de Correo Electrónico Saliente (Emisor / SMTP)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Configura la cuenta de correo que enviará comprobantes de pago, recordatorios de cuotas, avisos de membresías y reportes de caja.',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isVerified
                      ? AppTheme.success.withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isVerified ? AppTheme.success : Colors.orange,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVerified ? Icons.check_circle : Icons.info_outline,
                      size: 14,
                      color: isVerified ? AppTheme.success : Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isVerified ? 'Servidor Verificado' : 'No Verificado',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isVerified ? AppTheme.success : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Cards Row: Left (Configuración) & Right (Prueba de Envío)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Card: Datos del Servidor y Remitente (flex 7)
            Expanded(
              flex: 7,
              child: Card(
                color: AppTheme.darkCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.darkBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Datos del Remitente y Conexión',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Selecciona el proveedor y los datos de autenticación para el envío de correos.',
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
                      ),
                      const Divider(height: 24, color: AppTheme.darkBorder),

                      // Provider Selector
                      const Text('Proveedor de Correo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.darkSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.darkBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _emailProvider,
                            isExpanded: true,
                            dropdownColor: AppTheme.darkCard,
                            items: const [
                              DropdownMenuItem(
                                value: 'GOOGLE',
                                child: Row(
                                  children: [
                                    Icon(Icons.g_mobiledata, color: Colors.redAccent, size: 24),
                                    SizedBox(width: 8),
                                    Text('Google Gmail / Google Workspace (Recomendado)'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'MICROSOFT',
                                child: Row(
                                  children: [
                                    Icon(Icons.window, color: Colors.blueAccent, size: 18),
                                    SizedBox(width: 12),
                                    Text('Microsoft Outlook / Office 365'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'SMTP',
                                child: Row(
                                  children: [
                                    Icon(Icons.dns_outlined, color: AppTheme.primary, size: 18),
                                    SizedBox(width: 12),
                                    Text('Servidor SMTP Personalizado (cPanel, SendGrid, etc.)'),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _emailProvider = val;
                                  if (val == 'GOOGLE') {
                                    _emailSmtpHostCtrl.text = 'smtp.gmail.com';
                                    _emailSmtpPortCtrl.text = '587';
                                    _emailUseSsl = false;
                                    _emailUseTls = true;
                                  } else if (val == 'MICROSOFT') {
                                    _emailSmtpHostCtrl.text = 'smtp.office365.com';
                                    _emailSmtpPortCtrl.text = '587';
                                    _emailUseSsl = false;
                                    _emailUseTls = true;
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Sender Name & Sender Email
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Nombre del Remitente', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _emailSenderNameCtrl,
                                  decoration: const InputDecoration(
                                    hintText: 'Ej: SGGI Fitness Club',
                                    prefixIcon: Icon(Icons.badge_outlined, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Correo Electrónico Emisor *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _emailSenderEmailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    hintText: 'Ej: contacto@gimnasio.com',
                                    prefixIcon: Icon(Icons.email_outlined, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Password / App Password
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _emailProvider == 'GOOGLE'
                                    ? 'Contraseña de Aplicación de Google (16 caracteres) *'
                                    : 'Contraseña del Correo / App Password *',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 6),
                              Tooltip(
                                message: _emailProvider == 'GOOGLE'
                                    ? 'En Google no uses tu contraseña normal. Ve a tu cuenta Google > Seguridad > Verificación en dos pasos > Contraseñas de aplicaciones y genera una clave de 16 letras.'
                                    : 'Contraseña para autenticar con el servidor de correo.',
                                child: const Icon(Icons.help_outline, size: 15, color: Colors.white54),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _emailPasswordCtrl,
                            obscureText: !_emailPasswordVisible,
                            decoration: InputDecoration(
                              hintText: _emailProvider == 'GOOGLE' ? 'xxxx xxxx xxxx xxxx' : '••••••••••••',
                              prefixIcon: const Icon(Icons.lock_outline, size: 18),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _emailPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _emailPasswordVisible = !_emailPasswordVisible;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      // If Provider is SMTP, show host, port, user, pass, ssl/tls
                      if (_emailProvider == 'SMTP') ...[
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              flex: 7,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Servidor SMTP Host *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _emailSmtpHostCtrl,
                                    decoration: const InputDecoration(
                                      hintText: 'Ej: mail.midominio.com',
                                      prefixIcon: Icon(Icons.dns, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Puerto SMTP *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  TextField(
                                    controller: _emailSmtpPortCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: '587 o 465',
                                      prefixIcon: Icon(Icons.numbers, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Switch(
                                    value: _emailUseSsl,
                                    activeThumbColor: AppTheme.primary,
                                    onChanged: (val) => setState(() => _emailUseSsl = val),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Usar SSL (Puerto 465)', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Switch(
                                    value: _emailUseTls,
                                    activeThumbColor: AppTheme.primary,
                                    onChanged: (val) => setState(() => _emailUseTls = val),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Usar TLS / STARTTLS', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: emailState.isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.save_outlined, size: 18),
                          label: Text(emailState.isSaving ? 'Guardando...' : 'Guardar Configuración de Correo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: emailState.isSaving
                              ? null
                              : () async {
                                  final email = _emailSenderEmailCtrl.text.trim();
                                  if (email.isEmpty || !email.contains('@')) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Ingresa un correo electrónico emisor válido.'),
                                        backgroundColor: AppTheme.warning,
                                      ),
                                    );
                                    return;
                                  }

                                  final newConfig = EmailConfigModel(
                                    id: emailConfig?.id,
                                    provider: _emailProvider,
                                    email: email,
                                    password: _emailPasswordCtrl.text.trim(),
                                    senderName: _emailSenderNameCtrl.text.trim(),
                                    smtpHost: _emailProvider == 'SMTP'
                                        ? _emailSmtpHostCtrl.text.trim()
                                        : _emailProvider == 'GOOGLE'
                                            ? 'smtp.gmail.com'
                                            : 'smtp.office365.com',
                                    smtpPort: int.tryParse(_emailSmtpPortCtrl.text.trim()) ?? 587,
                                    smtpUser: _emailSmtpUserCtrl.text.trim().isNotEmpty
                                        ? _emailSmtpUserCtrl.text.trim()
                                        : email,
                                    smtpPassword: _emailSmtpPasswordCtrl.text.trim().isNotEmpty
                                        ? _emailSmtpPasswordCtrl.text.trim()
                                        : _emailPasswordCtrl.text.trim(),
                                    useSSL: _emailUseSsl,
                                    useTLS: _emailUseTls,
                                    isActive: true,
                                  );

                                  final ok = await ref.read(emailConfigProvider.notifier).saveConfig(newConfig);
                                  if (!mounted || !context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ok
                                            ? 'Configuración de correo guardada con éxito.'
                                            : (emailState.error ?? 'Error al guardar configuración.'),
                                      ),
                                      backgroundColor: ok ? AppTheme.success : AppTheme.error,
                                    ),
                                  );
                                },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),

            // Right Card: Verificación y Prueba de Envío (flex 5)
            Expanded(
              flex: 5,
              child: Card(
                color: AppTheme.darkCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.darkBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Prueba y Verificación de Envío',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Comprueba la autenticación con el servidor y envía un correo real de prueba.',
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
                      ),
                      const Divider(height: 24, color: AppTheme.darkBorder),

                      const Text('Correo de Destino para Prueba', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailTestRecipientCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Ej: tu-correo-personal@gmail.com',
                          prefixIcon: Icon(Icons.send_outlined, size: 18),
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: (emailState.isVerifying || emailState.isSendingTest)
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.verified_outlined, size: 18),
                          label: Text(
                            (emailState.isVerifying || emailState.isSendingTest)
                                ? 'Verificando y Enviando...'
                                : 'Verificar y Enviar Prueba',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: (emailState.isVerifying || emailState.isSendingTest)
                              ? null
                              : () async {
                                  final testRecipient = _emailTestRecipientCtrl.text.trim();
                                  if (testRecipient.isEmpty || !testRecipient.contains('@')) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Ingresa un correo de destino válido para la prueba.'),
                                        backgroundColor: AppTheme.warning,
                                      ),
                                    );
                                    return;
                                  }

                                  // Primero guardar si no se ha guardado o se modificó
                                  final senderEmail = _emailSenderEmailCtrl.text.trim();
                                  if (senderEmail.isNotEmpty) {
                                    final currentConfig = EmailConfigModel(
                                      id: emailConfig?.id,
                                      provider: _emailProvider,
                                      email: senderEmail,
                                      password: _emailPasswordCtrl.text.trim(),
                                      senderName: _emailSenderNameCtrl.text.trim(),
                                      smtpHost: _emailProvider == 'SMTP'
                                          ? _emailSmtpHostCtrl.text.trim()
                                          : _emailProvider == 'GOOGLE'
                                              ? 'smtp.gmail.com'
                                              : 'smtp.office365.com',
                                      smtpPort: int.tryParse(_emailSmtpPortCtrl.text.trim()) ?? 587,
                                      smtpUser: _emailSmtpUserCtrl.text.trim().isNotEmpty
                                          ? _emailSmtpUserCtrl.text.trim()
                                          : senderEmail,
                                      smtpPassword: _emailSmtpPasswordCtrl.text.trim().isNotEmpty
                                          ? _emailSmtpPasswordCtrl.text.trim()
                                          : _emailPasswordCtrl.text.trim(),
                                      useSSL: _emailUseSsl,
                                      useTLS: _emailUseTls,
                                      isActive: true,
                                    );
                                    await ref.read(emailConfigProvider.notifier).saveConfig(currentConfig);
                                  }

                                  final res = await ref.read(emailConfigProvider.notifier).verifyConfig(testRecipient);
                                  if (!mounted || !context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(res.message),
                                      backgroundColor: res.success ? AppTheme.success : AppTheme.error,
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Guide Box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.darkSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.darkBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.lightbulb_outline, size: 18, color: Colors.amber),
                                const SizedBox(width: 8),
                                Text(
                                  _emailProvider == 'GOOGLE'
                                      ? 'Guía Rápida para Gmail'
                                      : _emailProvider == 'MICROSOFT'
                                          ? 'Guía Rápida para Outlook'
                                          : 'Guía Rápida para SMTP',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _emailProvider == 'GOOGLE'
                                  ? '1. Activa la verificación en dos pasos en tu cuenta de Google.\n'
                                    '2. Ve a "Seguridad" > "Contraseñas de aplicaciones".\n'
                                    '3. Crea una clave con el nombre "Gimnasio".\n'
                                    '4. Pega aquí la contraseña de 16 letras generada.'
                                  : _emailProvider == 'MICROSOFT'
                                      ? 'Usa tu correo de Office 365 / Outlook (@outlook.com, @hotmail.com o corporativo). Si tu cuenta tiene 2FA, crea una contraseña de aplicación en la configuración de seguridad de Microsoft.'
                                      : 'Ingresa los datos de conexión SMTP que te suministra tu proveedor de correo o hosting. Para SSL usa el puerto 465; para TLS usa el puerto 587.',
                              style: TextStyle(fontSize: 12, height: 1.5, color: Colors.white.withValues(alpha: 0.75)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wpState = ref.watch(whatsappProvider);
    final emailState = ref.watch(emailConfigProvider);

    if (emailState.config != null) {
      _populateEmailFields(emailState.config!);
    }

    final status = wpState.status;
    final isConnected = status?.isConnected ?? false;
    final isQrReady = status?.isQrReady ?? false;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWhatsappSectionHeader(isConnected, isQrReady),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Card: Connection Status & QR Code
              Expanded(
                flex: 5,
                child: Card(
                  color: AppTheme.darkCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppTheme.darkBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Status Header Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Estado de Conexión',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isConnected
                                    ? AppTheme.success.withValues(alpha: 0.15)
                                    : isQrReady
                                        ? Colors.orange.withValues(alpha: 0.15)
                                        : Colors.red.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isConnected
                                      ? AppTheme.success
                                      : isQrReady
                                          ? Colors.orange
                                          : Colors.red,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: isConnected
                                          ? AppTheme.success
                                          : isQrReady
                                              ? Colors.orange
                                              : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    status?.label ?? 'Cargando...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isConnected
                                          ? AppTheme.success
                                          : isQrReady
                                              ? Colors.orange
                                              : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32, color: AppTheme.darkBorder),

                        // QR / Connected View
                        if (wpState.isLoading && status == null)
                          const Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(),
                          )
                        else if (isConnected) ...[
                          const Icon(Icons.check_circle_outline, size: 72, color: AppTheme.success),
                          const SizedBox(height: 16),
                          const Text(
                            'WhatsApp Vinculado y Activo',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'El sistema puede enviar facturas en PDF, recibos de caja, alertas de vencimiento y confirmaciones de membresía directamente a los socios.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
                          ),
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.logout, size: 16, color: Colors.redAccent),
                                label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('¿Cerrar sesión de WhatsApp?'),
                                      content: const Text('Se desvinculará el número actual y será necesario escanear un nuevo código QR.'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Desvincular')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    ref.read(whatsappProvider.notifier).logout();
                                  }
                                },
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.restart_alt, size: 16),
                                label: const Text('Reiniciar Servicio'),
                                onPressed: () => ref.read(whatsappProvider.notifier).restart(),
                              ),
                            ],
                          ),
                        ] else if (isQrReady) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: QrImageView(
                              data: status!.qr!,
                              version: QrVersions.auto,
                              size: 240,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Escanea este código con tu teléfono',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.darkSurface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.darkBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInstructionStep('1', 'Abre WhatsApp en el teléfono del gimnasio.'),
                                _buildInstructionStep('2', 'Toca Ajustes o Configuración > Dispositivos vinculados.'),
                                _buildInstructionStep('3', 'Toca "Vincular un dispositivo" y apunta con la cámara.'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Regenerar Código QR'),
                            onPressed: () => ref.read(whatsappProvider.notifier).restart(),
                          ),
                        ] else ...[
                          const Icon(Icons.signal_wifi_off, size: 64, color: Colors.white30),
                          const SizedBox(height: 16),
                          Text(
                            status?.label ?? 'Iniciando cliente de WhatsApp...',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Si tarda en responder, puedes forzar un reinicio del proceso.',
                            style: TextStyle(fontSize: 12, color: Colors.white54),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow, size: 16),
                            label: const Text('Iniciar / Reiniciar Cliente'),
                            onPressed: () => ref.read(whatsappProvider.notifier).restart(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Right Card: Test Message & Information
              Expanded(
                flex: 4,
                child: Card(
                  color: AppTheme.darkCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppTheme.darkBorder),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Prueba de Envío Directo',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Envía un mensaje de comprobación para verificar que el bot responde correctamente.',
                          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
                        ),
                        const Divider(height: 24, color: AppTheme.darkBorder),

                        const Text('Número de Destino (con o sin prefijo RD)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _testPhoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: 'Ej: 8091234567 o 8295551234',
                            prefixIcon: Icon(Icons.phone, size: 18),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const Text('Mensaje de Prueba', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _testMessageCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Escribe tu mensaje...',
                          ),
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: wpState.isSendingTest
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.send, size: 16),
                            label: const Text('Enviar Mensaje de Prueba'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isConnected ? AppTheme.primary : Colors.grey.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: (!isConnected || wpState.isSendingTest)
                                ? null
                                : () async {
                                    final phone = _testPhoneCtrl.text.trim();
                                    final msg = _testMessageCtrl.text.trim();
                                    if (phone.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Ingresa un número de teléfono válido'), backgroundColor: AppTheme.warning),
                                      );
                                      return;
                                    }
                                    final res = await ref.read(whatsappProvider.notifier).sendTestMessage(phone, msg);
                                    if (!mounted || !context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(res.message),
                                        backgroundColor: res.success ? AppTheme.success : AppTheme.error,
                                      ),
                                    );
                                  },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Information box
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.darkSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.darkBorder),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, size: 18, color: AppTheme.accent),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'El servicio corre localmente en el servidor backend mediante una instancia controlada de WhatsApp Web. No requiere pago de APIs externas.',
                                  style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Email Configuration Section
          _buildEmailSection(emailState),
        ],
      ),
    );
  }
}
