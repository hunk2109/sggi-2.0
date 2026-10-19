import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/permission_model.dart';
import '../services/role_permissions_service.dart';

final rolePermissionsServiceProvider = Provider<RolePermissionsService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RolePermissionsService(apiClient);
});

class RolePermissionsState {
  final bool isLoading;
  final bool isSaving;
  final bool isLoadingUsers;
  final String selectedRole;
  final List<PermissionDefinitionModel> catalog;
  final Map<String, Set<String>> rolePermissions;
  final Set<String> myPermissions;
  final Map<String, List<UserModel>> roleUsers;
  final String searchQuery;
  final String? error;
  final String? successMessage;

  const RolePermissionsState({
    this.isLoading = false,
    this.isSaving = false,
    this.isLoadingUsers = false,
    this.selectedRole = 'admin',
    this.catalog = const [],
    this.rolePermissions = const {},
    this.myPermissions = const {},
    this.roleUsers = const {},
    this.searchQuery = '',
    this.error,
    this.successMessage,
  });

  bool hasPermission(String permId, {bool isAdmin = false}) {
    if (isAdmin) return true;
    return myPermissions.contains(permId);
  }

  bool isActionEnabled(String role, String permId) {
    return rolePermissions[role]?.contains(permId) ?? false;
  }

  List<String> get modules {
    final Set<String> mods = {};
    for (final p in catalog) {
      mods.add(p.module);
    }
    return mods.toList();
  }

  List<PermissionDefinitionModel> getFilteredPermissions() {
    if (searchQuery.trim().isEmpty) return catalog;
    final q = searchQuery.toLowerCase().trim();
    return catalog.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.module.toLowerCase().contains(q) ||
          p.id.toLowerCase().contains(q);
    }).toList();
  }

  RolePermissionsState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isLoadingUsers,
    String? selectedRole,
    List<PermissionDefinitionModel>? catalog,
    Map<String, Set<String>>? rolePermissions,
    Set<String>? myPermissions,
    Map<String, List<UserModel>>? roleUsers,
    String? searchQuery,
    String? error,
    String? successMessage,
  }) {
    return RolePermissionsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isLoadingUsers: isLoadingUsers ?? this.isLoadingUsers,
      selectedRole: selectedRole ?? this.selectedRole,
      catalog: catalog ?? this.catalog,
      rolePermissions: rolePermissions ?? this.rolePermissions,
      myPermissions: myPermissions ?? this.myPermissions,
      roleUsers: roleUsers ?? this.roleUsers,
      searchQuery: searchQuery ?? this.searchQuery,
      error: error,
      successMessage: successMessage,
    );
  }
}

class RolePermissionsNotifier extends Notifier<RolePermissionsState> {
  @override
  RolePermissionsState build() {
    Future.microtask(() => loadInitialData());
    return const RolePermissionsState(isLoading: true);
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, error: null);
    final service = ref.read(rolePermissionsServiceProvider);

    try {
      final futures = await Future.wait([
        service.getCatalog(),
        service.getAllRolePermissions(),
        service.getMyPermissions(),
      ]);

      final catalog = futures[0] as List<PermissionDefinitionModel>;
      final allPermsRaw = futures[1] as Map<String, List<String>>;
      final myPermsRaw = futures[2] as List<String>;

      final Map<String, Set<String>> permMap = {};
      allPermsRaw.forEach((role, list) {
        permMap[role] = Set<String>.from(list);
      });

      state = state.copyWith(
        isLoading: false,
        catalog: catalog,
        rolePermissions: permMap,
        myPermissions: Set<String>.from(myPermsRaw),
      );

      // Cargar los usuarios del rol inicialmente seleccionado
      await loadUsersForRole(state.selectedRole);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadUsersForRole(String role) async {
    state = state.copyWith(isLoadingUsers: true);
    final service = ref.read(rolePermissionsServiceProvider);
    try {
      final users = await service.getUsersByRole(role);
      final updatedMap = Map<String, List<UserModel>>.from(state.roleUsers);
      updatedMap[role] = users;
      state = state.copyWith(isLoadingUsers: false, roleUsers: updatedMap);
    } catch (_) {
      state = state.copyWith(isLoadingUsers: false);
    }
  }

  void setSelectedRole(String role) {
    state = state.copyWith(selectedRole: role, error: null, successMessage: null);
    loadUsersForRole(role);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void togglePermission(String role, String permId, bool value) {
    final currentMap = Map<String, Set<String>>.from(state.rolePermissions);
    final roleSet = Set<String>.from(currentMap[role] ?? {});

    if (value) {
      roleSet.add(permId);
    } else {
      roleSet.remove(permId);
    }

    currentMap[role] = roleSet;
    state = state.copyWith(rolePermissions: currentMap, successMessage: null);
  }

  void toggleAllInModule(String role, String moduleName, bool value) {
    final currentMap = Map<String, Set<String>>.from(state.rolePermissions);
    final roleSet = Set<String>.from(currentMap[role] ?? {});
    final modulePerms = state.catalog.where((p) => p.module == moduleName).map((p) => p.id);

    if (value) {
      roleSet.addAll(modulePerms);
    } else {
      roleSet.removeAll(modulePerms);
    }

    currentMap[role] = roleSet;
    state = state.copyWith(rolePermissions: currentMap, successMessage: null);
  }

  void setAllForRole(String role, bool value) {
    final currentMap = Map<String, Set<String>>.from(state.rolePermissions);
    final roleSet = Set<String>.from(currentMap[role] ?? {});

    if (value) {
      roleSet.addAll(state.catalog.map((p) => p.id));
    } else {
      roleSet.clear();
    }

    currentMap[role] = roleSet;
    state = state.copyWith(rolePermissions: currentMap, successMessage: null);
  }

  Future<bool> saveRolePermissions(String role) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    final service = ref.read(rolePermissionsServiceProvider);

    try {
      final permissionsToSave = (state.rolePermissions[role] ?? {}).toList();
      await service.updateRolePermissions(role, permissionsToSave);

      final myPerms = await service.getMyPermissions();

      // Sincronizar permisos en authProvider inmediatamente
      await ref.read(authProvider.notifier).fetchPermissions();

      state = state.copyWith(
        isSaving: false,
        myPermissions: Set<String>.from(myPerms),
        successMessage: 'Permisos del rol actualizados correctamente.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> assignUserRole(String userId, String role) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    final service = ref.read(rolePermissionsServiceProvider);

    try {
      await service.assignRole(userId, role);
      await loadUsersForRole(role);
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Rol "$role" asignado con éxito al usuario.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> removeUserRole(String userId, String currentRole) async {
    state = state.copyWith(isSaving: true, error: null, successMessage: null);
    final service = ref.read(rolePermissionsServiceProvider);

    try {
      await service.assignRole(userId, 'cliente');
      await loadUsersForRole(currentRole);
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Rol revocado. El usuario ahora es Socio/Cliente.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}

final rolePermissionsProvider =
    NotifierProvider<RolePermissionsNotifier, RolePermissionsState>(() {
  return RolePermissionsNotifier();
});
