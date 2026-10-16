import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../employees/models/employee_model.dart';
import '../../employees/providers/employees_provider.dart';

enum ExtractChannelMode { whatsapp, email, both }

class SelectReportRecipientsDialog extends ConsumerStatefulWidget {
  final String currentRecipients;
  final String notificationChannel; // 'whatsapp', 'email', 'both'

  const SelectReportRecipientsDialog({
    super.key,
    required this.currentRecipients,
    required this.notificationChannel,
  });

  static Future<String?> show(
    BuildContext context, {
    required String currentRecipients,
    required String notificationChannel,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => SelectReportRecipientsDialog(
        currentRecipients: currentRecipients,
        notificationChannel: notificationChannel,
      ),
    );
  }

  @override
  ConsumerState<SelectReportRecipientsDialog> createState() => _SelectReportRecipientsDialogState();
}

class _SelectReportRecipientsDialogState extends ConsumerState<SelectReportRecipientsDialog> {
  final _searchController = TextEditingController();
  late ExtractChannelMode _extractMode;
  final Set<String> _selectedEmployeeIds = {};
  String _selectedRoleFilter = 'all';

  @override
  void initState() {
    super.initState();
    // Determinar modo de extracción según el canal configurado
    if (widget.notificationChannel == 'whatsapp') {
      _extractMode = ExtractChannelMode.whatsapp;
    } else if (widget.notificationChannel == 'email') {
      _extractMode = ExtractChannelMode.email;
    } else {
      _extractMode = ExtractChannelMode.both;
    }

    // Cargar empleados si aún no se han cargado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(employeesProvider);
      if (state.employees.isEmpty && !state.isLoading) {
        ref.read(employeesProvider.notifier).loadAllData();
      }
      _preselectExistingEmployees();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _preselectExistingEmployees() {
    final employees = ref.read(employeesProvider).employees;
    if (employees.isEmpty) return;

    final existingTokens = widget.currentRecipients
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();

    if (existingTokens.isEmpty) return;

    setState(() {
      for (final emp in employees) {
        final cleanPhone = emp.phone.replaceAll(RegExp(r'[^0-9]'), '');
        final empEmail = emp.email.trim().toLowerCase();

        final matches = existingTokens.any((token) {
          final cleanToken = token.replaceAll(RegExp(r'[^0-9]'), '');
          return (cleanToken.isNotEmpty && cleanToken.length >= 7 && (cleanPhone.contains(cleanToken) || cleanToken.contains(cleanPhone))) ||
              (empEmail.isNotEmpty && token.contains(empEmail));
        });

        if (matches) {
          _selectedEmployeeIds.add(emp.id);
        }
      }
    });
  }

  void _selectAll(List<EmployeeModel> employees) {
    setState(() {
      for (final e in employees) {
        _selectedEmployeeIds.add(e.id);
      }
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedEmployeeIds.clear();
    });
  }

  void _selectByRole(List<EmployeeModel> employees, List<String> roles) {
    setState(() {
      for (final e in employees) {
        if (roles.contains(e.role.toLowerCase())) {
          _selectedEmployeeIds.add(e.id);
        }
      }
    });
  }

  String _generateResultRecipients(List<EmployeeModel> allEmployees) {
    final selectedEmployees = allEmployees.where((e) => _selectedEmployeeIds.contains(e.id)).toList();

    // Preservar destinatarios manuales que no pertenecían a los empleados existentes
    final existingTokens = widget.currentRecipients
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final preservedTokens = <String>[];
    for (final token in existingTokens) {
      final cleanToken = token.replaceAll(RegExp(r'[^0-9]'), '').toLowerCase();
      final isFromKnownEmp = allEmployees.any((emp) {
        final cleanPhone = emp.phone.replaceAll(RegExp(r'[^0-9]'), '').toLowerCase();
        final empEmail = emp.email.trim().toLowerCase();
        return (cleanToken.isNotEmpty && cleanToken.length >= 7 && (cleanPhone.contains(cleanToken) || cleanToken.contains(cleanPhone))) ||
            (empEmail.isNotEmpty && token.toLowerCase().contains(empEmail));
      });

      if (!isFromKnownEmp) {
        preservedTokens.add(token);
      }
    }

    final newTokens = <String>{};

    for (final emp in selectedEmployees) {
      final cleanPhone = emp.phone.trim();
      final cleanEmail = emp.email.trim();

      if (_extractMode == ExtractChannelMode.whatsapp || _extractMode == ExtractChannelMode.both) {
        if (cleanPhone.isNotEmpty) {
          newTokens.add(cleanPhone);
        }
      }

      if (_extractMode == ExtractChannelMode.email || _extractMode == ExtractChannelMode.both) {
        if (cleanEmail.isNotEmpty) {
          newTokens.add(cleanEmail);
        }
      }
    }

    final allResults = [...preservedTokens, ...newTokens];
    // Eliminar duplicados exactos preservando orden
    final seen = <String>{};
    final unique = allResults.where((item) => seen.add(item.toLowerCase())).toList();

    return unique.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(employeesProvider);
    final allEmployees = state.employees.where((e) => e.isActive).toList();

    // Filtros
    final query = _searchController.text.trim().toLowerCase();
    final filtered = allEmployees.where((e) {
      if (_selectedRoleFilter != 'all') {
        if (_selectedRoleFilter == 'manager' && e.role.toLowerCase() != 'manager' && e.role.toLowerCase() != 'supervisor') {
          return false;
        } else if (_selectedRoleFilter == 'cashier' && e.role.toLowerCase() != 'cashier' && e.role.toLowerCase() != 'receptionist') {
          return false;
        } else if (_selectedRoleFilter == 'trainer' && e.role.toLowerCase() != 'trainer') {
          return false;
        }
      }

      if (query.isNotEmpty) {
        final nameMatch = e.fullName.toLowerCase().contains(query);
        final emailMatch = e.email.toLowerCase().contains(query);
        final phoneMatch = e.phone.contains(query);
        final roleMatch = e.roleLabel.toLowerCase().contains(query);
        return nameMatch || emailMatch || phoneMatch || roleMatch;
      }

      return true;
    }).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 720,
        constraints: const BoxConstraints(maxHeight: 740),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2028),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.darkBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ================= HEADER =================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF15181E),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.groups_outlined, color: AppTheme.primaryLight, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Extraer Destinatarios de Empleados',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Selecciona el personal que recibirá los cierres de caja y resúmenes automáticos',
                          style: TextStyle(fontSize: 12, color: Colors.white54),
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

