import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/group_model.dart';
import '../services/group_service.dart';

final groupServiceProvider = Provider<GroupService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return GroupService(apiClient);
});

/// Provider para obtener los grupos de un socio por su memberId
final memberGroupsProvider = FutureProvider.family<List<GroupModel>, String>((ref, memberId) async {
  final service = ref.watch(groupServiceProvider);
  return service.getMemberGroups(memberId);
});

/// Provider para obtener el detalle de un grupo específico
final groupDetailsProvider = FutureProvider.family<GroupModel?, String>((ref, groupId) async {
  final service = ref.watch(groupServiceProvider);
  return service.getGroupById(groupId);
});
