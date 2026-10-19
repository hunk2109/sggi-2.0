import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../members/models/member_model.dart';
import '../../members/providers/members_provider.dart';
import '../providers/employees_provider.dart';

class ConvertClientDialog extends ConsumerStatefulWidget {
  final MemberModel? preselectedMember;

  const ConvertClientDialog({
    super.key,
    this.preselectedMember,
  });

  static Future<bool?> show(BuildContext context, {MemberModel? preselectedMember}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ConvertClientDialog(preselectedMember: preselectedMember),
    );
  }

  @override
  ConsumerState<ConvertClientDialog> createState() => _ConvertClientDialogState();
}

class _ConvertClientDialogState extends ConsumerState<ConvertClientDialog> {
  final _formKey = GlobalKey<FormState>();

  MemberModel? _selectedMember;
  String _selectedRole = 'cashier';
  final _salaryController = TextEditingController(text: '25000');
  final _specializationController = TextEditingController(text: 'Atención al Cliente');
  bool _isLoading = false;

  final List<Map<String, String>> _roles = [
    {'value': 'cashier', 'label': 'Cajero / Recepción'},
    {'value': 'receptionist', 'label': 'Recepcionista'},
    {'value': 'trainer', 'label': 'Entrenador / Instructor'},
    {'value': 'supervisor', 'label': 'Supervisor / Encargado'},
    {'value': 'manager', 'label': 'Gerente de Sucursal'},
    {'value': 'nutritionist', 'label': 'Nutricionista'},
    {'value': 'cleaner', 'label': 'Limpieza / Mantenimiento'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedMember = widget.preselectedMember;
  }

  @override
  void dispose() {
    _salaryController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  Future<void> _handleConvert() async {
    if (_selectedMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione un socio'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final salary = double.tryParse(_salaryController.text.replaceAll(',', '').trim()) ?? 0.0;

    final result = await ref.read(employeesProvider.notifier).convertClientToEmployee(
      memberId: _selectedMember!.id,
      userId: _selectedMember!.userId,
      email: _selectedMember!.email,
      role: _selectedRole,
      salary: salary,
      specialization: _specializationController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      final success = result['success'] == true;
      final message = result['message']?.toString() ??
          (success ? 'Cliente promovido a empleado exitosamente' : 'Error al procesar');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? AppTheme.success : AppTheme.error,
          duration: const Duration(seconds: 4),
        ),
      );

      if (success) {
        // Recargar socios y empleados
        ref.read(membersProvider.notifier).loadMembers();
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersState = ref.watch(membersProvider);
    final allMembers = membersState.members;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 560,
        constraints: const BoxConstraints(maxHeight: 680),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2028),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF15181E),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.badge_outlined, color: AppTheme.primaryLight, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Convertir Socio a Empleado',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Promover cliente existente a personal del gimnasio',
                          style: TextStyle(fontSize: 12, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),

            // Form Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Client selection card / dropdown
                      const Text(
                        'CLIENTE / SOCIO SELECCIONADO',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.white38),
                      ),
                      const SizedBox(height: 8),

                      if (widget.preselectedMember != null) ...[
                        _buildMemberCard(widget.preselectedMember!),
                      ] else ...[
                        _buildMemberSelector(allMembers),
                        if (_selectedMember != null) ...[
                          const SizedBox(height: 12),
                          _buildMemberCard(_selectedMember!),
                        ],
                      ],

                      const SizedBox(height: 20),

                      const Text(
                        'DATOS DEL PUESTO LABORAL',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.white38),
                      ),
                      const SizedBox(height: 12),

                      // Role Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedRole,
                        dropdownColor: const Color(0xFF222731),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Puesto / Rol del Empleado *',
                          labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                          prefixIcon: const Icon(Icons.work_outline, color: Colors.white38, size: 18),
                          filled: true,
                          fillColor: const Color(0xFF222731),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        items: _roles.map((r) {
                          return DropdownMenuItem<String>(
                            value: r['value'],
                            child: Text(r['label']!),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedRole = val;
                              if (val == 'trainer') _specializationController.text = 'Entrenamiento Personal';
                              if (val == 'receptionist' || val == 'cashier') _specializationController.text = 'Atención al Cliente';
                              if (val == 'manager') _specializationController.text = 'Administración General';
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 14),

                      // Salary and Specialization
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _salaryController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Salario Mensual (RD\$) *',
                                labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                                prefixIcon: const Icon(Icons.attach_money, color: Colors.greenAccent, size: 18),
                                filled: true,
                                fillColor: const Color(0xFF222731),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Requerido';
                                final val = double.tryParse(v.trim());
                                if (val == null || val < 0) return 'Monto inválido';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _specializationController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Especialización',
                                labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                                prefixIcon: const Icon(Icons.star_outline, color: Colors.amberAccent, size: 18),
                                filled: true,
                                fillColor: const Color(0xFF222731),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Information Banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Al promover el socio a empleado:\n'
                                '• Se actualizará su cuenta de usuario con permisos de empleado.\n'
                                '• Se le asignará acceso ilimitado en el reloj biométrico ZKAccess.\n'
                                '• Se enviarán automáticamente sus credenciales por Correo y WhatsApp.',
                                style: TextStyle(fontSize: 11.5, color: Colors.white70, height: 1.4),
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

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF15181E),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isLoading ? null : _handleConvert,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                    label: Text(
                      _isLoading ? 'Procesando...' : 'Convertir en Empleado',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(MemberModel member) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF222731),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
            child: Text(
              member.firstName.isNotEmpty ? member.firstName[0].toUpperCase() : 'S',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Cód: ${member.displayCode}',
                        style: const TextStyle(fontSize: 10, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${member.email ?? 'Sin email'} • ${member.phone ?? 'Sin teléfono'}',
                  style: const TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ),
          if (widget.preselectedMember == null)
            IconButton(
              icon: const Icon(Icons.change_circle_outlined, color: Colors.white60, size: 20),
              tooltip: 'Cambiar Socio',
              onPressed: () => setState(() => _selectedMember = null),
            ),
        ],
      ),
    );
  }

  Widget _buildMemberSelector(List<MemberModel> members) {
    return Autocomplete<MemberModel>(
      displayStringForOption: (m) => '${m.fullName} (${m.displayCode})',
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return members.take(10);
        }
        final q = textEditingValue.text.toLowerCase();
        return members.where((m) {
          return m.fullName.toLowerCase().contains(q) ||
              m.displayCode.toLowerCase().contains(q) ||
              (m.email?.toLowerCase().contains(q) ?? false) ||
              (m.phone?.toLowerCase().contains(q) ?? false);
        });
      },
      onSelected: (m) {
        setState(() => _selectedMember = m);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Buscar socio por nombre, código, teléfono...',
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
            filled: true,
            fillColor: const Color(0xFF222731),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            color: const Color(0xFF222731),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 510,
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 12,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                      child: Text(
                        option.firstName.isNotEmpty ? option.firstName[0].toUpperCase() : 'S',
                        style: const TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(option.fullName, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    subtitle: Text('${option.displayCode} • ${option.phone ?? option.email ?? ''}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
