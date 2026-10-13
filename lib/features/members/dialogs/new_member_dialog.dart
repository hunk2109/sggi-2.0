import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/member_model.dart';
import '../providers/members_provider.dart';

class NewMemberDialog extends ConsumerStatefulWidget {
  final MemberModel? memberToEdit;

  const NewMemberDialog({super.key, this.memberToEdit});

  @override
  ConsumerState<NewMemberDialog> createState() => _NewMemberDialogState();
}

class _NewMemberDialogState extends ConsumerState<NewMemberDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _documentIdController;
  late final TextEditingController _addressController;
  late final TextEditingController _emergencyContactController;
  late final TextEditingController _emergencyPhoneController;

  String _gender = 'M';
  bool _isLoading = false;

  bool get _isEditing => widget.memberToEdit != null;

  @override
  void initState() {
    super.initState();
    final m = widget.memberToEdit;
    _firstNameController = TextEditingController(text: m?.firstName ?? '');
    _lastNameController = TextEditingController(text: m?.lastName ?? '');
    _phoneController = TextEditingController(text: m?.phone ?? '');
    _emailController = TextEditingController(text: m?.email ?? '');
    _documentIdController = TextEditingController(text: m?.documentId ?? '');
    _addressController = TextEditingController(text: m?.address ?? '');
    _emergencyContactController = TextEditingController(text: m?.emergencyContact ?? '');
    _emergencyPhoneController = TextEditingController(text: m?.emergencyPhone ?? '');
    _gender = m?.gender ?? 'M';
    if (_gender != 'M' && _gender != 'F') _gender = 'M';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _documentIdController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'documentId': _documentIdController.text.trim(),
      'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      'gender': _gender,
      'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      'emergencyContact': _emergencyContactController.text.trim().isEmpty ? null : _emergencyContactController.text.trim(),
      'emergencyPhone': _emergencyPhoneController.text.trim().isEmpty ? null : _emergencyPhoneController.text.trim(),
    };

    final notifier = ref.read(membersProvider.notifier);
    bool success;

    if (_isEditing) {
      success = await notifier.updateMember(widget.memberToEdit!.id, data);
    } else {
      success = await notifier.createMember(data);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Socio actualizado exitosamente' : 'Socio registrado exitosamente'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Error al actualizar socio' : 'Error al registrar socio. Revisa los datos.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 620,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isEditing ? Icons.edit_note_outlined : Icons.person_add_outlined,
                        color: AppTheme.primary,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isEditing ? 'Editar Datos del Socio' : 'Registrar Nuevo Socio',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Two Column Form: Names
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nombre *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _firstNameController,
                          autofocus: !_isEditing,
                          decoration: const InputDecoration(hintText: 'Ej. Juan'),
                          validator: (v) => v?.trim().isEmpty == true ? 'Requerido' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Apellido *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(hintText: 'Ej. Pérez'),
                          validator: (v) => v?.trim().isEmpty == true ? 'Requerido' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Phone & Document ID
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Teléfono / Móvil *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(hintText: '809-555-0101'),
                          validator: (v) => v?.trim().isEmpty == true ? 'Requerido' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Cédula / Documento', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _documentIdController,
                          decoration: const InputDecoration(hintText: '001-0000000-0'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Email & Gender
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Correo Electrónico', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(hintText: 'socio@gmail.com'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Género', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _gender,
                          items: const [
                            DropdownMenuItem(value: 'M', child: Text('Masculino')),
                            DropdownMenuItem(value: 'F', child: Text('Femenino')),
                          ],
                          onChanged: (v) => setState(() => _gender = v ?? 'M'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Address
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dirección', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(hintText: 'Calle, sector, ciudad'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Emergency Contact Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Contacto de Emergencia', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emergencyContactController,
                          decoration: const InputDecoration(hintText: 'Nombre de familiar / amigo'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Teléfono de Emergencia', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emergencyPhoneController,
                          decoration: const InputDecoration(hintText: '809-555-9999'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_isEditing ? 'Guardar Cambios' : 'Guardar Socio'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
