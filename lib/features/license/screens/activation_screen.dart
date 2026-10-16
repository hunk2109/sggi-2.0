import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import '../../../core/license/license_provider.dart';
import '../../../core/theme/app_theme.dart';

class ActivationScreen extends ConsumerStatefulWidget {
  const ActivationScreen({super.key});

  @override
  ConsumerState<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends ConsumerState<ActivationScreen> {
  final _keyCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    if (_keyCtrl.text.trim().isEmpty) return;
    setState(() => _busy = true);
    final ok = await ref.read(licenseProvider.notifier).activate(_keyCtrl.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Licencia activada correctamente')),
      );
    }
  }

  void _copy(String text, String msg) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final lic = ref.watch(licenseProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1218),
      body: Column(
        children: [
          // Barra de título (la ventana no tiene la nativa)
          SizedBox(
            height: 36,
            child: Row(
              children: [
                const Expanded(child: DragToMoveArea(child: SizedBox.expand())),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.white54),
                  onPressed: () => windowManager.close(),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: lic.isLoading
                  ? const CircularProgressIndicator()
                  : _buildCard(lic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(LicenseState lic) {
    return Container(
      width: 520,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF181C25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A303C)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.verified_user_outlined, size: 56, color: AppTheme.primary),
          const SizedBox(height: 12),
          const Text(
            'Activación de SGGI 2.0',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            'Envía el Código de Equipo a tu proveedor para recibir tu clave de activación.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 24),

          const Text('Código de Equipo (HW ID)', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    lic.hardwareId,
                    style: const TextStyle(fontFamily: 'Consolas', fontSize: 13, color: Colors.white),
                  ),
                ),
                IconButton(
                  tooltip: 'Copiar',
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () => _copy(lic.hardwareId, 'Código de equipo copiado'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _keyCtrl,
            maxLines: 4,
            style: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
            decoration: const InputDecoration(
              labelText: 'Clave de Activación',
              hintText: 'Pega aquí la clave recibida',
              border: OutlineInputBorder(),
            ),
          ),
          if (lic.error != null) ...[
            const SizedBox(height: 10),
            Text(lic.error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 46,
            child: FilledButton.icon(
              onPressed: _busy ? null : _activate,
              icon: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.key),
              label: const Text('ACTIVAR'),
            ),
          ),
        ],
      ),
    );
  }
}
