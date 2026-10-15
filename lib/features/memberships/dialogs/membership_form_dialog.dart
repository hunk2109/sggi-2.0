import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/membership_model.dart';
import '../providers/memberships_catalog_provider.dart';

class MembershipFormDialog extends ConsumerStatefulWidget {
  final MembershipModel? membershipToEdit;

  const MembershipFormDialog({super.key, this.membershipToEdit});

  @override
  ConsumerState<MembershipFormDialog> createState() => _MembershipFormDialogState();
}

class _MembershipFormDialogState extends ConsumerState<MembershipFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _durationValueController;
  late TextEditingController _pricePerCompanionController;
  late TextEditingController _maxCompanionsController;
  final _newBenefitController = TextEditingController();

  // Duración: 'months' o 'days'
  String _durationType = 'months';
  int _selectedPresetMonths = 1;

  // Tipo: 'individual' o 'group'
  String _membershipType = 'individual';

  // Opciones booleanas
  bool _isActive = true;
  bool _isRecurring = true;

  // Beneficios
  List<String> _benefits = [];

  bool _isSaving = false;

  final List<String> _suggestedBenefits = [
    'Acceso a Área de Pesas',
    'Área de Cardio',
    'Clases Grupales',
    'Acceso a Lockers',
    'Entrenador de Piso',
    'Evaluación Física Inicial',
    'Acceso 24/7',
    'Ducha y Vestidores',
    '1 Invitado Gratis al Mes',
    'Descuento en Suplementos (10%)',
  ];

  @override
  void initState() {
    super.initState();
    final m = widget.membershipToEdit;

    _nameController = TextEditingController(text: m?.name ?? '');
    _descriptionController = TextEditingController(text: m?.description ?? '');
    _priceController = TextEditingController(text: m != null && m.price > 0 ? m.price.toStringAsFixed(2) : '');

    if (m != null && m.durationDays != null && m.durationDays! > 0) {
      _durationType = 'days';
      _durationValueController = TextEditingController(text: m.durationDays.toString());
    } else {
      _durationType = 'months';
      final months = m?.durationMonths ?? 1;
      _selectedPresetMonths = [1, 2, 3, 6, 12].contains(months) ? months : 1;
      _durationValueController = TextEditingController(text: months.toString());
    }

    _membershipType = m?.type == MembershipType.group ? 'group' : 'individual';
    _pricePerCompanionController = TextEditingController(
      text: m != null && m.pricePerCompanion != null && m.pricePerCompanion! > 0
          ? m.pricePerCompanion!.toStringAsFixed(2)
          : '',
    );
    _maxCompanionsController = TextEditingController(
      text: m != null && m.maxGroupCompanions != null && m.maxGroupCompanions! > 0
          ? m.maxGroupCompanions.toString()
          : '2',
    );

    _isActive = m?.isActive ?? true;
    _isRecurring = m?.isRecurring ?? true;
    _benefits = List<String>.from(m?.benefits ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationValueController.dispose();
    _pricePerCompanionController.dispose();
    _maxCompanionsController.dispose();
    _newBenefitController.dispose();
    super.dispose();
  }

  void _addBenefit(String benefit) {
    final clean = benefit.trim();
    if (clean.isNotEmpty && !_benefits.contains(clean)) {
      setState(() {
        _benefits.add(clean);
        _newBenefitController.clear();
      });
    }
  }

  void _removeBenefit(String benefit) {
    setState(() {
      _benefits.remove(benefit);
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    int durationMonths = 1;
    int? durationDays;

    if (_durationType == 'months') {
      durationMonths = int.tryParse(_durationValueController.text.trim()) ?? _selectedPresetMonths;
      if (durationMonths < 1) durationMonths = 1;
    } else {
      durationDays = int.tryParse(_durationValueController.text.trim()) ?? 1;
      if (durationDays < 1) durationDays = 1;
      // Backend espera durationMonths numérico, asignamos proporcional o 1
      durationMonths = (durationDays / 30).ceil();
      if (durationMonths < 1) durationMonths = 1;
    }

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'price': price,
      'durationMonths': durationMonths,
      'durationDays': _durationType == 'days' ? durationDays : null,
      'type': _membershipType,
      'isActive': _isActive,
      'isRecurring': _isRecurring,
      'priceType': _membershipType == 'group' ? 'variable' : 'fixed',
      'benefits': _benefits,
      'pricePerCompanion': _membershipType == 'group'
          ? (double.tryParse(_pricePerCompanionController.text.trim()) ?? 0.0)
          : null,
      'maxGroupCompanions': _membershipType == 'group'
          ? (int.tryParse(_maxCompanionsController.text.trim()) ?? 2)
          : null,
    };

    setState(() => _isSaving = true);

    bool ok = false;
    final notifier = ref.read(membershipsCatalogProvider.notifier);

    if (widget.membershipToEdit != null) {
      ok = await notifier.updateMembership(widget.membershipToEdit!.id, data);
    } else {
      ok = await notifier.createMembership(data);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      if (ok) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.membershipToEdit != null
                  ? 'Plan "${_nameController.text.trim()}" actualizado exitosamente'
                  : 'Nuevo plan "${_nameController.text.trim()}" creado exitosamente',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar el plan de membresía'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.membershipToEdit != null;

    return Dialog(
      backgroundColor: const Color(0xFF1E232B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 680,
        constraints: const BoxConstraints(maxHeight: 740),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF2A303C))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.card_membership, color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Modificar Plan de Membresía' : 'Nuevo Plan de Membresía',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Configure las tarifas, duración y beneficios incluidos en este plan.',
                          style: TextStyle(fontSize: 12, color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SECCIÓN 1: IDENTIFICACIÓN DEL PLAN
                      _buildSectionHeader('1. Identificación del Plan', Icons.badge_outlined),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre del Plan *',
                                hintText: 'Ej: Mensualidad Regular, Plan Anual VIP...',
                                prefixIcon: Icon(Icons.title, size: 20),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'El nombre es obligatorio';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Precio Regular *',
                                hintText: '0.00',
                                prefixText: 'RD\$ ',
                                prefixIcon: Icon(Icons.attach_money, size: 20),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'El precio es obligatorio';
                                final val = double.tryParse(v);
                                if (val == null || val < 0) return 'Precio inválido';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Descripción del Plan (Opcional)',
                          hintText: 'Ej: Incluye acceso a todas las áreas de fuerza y máquinas en horario general.',
                        ),
                      ),

                      const SizedBox(height: 24),

                      // SECCIÓN 2: DURACIÓN Y RENOVACIÓN
                      _buildSectionHeader('2. Duración y Facturación', Icons.schedule_outlined),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16191E),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Selector de unidad (Meses vs Días)
                            Row(
                              children: [
                                const Text('Unidad de Plazo: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 12),
                                ChoiceChip(
                                  label: const Text('Por Meses (Regular)'),
                                  selected: _durationType == 'months',
                                  selectedColor: AppTheme.primary,
                                  onSelected: (val) {
                                    if (val) {
                                      setState(() {
                                        _durationType = 'months';
                                        _durationValueController.text = _selectedPresetMonths.toString();
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text('Por Días (Pase Corto)'),
                                  selected: _durationType == 'days',
                                  selectedColor: AppTheme.primary,
                                  onSelected: (val) {
                                    if (val) {
                                      setState(() {
                                        _durationType = 'days';
                                        _durationValueController.text = '1';
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            if (_durationType == 'months') ...[
                              const Text('Seleccionar Plazo en Meses:', style: TextStyle(fontSize: 12, color: Colors.white70)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [1, 2, 3, 6, 12].map((m) {
                                  final isSelected = _selectedPresetMonths == m && _durationValueController.text == m.toString();
                                  String lbl = '$m mes';
                                  if (m == 3) lbl = '3 meses (Trimestral)';
                                  if (m == 6) lbl = '6 meses (Semestral)';
                                  if (m == 12) lbl = '12 meses (Anual)';
                                  return ChoiceChip(
                                    label: Text(lbl),
                                    selected: isSelected,
                                    selectedColor: AppTheme.primary,
                                    onSelected: (s) {
                                      if (s) {
                                        setState(() {
                                          _selectedPresetMonths = m;
                                          _durationValueController.text = m.toString();
                                        });
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  SizedBox(
                                    width: 140,
                                    child: TextFormField(
                                      controller: _durationValueController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      decoration: const InputDecoration(
                                        labelText: 'Cantidad de Días *',
                                        hintText: '1',
                                        suffixText: 'días',
                                      ),
                                      validator: (v) {
                                        final val = int.tryParse(v ?? '');
                                        if (val == null || val <= 0) return 'Mínimo 1 día';
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () => setState(() => _durationValueController.text = '1'),
                                        child: const Text('1 Día (Pase Diario)'),
                                      ),
                                      OutlinedButton(
                                        onPressed: () => setState(() => _durationValueController.text = '7'),
                                        child: const Text('7 Días (Semana)'),
                                      ),
                                      OutlinedButton(
                                        onPressed: () => setState(() => _durationValueController.text = '15'),
                                        child: const Text('15 Días (Quincena)'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 14),
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 10),

                            // Switch Recurrente
                            Row(
                              children: [
                                Switch(
                                  value: _isRecurring,
                                  activeTrackColor: AppTheme.success,
                                  onChanged: (val) => setState(() => _isRecurring = val),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isRecurring ? 'Facturación Recurrente Automática' : 'Membresía No Recurrente (Plazo Fijo)',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        _isRecurring
                                            ? 'Al vencer el período, el sistema generará automáticamente la cuota pendiente de renovación.'
                                            : 'Al finalizar la vigencia, la membresía expira sin generar deudas ni facturas automáticas.',
                                        style: const TextStyle(fontSize: 11, color: Colors.white54),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // SECCIÓN 3: TIPO DE MEMBRESÍA
                      _buildSectionHeader('3. Modalidad del Plan', Icons.group_outlined),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _membershipType = 'individual'),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _membershipType == 'individual'
                                      ? AppTheme.primary.withValues(alpha: 0.15)
                                      : const Color(0xFF16191E),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _membershipType == 'individual' ? AppTheme.primary : Colors.white10,
                                    width: _membershipType == 'individual' ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      color: _membershipType == 'individual' ? AppTheme.primary : Colors.white54,
                                    ),
                                    const SizedBox(width: 10),
                                    const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Individual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text('1 único socio titular', style: TextStyle(fontSize: 11, color: Colors.white54)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _membershipType = 'group'),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _membershipType == 'group'
                                      ? AppTheme.primary.withValues(alpha: 0.15)
                                      : const Color(0xFF16191E),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _membershipType == 'group' ? AppTheme.primary : Colors.white10,
                                    width: _membershipType == 'group' ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.groups,
                                      color: _membershipType == 'group' ? AppTheme.primary : Colors.white54,
                                    ),
                                    const SizedBox(width: 10),
                                    const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Grupal / Pareja / Familiar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        Text('Titular + acompañantes adicionales', style: TextStyle(fontSize: 11, color: Colors.white54)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (_membershipType == 'group') ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16191E),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _pricePerCompanionController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                                  decoration: const InputDecoration(
                                    labelText: 'Precio por Acompañante Adicional',
                                    prefixText: 'RD\$ ',
                                    hintText: '0.00',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextFormField(
                                  controller: _maxCompanionsController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: const InputDecoration(
                                    labelText: 'Máx. Acompañantes Permitidos',
                                    hintText: '2',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // SECCIÓN 4: BENEFICIOS
                      _buildSectionHeader('4. Beneficios Incluidos', Icons.star_outline),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newBenefitController,
                              decoration: const InputDecoration(
                                hintText: 'Escriba un beneficio (ej: Acceso 24/7, Toallas)...',
                                prefixIcon: Icon(Icons.add_circle_outline, size: 20),
                              ),
                              onSubmitted: _addBenefit,
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Añadir'),
                            onPressed: () => _addBenefit(_newBenefitController.text),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Sugerencias rápidas
                      const Text('Sugerencias rápidas (clic para añadir):', style: TextStyle(fontSize: 11, color: Colors.white54)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _suggestedBenefits.where((b) => !_benefits.contains(b)).take(6).map((b) {
                          return ActionChip(
                            label: Text('+ $b', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                            backgroundColor: const Color(0xFF16191E),
                            side: const BorderSide(color: Colors.white12),
                            onPressed: () => _addBenefit(b),
                          );
                        }).toList(),
                      ),

                      if (_benefits.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Text('Beneficios asignados al plan:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _benefits.map((b) {
                            return Chip(
                              backgroundColor: AppTheme.primary.withValues(alpha: 0.18),
                              side: const BorderSide(color: AppTheme.primary),
                              avatar: const Icon(Icons.check_circle, size: 16, color: AppTheme.primary),
                              label: Text(b, style: const TextStyle(fontSize: 12, color: Colors.white)),
                              deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white70),
                              onDeleted: () => _removeBenefit(b),
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // SECCIÓN 5: ESTADO
                      _buildSectionHeader('5. Estado del Plan', Icons.toggle_on_outlined),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Switch(
                            value: _isActive,
                            activeTrackColor: AppTheme.success,
                            onChanged: (val) => setState(() => _isActive = val),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isActive ? 'Plan Activo (Disponible para asignar a socios)' : 'Plan Inactivo (Oculto en caja y recepción)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _isActive ? Colors.greenAccent : Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF2A303C))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                    ),
                    icon: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save, size: 18),
                    label: Text(isEditing ? 'Actualizar Plan' : 'Guardar Plan'),
                    onPressed: _isSaving ? null : _handleSubmit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }
}
