import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../memberships/services/promotion_service.dart';

class CreatePromotionDialog extends ConsumerStatefulWidget {
  const CreatePromotionDialog({super.key});

  @override
  ConsumerState<CreatePromotionDialog> createState() => _CreatePromotionDialogState();
}

class _CreatePromotionDialogState extends ConsumerState<CreatePromotionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '15');
  final _descriptionCtrl = TextEditingController();
  final _maxUsesCtrl = TextEditingController(text: '50');

  bool _hasMaxUses = true;
  bool _hasExpiration = false;
  DateTime _expiresAt = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _discountCtrl.dispose();
    _descriptionCtrl.dispose();
    _maxUsesCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final code = _codeCtrl.text.trim().toUpperCase();
    final discount = num.tryParse(_discountCtrl.text.trim()) ?? 0;
    final description = _descriptionCtrl.text.trim();
    final maxUses = _hasMaxUses ? int.tryParse(_maxUsesCtrl.text.trim()) : null;
    final expiresAt = _hasExpiration ? _expiresAt : null;

    setState(() => _isLoading = true);

    final success = await ref.read(promotionsProvider.notifier).createPromotion(
      code: code,
      discountPercentage: discount,
      description: description.isNotEmpty ? description : null,
      maxUses: maxUses,
      expiresAt: expiresAt,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Cupón "$code" creado exitosamente con $discount% de descuento.'),
              ],
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        final error = ref.read(promotionsProvider).error ?? 'Error al crear cupón';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E232B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(26),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.confirmation_number_outlined, color: Colors.amberAccent, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Nuevo Cupón / Promoción',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Colors.white54),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 24, color: Colors.white12),

                // Código
                const Text('Código del Cupón *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_-]')),
                    UpperCaseTextFormatter(),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Ej. PROMO20, BIENVENIDA, OCTUBRE10',
                    prefixIcon: Icon(Icons.local_offer_outlined, size: 18),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Por favor ingresa un código para el cupón';
                    }
                    if (val.trim().length < 3) {
                      return 'El código debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Porcentaje de Descuento
                const Text('Porcentaje de Descuento (%) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _discountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: 'Ej. 20',
                    prefixIcon: Icon(Icons.percent, size: 18),
                    suffixText: '% OFF',
                    suffixStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.amberAccent),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Por favor ingresa el porcentaje de descuento';
                    }
                    final numVal = int.tryParse(val.trim());
                    if (numVal == null || numVal <= 0 || numVal > 100) {
                      return 'El descuento debe ser entre 1% y 100%';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Descripción
                const Text('Descripción / Motivo (Opcional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descriptionCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Ej. 20% de descuento especial por aniversario para renovación de membresías.',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 18),
                      child: Icon(Icons.notes, size: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Límite de Usos
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Límite de Canjes / Usos', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                    Row(
                      children: [
                        Checkbox(
                          value: _hasMaxUses,
                          activeColor: AppTheme.primary,
                          onChanged: (val) => setState(() => _hasMaxUses = val ?? true),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _hasMaxUses = !_hasMaxUses),
                          child: Text(
                            _hasMaxUses ? 'Con límite' : 'Ilimitado',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_hasMaxUses) ...[
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _maxUsesCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: 'Cantidad máxima de usos permitidos (ej. 50)',
                      prefixIcon: Icon(Icons.pin_outlined, size: 18),
                    ),
                    validator: (val) {
                      if (_hasMaxUses) {
                        if (val == null || val.trim().isEmpty) return 'Ingresa el número máximo de usos';
                        final numVal = int.tryParse(val.trim());
                        if (numVal == null || numVal <= 0) return 'Debe ser un número mayor a 0';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),

                // Fecha de Expiración
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Fecha de Expiración', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                    Row(
                      children: [
                        Checkbox(
                          value: _hasExpiration,
                          activeColor: AppTheme.primary,
                          onChanged: (val) => setState(() => _hasExpiration = val ?? false),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _hasExpiration = !_hasExpiration),
                          child: Text(
                            _hasExpiration ? 'Con vencimiento' : 'Sin caducidad',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_hasExpiration) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _expiresAt,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                      );
                      if (picked != null) {
                        setState(() => _expiresAt = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15181E),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.event, size: 18, color: Colors.amberAccent),
                              const SizedBox(width: 10),
                              Text(
                                'Válido hasta: ${DateFormat('dd/MM/yyyy').format(_expiresAt)}',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const Text('Cambiar', style: TextStyle(fontSize: 11, color: Colors.amberAccent)),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 26),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: _isLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save, size: 18, color: Colors.white),
                      label: Text(
                        _isLoading ? 'Guardando...' : 'Crear Cupón',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      onPressed: _isLoading ? null : _handleSubmit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
