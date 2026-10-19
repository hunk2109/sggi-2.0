import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../dialogs/assign_user_role_dialog.dart';
import '../models/permission_model.dart';
import '../providers/role_permissions_provider.dart';

class RolesPermissionsTab extends ConsumerStatefulWidget {
  const RolesPermissionsTab({super.key});

  @override
  ConsumerState<RolesPermissionsTab> createState() => _RolesPermissionsTabState();
}

class _RolesPermissionsTabState extends ConsumerState<RolesPermissionsTab> {
  final _searchCtrl = TextEditingController();

  final List<({String key, String title, String subtitle, IconData icon, Color color})> _roles = const [
    (
      key: 'admin',
      title: 'Administrador',
      subtitle: 'Acceso total y configuración del gimnasio',
      icon: Icons.admin_panel_settings_outlined,
      color: Colors.amber,
    ),
    (
      key: 'encargado',
      title: 'Encargado / Supervisor',
      subtitle: 'Supervisión de operaciones, ventas y turnos',
      icon: Icons.supervisor_account_outlined,
      color: Colors.blueAccent,
    ),
    (
      key: 'empleado_cajero',
      title: 'Cajero / Recepción',
      subtitle: 'Ventas en mostrador, cobros y arqueos',
      icon: Icons.point_of_sale_outlined,
      color: Colors.greenAccent,
    ),
    (
      key: 'empleado_entrenador',
      title: 'Entrenador / Staff',
      subtitle: 'Acceso a socios, torniquete y clases',
      icon: Icons.fitness_center_outlined,
      color: Colors.purpleAccent,
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmRemoveRole(
    BuildContext context,
    UserModel user,
    ({String key, String title, String subtitle, IconData icon, Color color}) roleData,
    RolePermissionsNotifier notifier,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E232B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('Revocar Rol', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas revocar el rol de "${roleData.title}" a ${user.fullName}?\n\nEl usuario volverá a tener el rol básico de Socio / Cliente.',
          style: const TextStyle(fontSize: 13, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Revocar Rol', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      notifier.removeUserRole(user.id, roleData.key);
    }
  }

  IconData _getModuleIcon(String module) {
    switch (module.toLowerCase()) {
      case 'punto de venta':
        return Icons.point_of_sale;
      case 'caja & arqueo':
        return Icons.account_balance_wallet;
      case 'socios & membresías':
        return Icons.people_alt;
      case 'inventario & productos':
        return Icons.inventory_2;
      case 'nómina & empleados':
        return Icons.badge;
      case 'control de acceso':
        return Icons.door_sliding;
      case 'envíos masivos':
        return Icons.campaign;
      case 'reportes & métricas':
        return Icons.bar_chart;
      case 'configuración':
        return Icons.settings;
      default:
        return Icons.security;
    }
  }

  Widget _buildRoleUsersSection(
    BuildContext context,
    ({String key, String title, String subtitle, IconData icon, Color color}) selectedRoleData,
    RolePermissionsState state,
    RolePermissionsNotifier notifier,
  ) {
    final isAdmin = state.selectedRole == 'admin';
    final users = state.roleUsers[state.selectedRole] ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2028),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAdmin ? Colors.amber.withValues(alpha: 0.3) : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selectedRoleData.color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(selectedRoleData.icon, size: 20, color: selectedRoleData.color),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isAdmin
                                ? 'Usuarios Administradores del Sistema'
                                : 'Usuarios con Rol: ${selectedRoleData.title}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: selectedRoleData.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${users.length} ${users.length == 1 ? "usuario" : "usuarios"}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: selectedRoleData.color),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAdmin
                            ? 'Los Administradores tienen acceso total al sistema y NO figuran como empleados en nómina.'
                            : 'Usuarios activos asignados a este perfil de trabajo.',
                        style: const TextStyle(fontSize: 11, color: Colors.white54),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add_alt_1, size: 16),
                label: Text(
                  isAdmin ? '+ Seleccionar Usuario Admin' : '+ Asignar a este Rol',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAdmin ? Colors.amber : AppTheme.primary,
                  foregroundColor: isAdmin ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: () async {
                  final changed = await AssignUserRoleDialog.show(
                    context,
                    roleKey: state.selectedRole,
                    roleTitle: selectedRoleData.title,
                  );
                  if (changed == true) {
                    notifier.loadUsersForRole(state.selectedRole);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 14),
          if (state.isLoadingUsers)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (users.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF16191E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  const Icon(Icons.person_off_outlined, color: Colors.white30, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    isAdmin
                        ? 'No hay usuarios asignados como Administrador adicionales.'
                        : 'No hay usuarios asignados a este rol.',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAdmin
                        ? 'Presiona "+ Seleccionar Usuario Admin" para otorgar permisos a otro usuario.'
                        : 'Presiona "+ Asignar a este Rol" para vincular usuarios a este perfil.',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: users.map((u) {
                return Container(
                  width: 270,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16191E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: selectedRoleData.color.withValues(alpha: 0.2),
                        child: Text(
                          u.firstName.isNotEmpty ? u.firstName[0].toUpperCase() : 'U',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: selectedRoleData.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u.fullName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              u.email,
                              style: const TextStyle(fontSize: 11, color: Colors.white54),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.redAccent),
                        tooltip: 'Revocar este rol',
                        onPressed: () => _confirmRemoveRole(context, u, selectedRoleData, notifier),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rolePermissionsProvider);
    final notifier = ref.read(rolePermissionsProvider.notifier);

    if (state.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final selectedRoleData = _roles.firstWhere(
      (r) => r.key == state.selectedRole,
      orElse: () => _roles[0],
    );

    final permissions = state.getFilteredPermissions();

    // Group permissions by module
    final Map<String, List<PermissionDefinitionModel>> grouped = {};
    for (final p in permissions) {
      grouped.putIfAbsent(p.module, () => []).add(p);
    }

    final roleActiveCount = state.catalog
        .where((p) => state.isActionEnabled(state.selectedRole, p.id))
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner feedback if any
          if (state.successMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.successMessage!,
                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (state.error != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ================= 1. SELECTOR DE ROL =================
          const Text(
            'Seleccione el Rol que desea configurar:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(height: 10),

          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 12,
                runSpacing: 10,
                children: _roles.map((r) {
                  final isSelected = state.selectedRole == r.key;
                  final activeInRole = state.catalog
                      .where((p) => state.isActionEnabled(r.key, p.id))
                      .length;

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => notifier.setSelectedRole(r.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 250,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? r.color.withValues(alpha: 0.12)
                            : const Color(0xFF1E232B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? r.color : Colors.white12,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: r.color.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(r.icon, size: 18, color: r.color),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  r.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            r.subtitle,
                            style: const TextStyle(fontSize: 11, color: Colors.white38, height: 1.3),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected ? r.color.withValues(alpha: 0.25) : Colors.black26,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$activeInRole de ${state.catalog.length} permisos',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? r.color : Colors.white54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 20),

          // ================= USUARIOS CON ESTE ROL =================
          _buildRoleUsersSection(context, selectedRoleData, state, notifier),

          const SizedBox(height: 24),

          // ================= 2. BARRA DE HERRAMIENTAS Y ACCIONES RÁPIDAS =================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2028),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 14,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(selectedRoleData.icon, color: selectedRoleData.color, size: 24),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Permisos asignados a: ${selectedRoleData.title}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          '$roleActiveCount de ${state.catalog.length} acciones habilitadas para este rol',
                          style: TextStyle(fontSize: 12, color: selectedRoleData.color, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Search bar
                    SizedBox(
                      width: 200,
                      height: 38,
                      child: TextField(
                        controller: _searchCtrl,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Filtrar acción...',
                          hintStyle: const TextStyle(fontSize: 12, color: Colors.white38),
                          prefixIcon: const Icon(Icons.search, size: 16),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                        ),
                        onChanged: (val) => notifier.setSearchQuery(val),
                      ),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.done_all, size: 16),
                      label: const Text('Marcar Todos', style: TextStyle(fontSize: 12)),
                      onPressed: () => notifier.setAllForRole(state.selectedRole, true),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.remove_done, size: 16),
                      label: const Text('Desmarcar Todos', style: TextStyle(fontSize: 12)),
                      onPressed: () => notifier.setAllForRole(state.selectedRole, false),
                    ),
                    ElevatedButton.icon(
                      icon: state.isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save, size: 16),
                      label: Text(
                        state.isSaving ? 'Guardando...' : 'Guardar Permisos',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: state.isSaving ? null : () => notifier.saveRolePermissions(state.selectedRole),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ================= 3. LISTADO DE MÓDULOS Y PERMISOS =================
          if (state.selectedRole == 'admin') ...[
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.amber, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'El rol Administrador cuenta con acceso total e ilimitado a todas las funciones del sistema. Todas las acciones se encuentran activas por defecto.',
                      style: TextStyle(fontSize: 12, color: Colors.amberAccent, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (grouped.isEmpty) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text('No se encontraron acciones con ese filtro', style: TextStyle(color: Colors.white54)),
              ),
            ),
          ] else ...[
            ...grouped.entries.map((entry) {
              final moduleName = entry.key;
              final modulePerms = entry.value;

              final totalInModule = modulePerms.length;
              final enabledInModule = modulePerms
                  .where((p) => state.isActionEnabled(state.selectedRole, p.id))
                  .length;
              final isAllModuleActive = totalInModule > 0 && enabledInModule == totalInModule;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B2028),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Module Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF16191E),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(_getModuleIcon(moduleName), color: AppTheme.primary, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                moduleName,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: enabledInModule > 0
                                      ? AppTheme.primary.withValues(alpha: 0.15)
                                      : Colors.white10,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$enabledInModule de $totalInModule habilitadas',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: enabledInModule > 0 ? AppTheme.primary : Colors.white38,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            icon: Icon(
                              isAllModuleActive ? Icons.check_box : Icons.check_box_outline_blank,
                              size: 16,
                              color: isAllModuleActive ? AppTheme.primary : Colors.white54,
                            ),
                            label: Text(
                              isAllModuleActive ? 'Desmarcar Módulo' : 'Activar Todo el Módulo',
                              style: TextStyle(
                                fontSize: 11,
                                color: isAllModuleActive ? AppTheme.primary : Colors.white70,
                              ),
                            ),
                            onPressed: () => notifier.toggleAllInModule(
                              state.selectedRole,
                              moduleName,
                              !isAllModuleActive,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Actions list
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: modulePerms.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, color: Colors.white10),
                      itemBuilder: (context, index) {
                        final perm = modulePerms[index];
                        final isEnabled = state.isActionEnabled(state.selectedRole, perm.id);

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => notifier.togglePermission(
                              state.selectedRole,
                              perm.id,
                              !isEnabled,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Switch(
                                    value: isEnabled,
                                    activeThumbColor: AppTheme.primary,
                                    onChanged: (val) => notifier.togglePermission(
                                      state.selectedRole,
                                      perm.id,
                                      val,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          perm.name,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isEnabled ? Colors.white : Colors.white60,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          perm.description,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isEnabled ? Colors.white54 : Colors.white30,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      perm.id,
                                      style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.white30),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
