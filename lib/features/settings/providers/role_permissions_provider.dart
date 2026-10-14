import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final String selectedRole;
  final List<PermissionDefinitionModel> catalog;
  final Map<String, Set<String>> rolePermissions;
  final Set<String> myPermissions;
  final String searchQuery;
  final String? error;
  final String? successMessage;

  const RolePermissionsState({
    this.isLoading = false,
    this.isSaving = false,
    this.selectedRole = 'empleado_cajero',
    this.catalog = const [],
    this.rolePermissions = const {},
    this.myPermissions = const {},
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
    String? selectedRole,
    List<PermissionDefinitionModel>? catalog,
    Map<String, Set<String>>? rolePermissions,
    Set<String>? myPermissions,
    String? searchQuery,
    String? error,
    String? successMessage,
  }) {
    return RolePermissionsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      selectedRole: selectedRole ?? this.selectedRole,
      catalog: catalog ?? this.catalog,
      rolePermissions: rolePermissions ?? this.rolePermissions,
      myPermissions: myPermissions ?? this.myPermissions,
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
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSelectedRole(String role) {
    state = state.copyWith(selectedRole: role, error: null, successMessage: null);
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

      // Refresh my permissions in case the current user has that role
      final myPerms = await service.getMyPermissions();

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
}

final rolePermissionsProvider =
    NotifierProvider<RolePermissionsNotifier, RolePermissionsState>(() {
  return RolePermissionsNotifier();
});
