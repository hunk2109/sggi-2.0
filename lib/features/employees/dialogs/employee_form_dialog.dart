import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../models/employee_model.dart';
import '../providers/employees_provider.dart';

class EmployeeFormDialog extends ConsumerStatefulWidget {
  final EmployeeModel? employeeToEdit;

  const EmployeeFormDialog({super.key, this.employeeToEdit});

  @override
  ConsumerState<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends ConsumerState<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _salaryController;
  late final TextEditingController _specializationController;
  late final TextEditingController _bankController;
  late final TextEditingController _accountController;

  String _role = 'trainer';
  bool _isLoading = false;
  bool get _isEditing => widget.employeeToEdit != null;

  @override
  void initState() {
    super.initState();
    final e = widget.employeeToEdit;
    _firstNameController = TextEditingController(text: e?.firstName ?? '');
    _lastNameController = TextEditingController(text: e?.lastName ?? '');
    _phoneController = TextEditingController(text: e?.phone ?? '');
    _emailController = TextEditingController(text: e?.email ?? '');
    _salaryController = TextEditingController(text: e != null ? e.salary.toStringAsFixed(2) : '25000.00');
    _specializationController = TextEditingController(text: e?.specialization ?? '');
    _bankController = TextEditingController(text: e?.bank ?? 'Banco Popular');
    _accountController = TextEditingController(text: e?.accountNumber ?? '');
    _role = e?.role ?? 'trainer';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _salaryController.dispose();
    _specializationController.dispose();
    _bankController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'role': _role,
      'salary': double.tryParse(_salaryController.text.trim()) ?? 0.0,
      'hireDate': DateTime.now().toIso8601String().split('T')[0],
      if (_specializationController.text.trim().isNotEmpty) 'specialization': _specializationController.text.trim(),
      if (_bankController.text.trim().isNotEmpty) 'bank': _bankController.text.trim(),
      if (_accountController.text.trim().isNotEmpty) 'accountNumber': _accountController.text.trim(),
    };

    final notifier = ref.read(employeesProvider.notifier);
    bool success;

    if (_isEditing) {
      success = await notifier.updateEmployee(widget.employeeToEdit!.id, data);
    } else {
      success = await notifier.createEmployee(data);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Empleado actualizado' : 'Empleado registrado exitosamente'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar datos del empleado'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E232B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(26),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isEditing ? Icons.badge_outlined : Icons.person_add_alt_1_outlined,
                        color: AppTheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isEditing ? 'Editar Datos de Empleado' : 'Registrar Nuevo Empleado',
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

              // Names
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
                          decoration: const InputDecoration(hintText: 'Ej. Carlos'),
                          validator: (v) => v?.trim().isEmpty == true ? 'Requerido' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Apellido *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(hintText: 'Ej. Gómez'),
                          validator: (v) => v?.trim().isEmpty == true ? 'Requerido' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Phone & Email
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Teléfono *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(hintText: '809-555-0199'),
                          validator: (v) => v?.trim().isEmpty == true ? 'Requerido' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Correo Electrónico *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(hintText: 'empleado@gimnasio.com'),
                          validator: (v) => v?.trim().isEmpty == true ? 'Requerido' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Role & Salary
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Puesto / Rol *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _role,
                          items: const [
                            DropdownMenuItem(value: 'trainer', child: Text('Entrenador')),
                            DropdownMenuItem(value: 'receptionist', child: Text('Recepcionista')),
                            DropdownMenuItem(value: 'cashier', child: Text('Cajero')),
                            DropdownMenuItem(value: 'manager', child: Text('Encargado / Gerente')),
                            DropdownMenuItem(value: 'cleaner', child: Text('Mantenimiento')),
                            DropdownMenuItem(value: 'nutritionist', child: Text('Nutricionista')),
                          ],
                          onChanged: (v) => setState(() => _role = v ?? 'trainer'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Salario Mensual (RD\$) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _salaryController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: '25000.00'),
                          validator: (v) => v?.trim().isEmpty == true ? 'Requerido' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Specialization & Bank
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Especialización / Área', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _specializationController,
                          decoration: const InputDecoration(hintText: 'Pesas, Clases Grupales, etc.'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Banco de Nómina', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _bankController,
                          decoration: const InputDecoration(hintText: 'Banco Popular, BHD...'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isEditing ? 'Guardar Cambios' : 'Registrar Empleado'),
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
