import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/role_permissions_provider.dart';

class AssignUserRoleDialog extends ConsumerStatefulWidget {
  final String roleKey;
  final String roleTitle;

  const AssignUserRoleDialog({
    super.key,
    required this.roleKey,
    required this.roleTitle,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String roleKey,
    required String roleTitle,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AssignUserRoleDialog(
        roleKey: roleKey,
        roleTitle: roleTitle,
      ),
    );
  }

  @override
  ConsumerState<AssignUserRoleDialog> createState() => _AssignUserRoleDialogState();
}

class _AssignUserRoleDialogState extends ConsumerState<AssignUserRoleDialog> {
  final _searchCtrl = TextEditingController();
  Timer? _debounceTimer;
  bool _isLoading = false;
  List<UserModel> _users = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchUsers([String? query]) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = ref.read(rolePermissionsServiceProvider);
      final list = await service.searchUsers(search: query, limit: 40);
      if (mounted) {
        setState(() {
          _users = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _fetchUsers(val);
    });
  }

  Future<void> _confirmAndAssign(UserModel user) async {
    final isAdminRole = widget.roleKey == 'admin';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E232B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Icon(
              isAdminRole ? Icons.admin_panel_settings : Icons.assignment_ind,
              color: isAdminRole ? Colors.amber : AppTheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Asignar ${widget.roleTitle}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Deseas otorgar el rol "${widget.roleTitle}" a ${user.fullName}?',
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Correo: ${user.email}', style: const TextStyle(fontSize: 12, color: Colors.white60)),
                  if (user.phone != null && user.phone!.isNotEmpty)
                    Text('Teléfono: ${user.phone}', style: const TextStyle(fontSize: 12, color: Colors.white60)),
                  Text('Rol actual: ${user.role.label}', style: const TextStyle(fontSize: 12, color: Colors.white60)),
                ],
              ),
            ),
            if (isAdminRole) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'El usuario tendrá acceso total y no figurará como empleado en nómina.',
                        style: TextStyle(fontSize: 11, color: Colors.amberAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isAdminRole ? Colors.amber : AppTheme.primary,
              foregroundColor: isAdminRole ? Colors.black : Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar Asignación', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(rolePermissionsProvider.notifier).assignUserRole(
        user.id,
        widget.roleKey,
      );

      if (mounted && success) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdminRole = widget.roleKey == 'admin';

    return Dialog(
      backgroundColor: const Color(0xFF1B2028),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 620,
          maxHeight: 680,
        ),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF16191E),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isAdminRole ? Colors.amber : AppTheme.primary).withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isAdminRole ? Icons.admin_panel_settings : Icons.person_add_alt_1,
                      color: isAdminRole ? Colors.amber : AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAdminRole ? 'Seleccionar Usuario Administrador' : 'Asignar a: ${widget.roleTitle}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          isAdminRole
                              ? 'Busca y selecciona el usuario que tendrá privilegios de Administrador'
                              : 'Busca y asigna este rol a un usuario o socio del sistema',
                          style: const TextStyle(fontSize: 11, color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, apellido, correo o teléfono...',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, size: 18, color: Colors.white60),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            _fetchUsers();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF16191E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: _onSearchChanged,
              ),
            ),

            const Divider(height: 1, color: Colors.white10),

            // User List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                          ),
                        )
                      : _users.isEmpty
                          ? const Center(
                              child: Text(
                                'No se encontraron usuarios que coincidan con la búsqueda',
                                style: TextStyle(color: Colors.white38, fontSize: 13),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              itemCount: _users.length,
                              separatorBuilder: (_, _) => const Divider(height: 1, color: Colors.white10),
                              itemBuilder: (context, index) {
                                final user = _users[index];
                                final hasThisRole = user.role.name.toLowerCase() == widget.roleKey.toLowerCase();

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: hasThisRole ? null : () => _confirmAndAssign(user),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: (isAdminRole ? Colors.amber : AppTheme.primary)
                                                .withValues(alpha: 0.2),
                                            child: Text(
                                              user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: isAdminRole ? Colors.amber : AppTheme.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  user.fullName,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Text(
                                                      user.email,
                                                      style: const TextStyle(fontSize: 11, color: Colors.white54),
                                                    ),
                                                    if (user.phone != null && user.phone!.isNotEmpty) ...[
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        '• ${user.phone}',
                                                        style: const TextStyle(fontSize: 11, color: Colors.white38),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (hasThisRole)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.check, size: 12, color: Colors.greenAccent),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Ya asignado',
                                                    style: TextStyle(fontSize: 11, color: Colors.greenAccent, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            )
                                          else
                                            OutlinedButton.icon(
                                              icon: const Icon(Icons.add, size: 14),
                                              label: Text(
                                                isAdminRole ? 'Hacer Admin' : 'Asignar',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: isAdminRole ? Colors.amber : AppTheme.primary,
                                                side: BorderSide(color: isAdminRole ? Colors.amber : AppTheme.primary),
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              ),
                                              onPressed: () => _confirmAndAssign(user),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