            // ================= CONFIGURACIÓN DE EXTRACCIÓN =================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              color: const Color(0xFF1E232B),
              child: Row(
                children: [
                  const Text(
                    'Datos a extraer:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                  const SizedBox(width: 12),
                  _buildExtractModeChip('WhatsApp (Teléfono)', ExtractChannelMode.whatsapp, Icons.chat_bubble_outline),
                  const SizedBox(width: 8),
                  _buildExtractModeChip('Correo Electrónico', ExtractChannelMode.email, Icons.mail_outline),
                  const SizedBox(width: 8),
                  _buildExtractModeChip('Ambos', ExtractChannelMode.both, Icons.all_inclusive),
                ],
              ),
            ),

            // ================= SEARCH & QUICK FILTERS =================
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  // Search
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Buscar empleado por nombre, cargo, teléfono o correo...',
                        hintStyle: const TextStyle(fontSize: 13, color: Colors.white38),
                        prefixIcon: const Icon(Icons.search, size: 18, color: Colors.white54),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFF15181E),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.darkBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.darkBorder),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Quick Action Menu
                  PopupMenuButton<String>(
                    tooltip: 'Acciones rápidas de selección',
                    color: const Color(0xFF1E232B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'all',
                        child: Row(
                          children: [
                            Icon(Icons.select_all, size: 18, color: Colors.white70),
                            SizedBox(width: 8),
                            Text('Seleccionar Todos'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'managers',
                        child: Row(
                          children: [
                            Icon(Icons.admin_panel_settings_outlined, size: 18, color: Colors.amberAccent),
                            SizedBox(width: 8),
                            Text('Solo Encargados / Gerentes'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'cashiers',
                        child: Row(
                          children: [
                            Icon(Icons.point_of_sale, size: 18, color: Colors.blueAccent),
                            SizedBox(width: 8),
                            Text('Solo Cajeros / Recepción'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'clear',
                        child: Row(
                          children: [
                            Icon(Icons.deselect, size: 18, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text('Desmarcar Todos', style: TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (val) {
                      if (val == 'all') _selectAll(allEmployees);
                      if (val == 'managers') _selectByRole(allEmployees, ['manager', 'supervisor']);
                      if (val == 'cashiers') _selectByRole(allEmployees, ['cashier', 'receptionist']);
                      if (val == 'clear') _deselectAll();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15181E),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.darkBorder),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.tune, size: 16, color: AppTheme.primaryLight),
                          SizedBox(width: 6),
                          Text('Selección Rápida', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down, size: 18, color: Colors.white54),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Role Category Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildRoleFilterChip('Todos (${allEmployees.length})', 'all'),
                    const SizedBox(width: 8),
                    _buildRoleFilterChip('Gerentes / Encargados', 'manager'),
                    const SizedBox(width: 8),
                    _buildRoleFilterChip('Cajeros / Recepción', 'cashier'),
                    const SizedBox(width: 8),
                    _buildRoleFilterChip('Entrenadores', 'trainer'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // ================= EMPLOYEE LIST =================
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_off_outlined, size: 48, color: Colors.white.withValues(alpha: 0.2)),
                              const SizedBox(height: 12),
                              const Text('No se encontraron empleados activos', style: TextStyle(color: Colors.white54, fontSize: 14)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final emp = filtered[index];
                            final isSelected = _selectedEmployeeIds.contains(emp.id);
                            return _buildEmployeeRow(emp, isSelected);
                          },
                        ),
            ),

            // ================= FOOTER =================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF15181E),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _selectedEmployeeIds.isNotEmpty
                          ? AppTheme.primary.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_selectedEmployeeIds.length} de ${allEmployees.length} seleccionados',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _selectedEmployeeIds.isNotEmpty ? AppTheme.primaryLight : Colors.white54,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aplicar Destinatarios'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      final result = _generateResultRecipients(allEmployees);
                      Navigator.of(context).pop(result);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtractModeChip(String label, ExtractChannelMode mode, IconData icon) {
    final isSelected = _extractMode == mode;
    return InkWell(
      onTap: () => setState(() => _extractMode = mode),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : const Color(0xFF15181E),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.darkBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.white54),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleFilterChip(String label, String roleKey) {
    final isSelected = _selectedRoleFilter == roleKey;
    return InkWell(
      onTap: () => setState(() => _selectedRoleFilter = roleKey),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.white38 : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.white54,
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeRow(EmployeeModel emp, bool isSelected) {
    final hasPhone = emp.phone.trim().isNotEmpty;
    final hasEmail = emp.email.trim().isNotEmpty;

    Color roleColor = Colors.white54;
    final r = emp.role.toLowerCase();
    if (r == 'manager' || r == 'supervisor') {
      roleColor = Colors.amberAccent;
    } else if (r == 'cashier' || r == 'receptionist') {
      roleColor = Colors.blueAccent;
    } else if (r == 'trainer') {
      roleColor = Colors.greenAccent;
    }

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedEmployeeIds.remove(emp.id);
          } else {
            _selectedEmployeeIds.add(emp.id);
          }
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.08) : const Color(0xFF1E232B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primary.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.04),
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              activeColor: AppTheme.primary,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selectedEmployeeIds.add(emp.id);
                  } else {
                    _selectedEmployeeIds.remove(emp.id);
                  }
                });
              },
            ),
            const SizedBox(width: 6),
            CircleAvatar(
              radius: 18,
              backgroundColor: isSelected ? AppTheme.primary : const Color(0xFF2B3240),
              child: Text(
                emp.firstName.isNotEmpty ? emp.firstName[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emp.fullName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      emp.roleLabel,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: roleColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Phone
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 13,
                    color: hasPhone ? Colors.greenAccent : Colors.white24,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      hasPhone ? emp.phone : 'Sin teléfono',
                      style: TextStyle(
                        fontSize: 11,
                        color: hasPhone ? Colors.white70 : Colors.white30,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Email
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Icon(
                    Icons.mail_outline,
                    size: 13,
                    color: hasEmail ? Colors.blueAccent : Colors.white24,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      hasEmail ? emp.email : 'Sin correo',
                      style: TextStyle(
                        fontSize: 11,
                        color: hasEmail ? Colors.white70 : Colors.white30,
                      ),
                      overflow: TextOverflow.ellipsis,
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
}
