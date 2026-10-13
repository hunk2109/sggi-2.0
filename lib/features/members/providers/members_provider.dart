import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/member_model.dart';
import '../services/member_service.dart';
import '../../memberships/models/membership_model.dart';
import '../../memberships/services/membership_service.dart';

// Service Providers
final memberServiceProvider = Provider<MemberService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MemberService(apiClient);
});

final membershipServiceProvider = Provider<MembershipService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MembershipService(apiClient);
});

final activeMembershipsProvider = FutureProvider<List<MembershipModel>>((ref) async {
  final service = ref.watch(membershipServiceProvider);
  return service.getActiveMemberships();
});

// State
class MembersState {
  final bool isLoading;
  final List<MemberModel> members;
  final int total;
  final int currentPage;
  final int totalPages;
  final String searchQuery;
  final String filter; // 'all', 'active', 'expired', 'pending'
  final MemberModel? selectedMember;
  final String? error;

  const MembersState({
    this.isLoading = false,
    this.members = const [],
    this.total = 0,
    this.currentPage = 1,
    this.totalPages = 1,
    this.searchQuery = '',
    this.filter = 'all',
    this.selectedMember,
    this.error,
  });

  List<MemberModel> get filteredMembers {
    if (filter == 'all') return members;
    return members.where((m) {
      if (filter == 'active') return !m.isExpired && m.hasMembership && !m.isSuspended;
      if (filter == 'expired') return m.isExpired || !m.hasMembership;
      if (filter == 'pending') return m.hasPendingPayment;
      return true;
    }).toList();
  }

  MembersState copyWith({
    bool? isLoading,
    List<MemberModel>? members,
    int? total,
    int? currentPage,
    int? totalPages,
    String? searchQuery,
    String? filter,
    MemberModel? selectedMember,
    String? error,
  }) {
    return MembersState(
      isLoading: isLoading ?? this.isLoading,
      members: members ?? this.members,
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      selectedMember: selectedMember ?? this.selectedMember,
      error: error,
    );
  }
}

class MembersNotifier extends Notifier<MembersState> {
  Timer? _debounceTimer;

  @override
  MembersState build() {
    // Initial fetch on mount
    Future.microtask(() => loadMembers());
    return const MembersState(isLoading: true);
  }

  Future<void> loadMembers({int page = 1}) async {
    state = state.copyWith(isLoading: true, error: null);
    final service = ref.read(memberServiceProvider);

    try {
      final q = state.searchQuery.trim();
      if (q.isNotEmpty) {
        final results = await service.searchMembers(q);
        state = state.copyWith(
          isLoading: false,
          members: results,
          total: results.length,
          currentPage: 1,
          totalPages: 1,
        );
      } else {
        final result = await service.getMembers(page: page, limit: 25);
        state = state.copyWith(
          isLoading: false,
          members: result.members,
          total: result.total,
          currentPage: page,
          totalPages: result.totalPages,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void search(String query) {
    _debounceTimer?.cancel();
    state = state.copyWith(searchQuery: query);

    if (query.trim().isEmpty) {
      loadMembers(page: 1);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      loadMembers(page: 1);
    });
  }

  void setFilter(String filter) {
    state = state.copyWith(filter: filter);
  }

  void selectMember(MemberModel? member) {
    state = state.copyWith(selectedMember: member);
  }

  Future<bool> createMember(Map<String, dynamic> data) async {
    final service = ref.read(memberServiceProvider);
    try {
      await service.createMember(data);
      await loadMembers(page: 1);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateMember(String id, Map<String, dynamic> data) async {
    final service = ref.read(memberServiceProvider);
    try {
      await service.updateMember(id, data);
      await loadMembers(page: state.currentPage);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteMember(String id) async {
    final service = ref.read(memberServiceProvider);
    try {
      await service.deleteMember(id);
      await loadMembers(page: state.currentPage);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<({bool success, String? warning})> assignMembership({
    required String memberId,
    required String membershipId,
    required String startDate,
    String? endDate,
    String paymentMethod = 'cash',
  }) async {
    final service = ref.read(membershipServiceProvider);
    try {
      final res = await service.assignMembership(
        memberId: memberId,
        membershipId: membershipId,
        startDate: startDate,
        endDate: endDate,
        paymentMethod: paymentMethod,
      );
      await loadMembers(page: state.currentPage);
      return res;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return (success: false, warning: null);
    }
  }
}

final membersProvider = NotifierProvider<MembersNotifier, MembersState>(() {
  return MembersNotifier();
});
